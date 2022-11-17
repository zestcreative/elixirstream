defmodule Utility.Test.Factory do
  def build(:user) do
    %Utility.Accounts.User{
      source_id: "#{:erlang.unique_integer([:positive, :monotonic])}",
      source: :github,
      name: "User Name",
      avatar: "https://url.example/avatar.jpg",
      username: "username"
    }
  end

  def build(:github_auth) do
    %Ueberauth.Auth{
      credentials: %Ueberauth.Auth.Credentials{
        expires: false,
        expires_at: nil,
        other: %{},
        refresh_token: nil,
        scopes: ["read:user"],
        secret: nil,
        token: "123abc",
        token_type: "Bearer"
      },
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: %OAuth2.AccessToken{
            access_token: "123abc",
            expires_at: nil,
            other_params: %{"scope" => "read:user"},
            refresh_token: nil,
            token_type: "Bearer"
          },
          user: %{
            "collaborators" => 0,
            "two_factor_authentication" => true,
            "twitter_username" => "bernheisel",
            "company" => "@stripe @zestcreative",
            "bio" => nil,
            "following" => 30,
            "followers_url" => "https://api.github.com/users/dbernheisel/followers",
            "public_gists" => 48,
            "id" => 999_999,
            "avatar_url" => "https://avatars.githubusercontent.com/u/643968?v=4",
            "events_url" => "https://api.github.com/users/dbernheisel/events{/privacy}",
            "starred_url" => "https://api.github.com/users/dbernheisel/starred{/owner}{/repo}",
            "private_gists" => 16,
            "blog" => "https://bernheisel.com",
            "subscriptions_url" => "https://api.github.com/users/dbernheisel/subscriptions",
            "type" => "User",
            "disk_usage" => 564_771,
            "site_admin" => false,
            "owned_private_repos" => 8,
            "public_repos" => 95,
            "location" => "Foo, NC",
            "hireable" => nil,
            "created_at" => "2011-03-01T03:41:37Z",
            "name" => "David Bernheisel",
            "organizations_url" => "https://api.github.com/users/dbernheisel/orgs",
            "gists_url" => "https://api.github.com/users/dbernheisel/gists{/gist_id}",
            "following_url" => "https://api.github.com/users/dbernheisel/following{/other_user}",
            "url" => "https://api.github.com/users/dbernheisel",
            "email" => nil,
            "login" => "dbernheisel",
            "html_url" => "https://github.com/dbernheisel",
            "gravatar_id" => "",
            "received_events_url" => "https://api.github.com/users/dbernheisel/received_events",
            "repos_url" => "https://api.github.com/users/dbernheisel/repos",
            "plan" => %{
              "collaborators" => 0,
              "name" => "free",
              "private_repos" => 10000,
              "space" => 976_562_499
            },
            "node_id" => "",
            "followers" => 51,
            "updated_at" => "2021-03-02T00:07:17Z",
            "total_private_repos" => 8
          }
        }
      },
      info: %Ueberauth.Auth.Info{
        birthday: nil,
        description: nil,
        email: "999999+dbernheisel@users.noreply.github.com",
        first_name: nil,
        image: "https://avatars.githubusercontent.com/u/999999=4",
        last_name: nil,
        location: "Foo, NC",
        name: "David Bernheisel",
        nickname: "dbernheisel",
        phone: nil,
        urls: %{
          api_url: "https://api.github.com/users/dbernheisel",
          avatar_url: "https://avatars.githubusercontent.com/u/999999?v=4",
          blog: "https://bernheisel.com",
          events_url: "https://api.github.com/users/dbernheisel/events{/privacy}",
          followers_url: "https://api.github.com/users/dbernheisel/followers",
          following_url: "https://api.github.com/users/dbernheisel/following{/other_user}",
          gists_url: "https://api.github.com/users/dbernheisel/gists{/gist_id}",
          html_url: "https://github.com/dbernheisel",
          organizations_url: "https://api.github.com/users/dbernheisel/orgs",
          received_events_url: "https://api.github.com/users/dbernheisel/received_events",
          repos_url: "https://api.github.com/users/dbernheisel/repos",
          starred_url: "https://api.github.com/users/dbernheisel/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/dbernheisel/subscriptions"
        }
      },
      provider: :github,
      strategy: Ueberauth.Strategy.Github,
      # changed the uid
      uid: 999_999
    }
  end

  def build(name, attrs) do
    name |> build() |> struct!(attrs)
  end

  def insert!(name, attrs \\ []) do
    name |> build(attrs) |> Utility.Repo.insert!()
  end

  def insert(name, attrs \\ []) do
    name |> build(attrs) |> Utility.Repo.insert()
  end
end
