# Utilities (made with Elixir)

A series of utilities for developers.

1. Regex Tester
1. HTTP Sink. Send a request and see it echo on the UI.
1. Generator diff pipeline. See the diff between versions and flags of
   generators, such as `phx.gen.auth`, `phx.new`, `scenic.new`, or `nerves.new`.
1. ... that's it for now :)

## Running Locally

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`
  * You need docker installed in order to run generator diffs.
    * After booting, make sure you run `Utility.ProjectRunner.build_runners()`
      in an IEx console.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

- Configure ~/.ssh/config on your machine to alias the production machine. For
  example:

  ```
  Host utility-web
    HostName 123.45.67.89
  ```

- `ssh root@utility-web`
- Ensure SSH access is setup for a user `utility` on the server
- `bin/deploy production`
