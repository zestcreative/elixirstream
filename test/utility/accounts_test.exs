defmodule Utility.AccountsTest do
  use Utility.DataCase, async: true
  alias Utility.Accounts
  alias Utility.Test.Factory

  doctest Accounts

  describe "admin?" do
    test "should only return true for dbernheisel" do
      user = Factory.build(:user)
      refute Accounts.admin?(user)

      # Magic number hard-coded in accounts
      user = Factory.build(:user, source: :github, source_id: "643967")
      assert Accounts.admin?(user)
    end
  end

  describe "update_twitter" do
    test "updates twitter on user" do
      user = Factory.insert!(:user, twitter: nil)
      assert {:ok, _updated} = Accounts.update_twitter(user, "new twitter")
      assert Repo.get_by(Accounts.User, id: user.id, twitter: "new twitter")
    end
  end

  describe "update_or_create" do
    test "when not found, creates" do
      auth = Factory.build(:github_auth)
      refute Accounts.find(to_string(auth.provider), to_string(auth.uid))

      assert {:create, {:ok, user}} = Accounts.update_or_create(auth)
      assert user.source == auth.provider
      assert user.source_id == to_string(auth.uid)
      assert user.avatar == auth.info.urls.avatar_url
      assert user.username == auth.info.nickname
      assert user.name == auth.info.name
    end

    test "when found, returns existing" do
      auth = Factory.build(:github_auth)

      %{id: existing_id} =
        Factory.insert!(:user,
          username: auth.info.nickname,
          source: auth.provider,
          source_id: to_string(auth.uid)
        )

      assert {:update, {:ok, %{id: ^existing_id}}} = Accounts.update_or_create(auth)
    end

    test "when found, updates existing" do
      auth = Factory.build(:github_auth)

      %{id: existing_id} =
        Factory.insert!(:user,
          name: "old name",
          username: "old username",
          source: auth.provider,
          source_id: to_string(auth.uid)
        )

      assert {:update, {:ok, %{id: ^existing_id} = user}} = Accounts.update_or_create(auth)
      refute user.username == "old username"
      refute user.name == "old name"
    end
  end
end
