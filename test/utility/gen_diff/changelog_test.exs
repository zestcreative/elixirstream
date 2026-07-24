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
end
