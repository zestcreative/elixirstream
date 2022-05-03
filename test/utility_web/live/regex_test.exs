defmodule UtilityWeb.RegexLiveTest do
  use UtilityWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias UtilityWeb.RegexLive
  alias Utility.Test.TooLong

  @route "/regex"
  @valid_params %{
    "regex_live" => %{
      "function" => "scan",
      "string" => "asdf asdf",
      "flags" => "i",
      "regex" => "[A-z]+"
    }
  }

  describe "changeset" do
    test "record has defaults" do
      record = %RegexLive{}

      assert record.function == "scan"
      assert record.string == ""
      assert record.flags == ""
      assert record.regex == ""

      # computed
      assert record.result == ""
      assert record.pasta == ""
      assert record.matched == []
    end

    test "validates length of regex" do
      record = %RegexLive{}
      changeset = RegexLive.changeset(record, %{regex: TooLong.too_long()})

      assert %{regex: ["must be under 6,500 characters"]} = errors_on(changeset)
    end

    test "validates length of string" do
      record = %RegexLive{}
      changeset = RegexLive.changeset(record, %{string: TooLong.too_long()})

      assert %{string: ["must be under 2MB"]} = errors_on(changeset)
    end

    test "validates allowed functions" do
      record = %RegexLive{}
      changeset = RegexLive.changeset(record, %{function: "escape"})

      assert %{function: ["is invalid"]} = errors_on(changeset)
    end

    test "does not populate result or pasta if invalid" do
      record = %RegexLive{}
      changeset = RegexLive.changeset(record, %{function: "foo", regex: "[0-9]+", string: "1234"})

      assert Ecto.Changeset.get_field(changeset, :result) == ""
      assert Ecto.Changeset.get_field(changeset, :pasta) == ""
    end

    test "populates copy-pasta if valid" do
      record = %RegexLive{}
      changeset = RegexLive.changeset(record, %{function: "scan", flags: "i", regex: "[0-9]+"})

      assert Ecto.Changeset.get_field(changeset, :pasta) == "Regex.scan(~r/[0-9]+/i, string)"
    end

    test "populates result if valid" do
      record = %RegexLive{}

      changeset =
        RegexLive.changeset(record, %{
          function: "scan",
          string: "123asdf1234",
          flags: "i",
          regex: "[0-9]+"
        })

      assert Ecto.Changeset.get_field(changeset, :result) == [["123"], ["1234"]]
    end

    test "populates matches if valid" do
      record = %RegexLive{}

      changeset =
        RegexLive.changeset(record, %{
          function: "scan",
          string: "123asdf1234",
          flags: "i",
          regex: "[0-9]+"
        })

      assert Ecto.Changeset.get_field(changeset, :matched) == [
               matched: "123",
               unmatched: "asdf",
               matched: "1234"
             ]
    end

    test "correctly maps submatches" do
      record = %RegexLive{}

      changeset =
        RegexLive.changeset(record, %{
          function: "scan",
          string: "+1 999 999-9999",
          flags: "",
          regex: ~S"\A(\+?1(-| )?)?(\(?\d{3}\)?(-| )?)?\d{3}(-| )?\d{4}\z"
        })

      assert Ecto.Changeset.get_field(changeset, :matched) == [matched: "+1 999 999-9999"]
    end
  end

  describe "mounting" do
    test "can mount", %{conn: conn} do
      conn = get(conn, @route)
      assert html_response(conn, 200) =~ "Regex Tester</h2>"
      assert {:ok, _view, html} = live(conn)
      assert html =~ "Regex Tester</h2>"
    end

    test "can load saved record", %{conn: conn} do
      Utility.Cache.multi([
        [:hash_set, "regex-test-id", "string", "1234 my test string"],
        [:hash_set, "regex-test-id", "regex", "[0-9]+"],
        [:hash_set, "regex-test-id", "function", "run"],
        [:hash_set, "regex-test-id", "flags", "i"]
      ])

      conn = get(conn, @route <> "/test-id")
      assert html_response(conn, 200) =~ "Regex Tester</h2>"
      assert {:ok, _view, html} = live(conn)
      assert html =~ "1234 my test string"
    end
  end

  describe "handle_event - permalink" do
    test "with invalid record, flashes error", %{conn: conn} do
      conn = get(conn, @route)
      {:ok, view, _html} = live(conn)

      render_change(view, :validate, %{"regex_live" => %{"function" => "invalid"}})
      assert render_click(view, "permalink") =~ "You may only save a valid regex"
    end

    test "with valid record, patches to saved record", %{conn: conn} do
      conn = get(conn, @route)
      {:ok, view, _html} = live(conn)
      send(self(), {:validate, @valid_params})

      assert render_click(view, "permalink") =~ "Saved regex for 1 year. See browser URL"
      # I would use assert_patch but the route would include a random UUID
    end
  end

  describe "rendering" do
    test "renders copy-pasta", %{conn: conn} do
      conn = get(conn, @route)
      {:ok, view, _html} = live(conn)

      params = %{
        "regex_live" => %{
          "function" => "run",
          "string" => "asdf 1234",
          "flags" => "i",
          "regex" => "[0-9]+"
        }
      }

      assert render_change(view, :validate, params) =~ "Regex.run(~r/[0-9]+/i, string)"
    end

    test "renders result", %{conn: conn} do
      conn = get(conn, @route)
      {:ok, view, _html} = live(conn)

      params = %{
        "regex_live" => %{
          "function" => "run",
          "string" => "asdf 1234",
          "flags" => "i",
          "regex" => "[0-9]+"
        }
      }

      assert render_change(view, :validate, params) =~ "result = [&quot;1234&quot;]"
    end

    test "renders error message with invalid regex", %{conn: conn} do
      conn = get(conn, @route)
      {:ok, view, _html} = live(conn)

      params = %{
        "regex_live" => %{
          "function" => "run",
          "string" => "",
          "flags" => "",
          "regex" => "[asdf"
        }
      }

      assert render_change(view, :validate, params) =~
               "result = &quot;missing terminating ] for character class (at character 5)&quot;"
    end
  end
end
