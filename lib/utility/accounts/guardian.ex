defmodule Utility.Accounts.Guardian do
  use Guardian, otp_app: :utility

  def subject_for_token(%{id: id} = _subject, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _), do: {:ok, nil}

  def resource_from_claims(%{"sub" => nil}) do
    {:ok, %Utility.Accounts.User{}}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Utility.Accounts.find(id) do
      nil -> {:ok, %Utility.Accounts.User{}}
      user -> {:ok, user}
    end
  end
end
