defmodule UtilityWeb.Plug.GuardianPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :utility,
    module: Utility.Accounts.Guardian,
    error_handler: UtilityWeb.Plug.AuthErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
