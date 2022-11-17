# BUILD LAYER

FROM hexpm/elixir:1.14.2-erlang-25.1.2-alpine-3.16.2 AS build
RUN apk add --no-cache build-base npm gcompat
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
FROM docker:20.10.21-dind-alpine3.16 AS app
RUN apk add --no-cache libstdc++ openssl ncurses-libs ruby bash git curl \
    ip6tables pigz sysstat procps lsof sudo bind-tools expat-dev pkgconfig \
    fontconfig fontconfig-dev freetype-dev freetype libxcb libxcb-dev \
    xclip harfbuzz harfbuzz-dev libxkbcommon-dev libxml2 libxml2-dev cargo \
    font-fira-code-nerd uuidgen
RUN addgroup -S docker && \
    addgroup -S --gid 1000 app && \
    adduser -D -G app --uid 1000 app && \
    addgroup -S app docker && \
    echo "app ALL=(ALL) NOPASSWD: /sbin/docker-setup" >> /etc/sudoers
RUN cargo install --root / silicon --version 0.4.3

## COPY RELEASE
WORKDIR /app
RUN chown -R 1000:1000 /app
COPY --from=build --chown=app:app app/_build/prod/rel/utility ./
COPY priv/docker-setup /sbin/docker-setup
COPY priv/docker-daemon.json /etc/docker/daemon.json
RUN chmod 711 /sbin/docker-setup
USER app
WORKDIR /app
ENV HOME=/app
ENV MIX_ENV=prod

CMD ["./bin/start.sh"]
