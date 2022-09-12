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
        |> redirect(to: Routes.gen_diff_path(conn, :new))
    end
  end

  defp stream_diff(conn, stream) do
    header = [
      Phoenix.View.render_to_iodata(UtilityWeb.LayoutView, "head.html", conn: conn),
      "<body class=\"antialiased leading-tight bg-white dark:bg-black text-gray-900 dark:text-gray-100\">",
      Phoenix.View.render_to_iodata(UtilityWeb.GenDiffView, "head.html", conn: conn)
    ]

    footer = [
      Phoenix.View.render_to_iodata(UtilityWeb.GenDiffView, "footer.html", conn: conn),
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
