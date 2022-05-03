defmodule UtilityWeb.LayoutView do
  use UtilityWeb, :view
  alias Phoenix.LiveView.JS

  @themes ["dark", "light", "system"]
  def themes, do: @themes

  def show_mobile_nav(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#mobileNavShade",
      transition: {"duration-150 ease-out", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#mobileNav",
      transition: {"duration-150 ease-out", "opacity-0 scale-95", "opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-hidden", "false"}, to: "#mobileNav")
    |> JS.remove_class("block", to: "#mobileNavIconOpen")
    |> JS.add_class("hidden", to: "#mobileNavIconOpen")
    |> JS.remove_class("hidden", to: "#mobileNavIconClose")
    |> JS.add_class("block", to: "#mobileNavIconClose")
  end

  def hide_mobile_nav(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#mobileNavShade",
      transition: {"duration-150 ease-in", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#mobileNav",
      transition: {"duration-150 ease-in", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
    |> JS.set_attribute({"aria-hidden", "true"}, to: "#mobileNav")
    |> JS.remove_class("hidden", to: "#mobileNavIconOpen")
    |> JS.add_class("block", to: "#mobileNavIconOpen")
    |> JS.remove_class("block", to: "#mobileNavIconClose")
    |> JS.add_class("hidden", to: "#mobileNavIconClose")
  end
end
