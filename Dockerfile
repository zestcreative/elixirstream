# BUILD LAYER

FROM hexpm/elixir:1.17.3-erlang-27.2-alpine-3.21.0 AS build
RUN apk add --no-cache build-base npm git gcompat \
    expat-dev pkgconfig fontconfig fontconfig-dev freetype-dev freetype \
    libxcb libxcb-dev xclip harfbuzz harfbuzz-dev libxkbcommon-dev \
    libxml2 libxml2-dev cargo
WORKDIR /app
RUN cargo install --root / silicon --version 0.4.3

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
RUN mix do deps.get --only prod, deps.compile, tailwind.install, esbuild.install

## BUILD RELEASE
COPY assets ./assets
COPY lib ./lib
COPY priv ./priv
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN mix assets.deploy
COPY config/runtime.exs ./config/runtime.exs
COPY rel ./rel
RUN mix do sentry.package_source_code, release

# APP LAYER
FROM docker/buildx-bin:v0.12 as buildx
FROM docker:27.4.0-dind-alpine3.21 AS app
RUN apk add --no-cache libstdc++ openssl ncurses-libs ruby bash git curl \
    ip6tables pigz sysstat procps lsof sudo bind-tools expat-dev pkgconfig \
    fontconfig fontconfig-dev freetype-dev freetype libxcb libxcb-dev \
    xclip harfbuzz harfbuzz-dev libxkbcommon-dev libxml2 libxml2-dev \
    font-fira-code-nerd uuidgen coreutils pngquant
RUN addgroup -S --gid 1000 app && \
    adduser -D -G app --uid 1000 app && \
    addgroup -S app docker && \
    echo "app ALL=(ALL) NOPASSWD: /sbin/docker-setup" >> /etc/sudoers

## COPY RELEASE
WORKDIR /app
RUN chown -R 1000:1000 /app
COPY --from=buildx /buildx /root/.docker/cli-plugins/docker-buildx
COPY --from=build --chown=app:app app/_build/prod/rel/utility ./
COPY --from=build /bin/silicon /bin/silicon
COPY priv/docker-setup /sbin/docker-setup
COPY priv/docker-daemon.json /etc/docker/daemon.json
RUN chmod 711 /sbin/docker-setup
USER app
WORKDIR /app
ENV HOME=/app
ENV MIX_ENV=prod

CMD ["./bin/start.sh"]
