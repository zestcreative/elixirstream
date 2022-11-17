defmodule Utility.Silicon do
  require Logger
  @silicon_bin "bin/silicon.sh"
  @default_font "FiraCode Nerd Font"
  @default_theme "Monokai Extended Bright"

  def generate(tip, opts \\ [])
  def generate(%{code: nil}, _opts), do: {:ok, nil}

  def generate(tip, opts) do
    theme = Keyword.get(opts, :theme, @default_theme)
    font = Keyword.get(opts, :font, @default_font)
    extension = Keyword.get(opts, :extension, "ex")

    @silicon_bin
    |> path_for()
    |> Path.expand()
    |> System.cmd([tip.code, theme, font, extension])
    |> case do
      {filepath, 0} ->
        {:ok, String.trim(filepath)}

      {output, _} ->
        Logger.error(output)
        {:error, "could not generate image"}
    end
  end

  def path_for(relative_path) do
    if Application.get_env(:utility, :app_env) == :prod do
      relative_path
    else
      Path.join(["rel", "overlays", relative_path])
    end
  end

  def fonts() do
    "silicon"
    |> System.find_executable()
    |> System.cmd(["--list-fonts"])
    |> case do
      {fonts, 0} ->
        fonts
        |> String.trim()
        |> String.split("\n")
        |> Enum.reject(&String.match?(&1, ~r/warning:|error:/))

      _ ->
        []
    end
  end

  def themes() do
    "silicon"
    |> System.find_executable()
    |> System.cmd(["--list-themes"])
    |> case do
      {fonts, 0} ->
        fonts |> String.trim() |> String.split("\n")

      _ ->
        []
    end
  end
end
