FROM hexpm/elixir:1.11.2-erlang-23.1.4-alpine-3.12.1

RUN apk upgrade --no-cache && \
    apk add --no-cache bash curl g++ git ca-certificates openssh-client

CMD ["/bin/bash"]
