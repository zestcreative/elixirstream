defmodule Utility.Workers.ErrorHandler do
  def handle_event([:oban, :job, :exception], _measure, meta, _config) do
    IO.inspect meta, label: "EXCEPTION"
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _config) do
    IO.inspect meta, label: "EXCEPTION"
  end
end
