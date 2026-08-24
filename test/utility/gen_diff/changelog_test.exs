defmodule Utility.GenDiff.ChangelogTest do
  use ExUnit.Case, async: true
  alias Utility.GenDiff.Changelog

  # Mirrors the real Phoenix CHANGELOG.md shape: a highlights preamble of narrative
  # `## ` sections, then version sections (newest first), then a prior-series pointer.
  @raw """
  # Changelog for v1.8

  This release requires Erlang/OTP 25+.

  ## Streamlined generators

    * daisyUI support

  ## Deprecations

    * some deprecation

  ## 1.8.0 (2025-08-05)

  ### Enhancements
    - [phx.new] Add `mix precommit` alias

  ## 1.8.0-rc.0 (2025-04-01) 🚀

  ### Bug fixes
    - an rc fix

  ## v1.7

  See the [CHANGELOG for v1.7](url) for prior changes.
  """

  test "keeps the highlights preamble and versions in (from, to], dropping the prior-series pointer" do
    out = Changelog.slice_text(@raw, "1.7.14", "1.8.0")

    assert out =~ "# Changelog for v1.8"
    assert out =~ "## Streamlined generators"
    assert out =~ "## Deprecations"
    assert out =~ "## 1.8.0 (2025-08-05)"
    assert out =~ "## 1.8.0-rc.0"
    # the trailing "## v1.7" pointer to the previous series is excluded
    refute out =~ "## v1.7"
    refute out =~ "CHANGELOG for v1.7"
  end

  test "excludes versions at or below `from`" do
    out = Changelog.slice_text(@raw, "1.8.0-rc.0", "1.8.0")

    assert out =~ "## 1.8.0 (2025-08-05)"
    refute out =~ "## 1.8.0-rc.0"
  end

  test "to=main includes everything newer than from" do
    out = Changelog.slice_text(@raw, "1.7.14", "main")

    assert out =~ "## 1.8.0 (2025-08-05)"
    assert out =~ "## 1.8.0-rc.0"
  end

  test "skips versions newer than `to` (series-latest changelog covers later patches)" do
    raw = """
    # Changelog for v1.8

    ## Highlights

      * stuff

    ## 1.8.9 (2025-12-01)
    ### too new

    ## 1.8.1 (2025-09-01)
    ### also too new

    ## 1.8.0 (2025-08-05)
    ### the target
    """

    out = Changelog.slice_text(raw, "1.7.14", "1.8.0")

    assert out =~ "## Highlights"
    assert out =~ "## 1.8.0 (2025-08-05)"
    refute out =~ "## 1.8.9"
    refute out =~ "## 1.8.1"
  end

  test "returns empty string when no version in the file falls in range" do
    # `from` is at/above the newest version in this file → this series contributes nothing.
    assert Changelog.slice_text(@raw, "1.8.0", "1.9.0") == ""
  end

  test "unsupported project returns an error without fetching" do
    assert {:error, :unsupported} = Changelog.slice("rails", "5.0.0", "7.0.0")
  end

  test "a slice with only a preamble and no versions is treated as empty" do
    # Nothing in range: the result would be a bare title plus highlights, which tells the
    # reader nothing about what changed, so callers should render no section at all.
    assert Changelog.slice_text(@raw, "1.8.0", "1.9.0") == ""
  end

  describe "changed_deps/1" do
    # Verbatim from the real `phx.new` 1.7.14 -> 1.8.0 mix.exs diff, including the
    # commented-out `phoenix_live_view` line 1.7.14 actually shipped.
    @patch """
    diff --git a/mix.exs b/mix.exs
    index 1111111..2222222 100644
    --- a/mix.exs
    +++ b/mix.exs
    -      {:ecto_sql, "~> 3.10"},
    +      {:ecto_sql, "~> 3.13"},
    -      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
    -      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
    -      {:floki, ">= 0.30.0", only: :test},<% end %>
    +      {:phoenix_live_view, "~> 1.1.0"},
    +      {:lazy_html, ">= 0.1.0", only: :test},<% end %>
    -      {:swoosh, "~> 1.5"},
    -      {:finch, "~> 0.13"},<% end %>
    +      {:swoosh, "~> 1.16"},
    +      {:req, "~> 0.5"},<% end %>
    -      {:gettext, "~> 0.20"},<% end %>
    +      {:gettext, "~> 0.26"},<% end %>
       {:heroicons,
        github: "tailwindlabs/heroicons",
    """

    test "pairs up the requirement on each side of the diff" do
      deps = Changelog.changed_deps(@patch)

      assert {"ecto_sql", "~> 3.10", "~> 3.13"} in deps
      assert {"swoosh", "~> 1.5", "~> 1.16"} in deps
      assert {"gettext", "~> 0.20", "~> 0.26"} in deps
    end

    test "takes the real pin, not the commented-out one above it" do
      assert {"phoenix_live_view", "~> 1.0.0-rc.1", "~> 1.1.0"} in Changelog.changed_deps(@patch)
    end

    test "skips deps present on only one side, and git deps with no requirement" do
      packages = Enum.map(Changelog.changed_deps(@patch), &elem(&1, 0))

      # replaced, not bumped — there's no range to slice
      refute "floki" in packages
      refute "lazy_html" in packages
      refute "finch" in packages
      refute "req" in packages
      refute "heroicons" in packages
    end

    test "ignores deps with no known changelog source" do
      patch = """
      diff --git a/mix.exs b/mix.exs
      --- a/mix.exs
      +++ b/mix.exs
      -      {:some_private_dep, "~> 1.0"},
      +      {:some_private_dep, "~> 2.0"},
      """

      assert Changelog.changed_deps(patch) == []
    end

    test "only reads mix.exs, not other files in the patch" do
      patch = """
      diff --git a/README.md b/README.md
      --- a/README.md
      +++ b/README.md
      -      {:ecto_sql, "~> 3.10"},
      +      {:ecto_sql, "~> 3.13"},
      """

      assert Changelog.changed_deps(patch) == []
    end

    test "a patch with no mix.exs yields nothing" do
      assert Changelog.changed_deps(nil) == []
      assert Changelog.changed_deps("") == []
    end

    test "sorts phoenix_live_view first, then alphabetically" do
      assert Enum.map(Changelog.changed_deps(@patch), &elem(&1, 0)) ==
               ["phoenix_live_view", "ecto_sql", "gettext", "swoosh"]
    end
  end

  describe "companion_range/3" do
    # No Hex versions are cached in test, so these exercise the base-version fallback:
    # over-inclusive on purpose, since a long changelog beats a silently missing one.
    test "falls back to the requirements' base versions when no releases are known" do
      assert Changelog.companion_range("phoenix_live_view", "~> 1.1.0", "~> 1.2.0") ==
               {:ok, "1.1.0", "1.2.0"}
    end

    test "pads a two-segment requirement to a full version" do
      assert Changelog.companion_range("gettext", "~> 0.26", "~> 1.0") == {:ok, "0.26.0", "1.0.0"}
    end

    test "keeps a pre-release base intact" do
      assert Changelog.companion_range("phoenix_live_view", "~> 1.0.0-rc.1", "~> 1.1.0") ==
               {:ok, "1.0.0-rc.1", "1.1.0"}
    end

    test "is :error for a requirement with no version in it" do
      assert Changelog.companion_range("ecto", "github: foo/bar", "~> 3.13") == :error
    end
  end
end
