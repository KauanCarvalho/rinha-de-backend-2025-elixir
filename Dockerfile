FROM hexpm/elixir:1.18.4-erlang-28.0.1-alpine-3.22.0 AS base

RUN MIX_HOME=/app mix do local.hex --force, local.rebar --force

RUN apk add --no-cache \
    build-base \
    git

FROM base AS build

ENV MIX_ENV=prod

WORKDIR /app

COPY mix.exs mix.lock ./

RUN mix deps.get --only prod && mix deps.compile

COPY . .

RUN mix compile && mix release

FROM alpine:3.22.0 AS release

RUN apk add --update --no-cache \
  libgcc \
  libstdc++ \
  ncurses-libs

WORKDIR /app

COPY ./containers/app/docker-entrypoint.sh ./

COPY --from=build /app/_build/prod/rel/backend_fight ./

ENTRYPOINT ["/app/docker-entrypoint.sh"]
