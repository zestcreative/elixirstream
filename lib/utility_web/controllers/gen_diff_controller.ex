defmodule UtilityWeb.GenDiffController do
  use UtilityWeb, :controller
  require Logger

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
      Phoenix.Template.render_to_iodata(UtilityWeb.Layouts, "head", "html", conn: conn),
      "<body class=\"antialiased leading-tight bg-white dark:bg-black text-gray-900 dark:text-gray-100\">",
      Phoenix.Template.render_to_iodata(UtilityWeb.GenDiffHTML, "head", "html", conn: conn)
    ]

    footer = [
      Phoenix.Template.render_to_iodata(UtilityWeb.GenDiffHTML, "footer", "html", conn: conn),
      "</body>"
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
