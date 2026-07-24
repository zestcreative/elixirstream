# BUILD LAYER

FROM hexpm/elixir:1.20.2-erlang-29.0.3-alpine-3.21.7 AS build
RUN apk add --no-cache build-base npm git gcompat libxml2 libxml2-dev
WORKDIR /app

## HEX
ENV HEX_HTTP_TIMEOUT=20
RUN mix local.hex --if-missing --force && \
    mix local.rebar
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokeyyet

## COMPILE
COPY mix.exs mix.lock ./
COPY config/config.exs ./config/config.exs
COPY config/prod.exs ./config/prod.exs
COPY VERSION .
RUN mix do deps.get --only prod, deps.compile

## BUILD RELEASE
COPY assets ./assets
COPY lib ./lib
COPY priv ./priv
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN mix assets.deploy
COPY config/runtime.exs ./config/runtime.exs
COPY rel ./rel
RUN mix release

# APP LAYER
FROM docker:28.2.2-dind-alpine3.21 AS app
RUN apk add --no-cache libstdc++ openssl ncurses-libs ruby bash git curl \
    ip6tables pigz sysstat procps lsof sudo bind-tools uuidgen coreutils
# The docker:dind base image already ships a "docker" group, so create it only if missing.
RUN (getent group docker || addgroup -S docker) && \
    addgroup -S --gid 1000 app && \
    adduser -D -G app --uid 1000 app && \
    addgroup -S app docker && \
    echo "app ALL=(ALL) NOPASSWD: /sbin/docker-setup, /sbin/storage-setup" >> /etc/sudoers

## COPY RELEASE
WORKDIR /app
RUN chown -R 1000:1000 /app
COPY --from=build --chown=app:app app/_build/prod/rel/utility ./
COPY priv/docker-setup /sbin/docker-setup
COPY priv/storage-setup /sbin/storage-setup
COPY priv/docker-daemon.json /etc/docker/daemon.json
RUN chmod 711 /sbin/docker-setup /sbin/storage-setup
USER app
WORKDIR /app
ENV HOME=/app
ENV MIX_ENV=prod

CMD ["./bin/start.sh"]
