defmodule UtilityWeb.GenDiffHTMLTest do
  use ExUnit.Case, async: true
  alias UtilityWeb.GenDiffHTML

  describe "render_changelog/1" do
    test "renders markdown to HTML with syntax-highlighted code blocks" do
      md = "## 1.8.0\n\n* note\n\n```elixir\ndef deps, do: []\n```\n"
      html = md |> GenDiffHTML.render_changelog() |> Phoenix.HTML.safe_to_string()

      # Markdown structure became HTML...
      assert html =~ "<h2>1.8.0</h2>"
      assert html =~ "<li>note</li>"
      # ...and the code block was highlighted (lumis emits inline-styled spans).
      assert html =~ ~s(class="lumis")
      assert html =~ "style=\"color:"
    end

    test "escapes raw inline HTML (XSS-safe)" do
      html =
        "<script>alert(1)</script>"
        |> GenDiffHTML.render_changelog()
        |> Phoenix.HTML.safe_to_string()

      refute html =~ "<script>"
    end
  end
end
