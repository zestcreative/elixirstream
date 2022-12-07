# Utilities (made with Elixir)

A series of utilities for developers.

1. Regex Tester
1. HTTP Sink. Send a request and see it echo on the UI.
1. Generator diff pipeline. See the diff between versions and flags of
   generators, such as `phx.gen.auth`, `phx.new`, `scenic.new`, or `nerves.new`.
1. Community-provided tips that post to Twitter for you from [@elixirstream](https://twitter.com/elixirstream)
1. ... that's it for now :)

## Running Locally

You need to install `docker` and `gem` for Ruby and docker needs to be running,
otherwise the app will complain when starting up since it can't build the
Dockerfiles needed for diffing. Colima doesn't seem to work, but docker-ce does
seem to work when mounting volumes. `podman` might work instead of `docker` but
is the containerd runtime is untested.

You also need [`silicon`](https://github.com/Aloxaf/silicon) installed to
generate code screenshots.

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

`flyctl deploy`
