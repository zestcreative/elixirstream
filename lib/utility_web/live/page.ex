defmodule UtilityWeb.PageLive do
  use UtilityWeb, :live_view

  def mount(_params, _session, socket) do
    if socket.assigns.live_action == :about do
      {:ok, assign(socket, :page_title, "About")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mt-6 lg:mt-0 mx-auto px-4 sm:px-6 lg:max-w-7xl lg:px-8">
      <div class="rounded-lg dark:bg-gray-800 bg-white overflow-hidden shadow">
        <article class="p-6 prose dark:prose-invert lg:prose-lg">
          <p>
            Made with 💚💙💜💛❤️ by
            <Components.outbound_link href="https://twitter.com/bernheisel" class="link">
              @dbernheisel
            </Components.outbound_link>
          </p>

          <p>
            If you're interested in the source code,
            <.link href="https://github.com/zestcreative/utility" class="link">check it out</.link>
            .
            Have any ideas on what would be helpful here? Drop me a line by
            <Components.outbound_link href="https://github.com/zestcreative/utility/discussions/categories/ideas" class="link">
              starting a discussion on GitHub
            </Components.outbound_link>
            .
          </p>

          <h3>What does this site use?</h3>
          <ul>
            <li>
              <Components.outbound_link href="https://elixir-lang.org" class="link">
                Elixir
              </Components.outbound_link>
            </li>
            <li>
              <Components.outbound_link href="https://phoenixframework.org" class="link">
                Phoenix Framework
              </Components.outbound_link>
            </li>
            <li>
              <Components.outbound_link href="https://github.com/phoenixframework/phoenix_live_view" class="link">
                Phoenix LiveView
              </Components.outbound_link>
            </li>
            <li>
              <Components.outbound_link href="https://tailwindcss.com" class="link">
                Tailwind CSS
              </Components.outbound_link>
            </li>
          </ul>

          <h3>How does Phoenix LiveView make this awesome?</h3>
          <p>Before we get to Phoenix LiveView, let's start at the beginning:</p>
          <ul>
            <li>
              Elixir is an awesome language to work with to write web applications (and more like embedded devices!).
            </li>
            <li>
              Phoenix is a wonderful web framework which is quickly productive for handling web requests.
            </li>
            <li>
              Phoenix LiveView is a welcome addition that enables normally-backend-developers like me produce reactive Web
              UIs like the
              <.link navigate={~p"/regex"} class="link">Regex Tester</.link>
              without having to split the codebase into "backend" and "frontend" so much. This isn't a knock on frontend frameworks; this is just another highly-efficient tool in the developer's toolbelt to rapidly produce good web applications.
            </li>
          </ul>

          <p>
            Phoenix LiveView is performing server-side HTML diffing before sending it over the wire to
            your browser. "The wire" in this case is not AJAX or even an HTTP request, no, instead it's
            using websockets. Once the changed bits are received in the browser, Phoenix LiveView's
            JavaScript (with a lot of help from morphdom) is patching those changed bits to the HTML DOM,
            rendering what you see.
          </p>

          <h3>How do you deploy the app?</h3>
          <p>
            We're using
            <Components.outbound_link href="https://www.fly.io" class="link">fly.io</Components.outbound_link>
            .
            When it's time to deploy, all we do is commit to the main branch and a GitHub Action will run <code>flyctl deploy</code>
            automatically if tests pass.
          </p>
          <p>
            Since it costs money, it would be wonderful if you considered
            <Components.outbound_link href="https://github.com/sponsors/dbernheisel" class="link">sponsoring us at GitHub</Components.outbound_link>.
          </p>

          <h3>While I have you here...</h3>
          <p>
            Check out
            <Components.outbound_link href="https://thinkingelixir.com" class="link">
              Thinking Elixir
            </Components.outbound_link>
            and the
            <Components.outbound_link href="https://podcast.thinkingelixir.com" class="link">
              podcast
            </Components.outbound_link>
            .
          </p>
          <p>Remember to stay positive!</p>
        </article>
      </div>
    </div>
    """
  end
end
