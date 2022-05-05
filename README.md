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
  * Start Phoenix endpoint with `iex -S mix phx.server`
  * You need docker and ruby installed in order to run generator diffs.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

`flyctl deploy`
