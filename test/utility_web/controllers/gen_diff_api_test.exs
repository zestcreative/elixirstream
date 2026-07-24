defmodule UtilityWeb.GenDiffApiTest do
  # async: false — these tests read/write the shared on-disk gendiff storage.
  use UtilityWeb.ConnCase, async: false
  alias Utility.GenDiff.{Generator, Storage}

  setup do
    # Clear any diff artifacts cached by previous runs so cache hits are deterministic.
    File.rm_rf(Path.join(Application.get_env(:utility, :gendiff_storage_dir), "diff-html"))
    :ok
  end

  @patch """
  diff --git a/mix.exs b/mix.exs
  --- a/mix.exs
  +++ b/mix.exs
  @@ -1 +1 @@
  -      {:phoenix, "~> 1.7.0"},
  +      {:phoenix, "~> 1.8.0"},
  diff --git a/README.md b/README.md
  --- a/README.md
  +++ b/README.md
  @@ -1 +1 @@
  -# old
  +# new
  """

  defp generator(overrides) do
    params =
      Map.merge(
        %{
          "project" => "phx_new",
          "command" => "phx.new",
          "from_version" => "1.5.0",
          "to_version" => "1.6.0",
          "from_flags" => [],
          "to_flags" => []
        },
        overrides
      )

    {:ok, generator} = Generator.apply(params)
    generator
  end

  defp seed_patch(generator, patch) do
    tmp = Path.join(System.tmp_dir!(), "gendiff-seed-#{System.unique_integer([:positive])}.patch")
    File.write!(tmp, patch)
    Storage.put_patch(generator, tmp)
    File.rm(tmp)
  end

  defp query(path, pairs), do: path <> "?" <> URI.encode_query(pairs)

  test "serves cached index markdown as-is on a hit", %{conn: conn} do
    gen =
      generator(%{
        "from_version" => "1.5.0",
        "to_version" => "1.6.0",
        "from_flags" => ["--no-ecto"]
      })

    Storage.put_md(gen, "# cached document\n")

    conn = get(conn, query("/gendiff/api", from: "1.5.0", to: "1.6.0", from_flags: "--no-ecto"))

    assert response(conn, 200) == "# cached document\n"
    assert response_content_type(conn, :md) =~ "text/markdown"
  end

  test "assembles an index (not inline diffs) linking to per-file patch URLs", %{conn: conn} do
    gen =
      generator(%{
        "from_version" => "1.7.0",
        "to_version" => "1.8.0",
        "from_flags" => ["--binary-id"],
        "to_flags" => ["--binary-id"]
      })

    seed_patch(gen, @patch)

    conn =
      get(
        conn,
        query("/gendiff/api",
          from: "1.7.0",
          to: "1.8.0",
          from_flags: "--binary-id",
          to_flags: "--binary-id"
        )
      )

    body = response(conn, 200)

    assert body =~ "How to use this document"
    assert body =~ "**from:** `1.7.0`"
    assert body =~ "**files changed:** 2"
    # per-file links, no inline diff
    assert body =~ "[`mix.exs`]"
    assert body =~ "/gendiff/api/file?"
    assert body =~ "file=mix.exs"
    refute body =~ "```diff"
    refute body =~ "{:phoenix"
    # changelog is linked (not inlined), with a strong instruction
    assert body =~ "ALWAYS READ THIS FIRST"
    assert body =~ "/gendiff/api/changelog?"

    assert {:ok, cached} = Storage.get_md(gen)
    assert cached == body
  end

  test "returns 400 from the changelog endpoint for invalid params", %{conn: conn} do
    conn =
      get(
        conn,
        query("/gendiff/api/changelog", project: "not-a-real-project", from: "1.0.0", to: "2.0.0")
      )

    assert response(conn, 400) =~ "Invalid parameters"
  end

  test "serves a single file's patch as text/plain", %{conn: conn} do
    gen =
      generator(%{
        "from_version" => "1.7.1",
        "to_version" => "1.8.1",
        "from_flags" => ["--binary-id"],
        "to_flags" => ["--binary-id"]
      })

    seed_patch(gen, @patch)

    conn =
      get(
        conn,
        query("/gendiff/api/file",
          from: "1.7.1",
          to: "1.8.1",
          from_flags: "--binary-id",
          to_flags: "--binary-id",
          file: "mix.exs"
        )
      )

    body = response(conn, 200)
    assert response_content_type(conn, :txt) =~ "text/plain"
    assert body =~ "diff --git a/mix.exs b/mix.exs"
    assert body =~ "{:phoenix, \"~> 1.8.0\"}"
    # only the requested file
    refute body =~ "README.md"
  end

  test "returns 404 for a file not in the diff", %{conn: conn} do
    gen =
      generator(%{
        "from_version" => "1.7.2",
        "to_version" => "1.8.2",
        "from_flags" => ["--binary-id"],
        "to_flags" => ["--binary-id"]
      })

    seed_patch(gen, @patch)

    conn =
      get(
        conn,
        query("/gendiff/api/file",
          from: "1.7.2",
          to: "1.8.2",
          from_flags: "--binary-id",
          to_flags: "--binary-id",
          file: "lib/nope.ex"
        )
      )

    assert response(conn, 404) =~ "not present"
  end

  test "defaults project/command to phx_new/phx.new", %{conn: conn} do
    gen = generator(%{"from_version" => "1.6.0", "to_version" => "1.7.0"})
    Storage.put_md(gen, "# defaulted\n")

    conn = get(conn, query("/gendiff/api", from: "1.6.0", to: "1.7.0"))
    assert response(conn, 200) == "# defaulted\n"
  end

  test "returns 400 for invalid params", %{conn: conn} do
    conn =
      get(conn, query("/gendiff/api", project: "not-a-real-project", from: "1.0.0", to: "2.0.0"))

    body = response(conn, 400)
    assert body =~ "Invalid parameters"
    assert body =~ "project"
  end
end
