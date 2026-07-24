defmodule UtilityWeb.GenDiffController do
  use UtilityWeb, :controller
  require Logger

  @doc """
  On-demand Markdown API for LLMs. Returns a compact **index** document — generator
  metadata, a change summary, and a list of changed files, each linking to its own
  patch URL (`api_file/2`). Blocks until the diff is built. Query-param keys are
  case-insensitive; `project` defaults to `phx_new` and `command` to `phx.new`.

      GET /gendiff/api?from=1.8.0&to=1.8.9&from_flags=--binary-id,--no-mailer&to_flags=--binary-id
  """
  def api(conn, params) do
    conn = put_resp_content_type(conn, "text/markdown")
    p = downcase(params)

    # Bare/exploratory request (no version range): serve the usage guide so an agent
    # pointed at this URL learns how to generate a diff without making one first.
    if p["from"] in [nil, ""] or p["to"] in [nil, ""] do
      send_resp(conn, 200, usage_md())
    else
      file_url = fn generator, file ->
        url(~p"/gendiff/api/file?#{file_query(generator, file)}")
      end

      changelog_url = fn generator -> url(~p"/gendiff/api/changelog?#{base_query(generator)}") end

      opts = [file_url: file_url, changelog_url: changelog_url]

      case Utility.GenDiff.Api.markdown(generator_params(params), opts) do
        {:ok, markdown} -> send_resp(conn, 200, markdown)
        {:error, :invalid, changeset} -> send_resp(conn, 400, invalid_markdown(changeset))
        {:error, :build_failed} -> send_resp(conn, 502, build_failed_md())
        {:error, :timeout} -> send_resp(conn, 504, timeout_md())
      end
    end
  end

  defp usage_md do
    example =
      url(
        ~p"/gendiff/api?#{[project: "phx_new", command: "phx.new", from: "1.7.14", to: "1.8.5"]}"
      )

    """
    # gendiff — Markdown API for coding agents

    Generate a diff of a project generator's output between two versions, rendered as
    Markdown built for LLMs. Fetch one URL, get the diff — no UI needed.

    ## Endpoint

        GET /gendiff/api

    ## Query parameters

    | Param | Required | Default | Notes |
    | --- | --- | --- | --- |
    | `project` | no | `phx_new` | Generator package, e.g. `phx_new`, `nerves_bootstrap`, `credo` |
    | `command` | no | `phx.new` | Mix task, e.g. `phx.new`, `phx.gen.auth` |
    | `from` | **yes** | — | FROM version, e.g. `1.7.14` |
    | `to` | **yes** | — | TO version, e.g. `1.8.5` |
    | `from_flags` | no | — | Comma-separated flags for the FROM run, e.g. `--binary-id,--no-mailer` |
    | `to_flags` | no | — | Comma-separated flags for the TO run |

    ## Example

    Diff a fresh `mix phx.new` app between 1.7.14 and 1.8.5:

        #{example}

    The response is an **index**: generator metadata, a change summary, and a list of
    changed files — each linking to its own per-file patch URL. Fetch only the files
    relevant to your task. A new (uncached) version+flag combination may take up to
    ~3 minutes to build on the first request; subsequent requests are cached.

    ## Discovering valid projects, commands, versions, and flags

    Browse the interactive tool to see every available option: #{url(~p"/gendiff")}
    """
  end

  @doc """
  Returns the upstream CHANGELOG sliced to this version range, as its own `text/markdown`
  document (linked from the index). Same params as `api/2`.
  """
  def api_changelog(conn, params) do
    conn = put_resp_content_type(conn, "text/markdown")

    case Utility.GenDiff.Api.changelog(generator_params(params)) do
      {:ok, changelog} ->
        send_resp(conn, 200, changelog)

      {:error, :invalid, changeset} ->
        send_resp(conn, 400, invalid_markdown(changeset))

      {:error, :unsupported} ->
        send_resp(conn, 404, "# No changelog\n\nThis generator has no changelog source.\n")

      {:error, _reason} ->
        send_resp(
          conn,
          502,
          "# Changelog unavailable\n\nCould not fetch the changelog for this range.\n"
        )
    end
  end

  @doc """
  Returns the standalone unified diff for a single `file` within a generated diff, as
  `text/plain`. Linked from the index (`api/2`); takes the same params plus `file`.
  """
  def api_file(conn, params) do
    case downcase(params)["file"] do
      nil ->
        conn
        |> put_resp_content_type("text/markdown")
        |> send_resp(400, "# Missing `file` parameter\n")

      file ->
        respond_file(conn, Utility.GenDiff.Api.file_patch(generator_params(params), file), file)
    end
  end

  defp respond_file(conn, {:ok, file_diff}, _file) do
    conn |> put_resp_content_type("text/plain") |> send_resp(200, file_diff)
  end

  defp respond_file(conn, {:error, :not_in_diff}, file) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "File not present in this diff: #{file}\n")
  end

  defp respond_file(conn, {:error, :invalid, changeset}, _file) do
    conn |> put_resp_content_type("text/markdown") |> send_resp(400, invalid_markdown(changeset))
  end

  defp respond_file(conn, {:error, :build_failed}, _file) do
    conn |> put_resp_content_type("text/markdown") |> send_resp(502, build_failed_md())
  end

  defp respond_file(conn, {:error, :timeout}, _file) do
    conn |> put_resp_content_type("text/markdown") |> send_resp(504, timeout_md())
  end

  defp downcase(params), do: Map.new(params, fn {k, v} -> {String.downcase(to_string(k)), v} end)

  defp generator_params(params) do
    params = downcase(params)

    %{
      "project" => Map.get(params, "project", "phx_new"),
      "command" => Map.get(params, "command", "phx.new"),
      "from_version" => params["from"],
      "to_version" => params["to"],
      "from_flags" => parse_flags(params["from_flags"]),
      "to_flags" => parse_flags(params["to_flags"])
    }
  end

  defp base_query(generator) do
    [
      project: generator.project,
      command: generator.command,
      from: generator.from_version,
      to: generator.to_version,
      from_flags: Enum.join(generator.from_flags || [], ","),
      to_flags: Enum.join(generator.to_flags || [], ",")
    ]
  end

  defp file_query(generator, file), do: base_query(generator) ++ [file: file]

  defp build_failed_md,
    do: "# Build failed\n\nThe diff could not be generated. Try again later.\n"

  defp timeout_md, do: "# Timed out\n\nThe diff took too long to build. Try again shortly.\n"

  defp parse_flags(nil), do: []

  defp parse_flags(value) when is_binary(value) do
    value |> String.split(",", trim: true) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp invalid_markdown(changeset) do
    details =
      changeset
      |> Ecto.Changeset.traverse_errors(&translate_error/1)
      |> Enum.map_join("\n", fn {field, messages} ->
        "- **#{field}:** #{Enum.join(messages, ", ")}"
      end)

    "# Invalid parameters\n\n#{details}\n"
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  def show(conn, %{"project" => project, "id" => id} = _params) do
    case Utility.GenDiff.Storage.get(project, id) do
      {:ok, diff_stream} ->
        conn
        |> put_resp_content_type("text/html")
        |> stream_diff(diff_stream)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Diff not found. Please specify diff parameters")
        |> redirect(to: ~p"/gendiff")
    end
  end

  defp stream_diff(conn, stream) do
    header = [
      "<!DOCTYPE html><html lang=\"en\" class=\"dark\">",
      Phoenix.Template.render_to_iodata(UtilityWeb.Layouts, "head", "html", conn: conn),
      "<body class=\"antialiased leading-tight bg-black text-gray-100\">",
      Phoenix.Template.render_to_iodata(UtilityWeb.GenDiffHTML, "head", "html", conn: conn)
    ]

    footer = [
      Phoenix.Template.render_to_iodata(UtilityWeb.GenDiffHTML, "footer", "html", conn: conn),
      "</body></html>"
    ]

    conn = send_chunked(conn, 200)

    with {:ok, conn} <- chunk(conn, header),
         {:ok, conn} <- stream_chunks(conn, stream),
         {:ok, conn} <- chunk(conn, footer) do
      conn
    else
      {:error, reason} ->
        Logger.error("chunking failed: #{inspect(reason)}")
        conn
    end
  end

  defp stream_chunks(conn, stream) do
    Enum.reduce_while(stream, {:ok, conn}, fn chunk, {:ok, conn} ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, {:ok, conn}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end
end
