defmodule Utility.Workers.ErrorHandler do
  def handle_event([:oban, :job, :exception], measure, meta, _config) do
    extra = meta |> Map.take([:id, :args, :queue, :worker]) |> Map.merge(measure)
    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: extra)
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _config) do
    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: meta)
  end
end
