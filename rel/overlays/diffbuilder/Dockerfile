FROM hexpm/elixir:1.14.1-erlang-25.1.1-debian-bullseye-20220801

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        make \
        wget \
        git \
        ca-certificates \
        openssh-client \
        build-essential \
        openssl \
        locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8 && \
    update-ca-certificates

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_HOME=/cache/.mix \
    HEX_HOME=/cache/.hex \
    DEBIAN_FRONTEND=noninteractive

ARG USER_ID=1000
ARG GROUP_ID=1001
ARG USER=user

COPY get-old-phx .
RUN groupadd --gid $GROUP_ID $USER && \
    useradd -m --gid $GROUP_ID --uid $USER_ID $USER && \
    mkdir -p /cache /app && bash get-old-phx && \
    chown -R $USER_ID:$GROUP_ID /cache /app

USER $USER
WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar

CMD ["/bin/bash"]
