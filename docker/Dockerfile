# ---- Elixir deps Stage ----
FROM elixir:1.11-alpine as builder

ENV MIX_ENV=prod
ENV DATABASE_URL=
ENV SECRET_KEY_BASE=

WORKDIR /app

COPY . ./

RUN apk add alpine-sdk

RUN mix local.rebar --force && \
    mix local.hex --force && \
    mix deps.get --only prod && \
    mix compile

# ---- Assets building ----
FROM node:12-alpine AS assets

ARG WEBAPP

WORKDIR /app

# Compile assets
COPY --from=builder /app/deps /app/deps

COPY --from=builder /app/assets/                        ./assets/
COPY --from=builder /app/lib/crapetto_web/templates/    ./lib/crapetto_web/templates
COPY --from=builder /app/lib/crapetto_web/live/         ./lib/crapetto_web/live
COPY --from=builder /app/priv/                          ./priv/

RUN cd /app/assets && \
    npm install && \
    NODE_ENV=production npm run deploy

# ---- Release Stage ----
FROM builder AS release

ARG WEBAPP
ARG OMNIAPP
ARG DOMOAPP
ARG DISCAPP

ENV MIX_ENV=prod

WORKDIR /app

COPY --from=builder /app/           ./
COPY --from=assets /app/priv/static ./priv/static

RUN mix phx.digest

RUN mix compile & mix release

# ---- Application Stage ----
FROM alpine:3.13
RUN apk add --no-cache ncurses-libs openssl libstdc++
WORKDIR /app
COPY --from=release --chown=nobody:nobody /app/_build/prod/rel/crapetto/ .
RUN chown nobody:nobody /app
USER nobody:nobody
ENV HOME=/app
ENV RELEASE_NODE=crapetto@localhost
ENV RELEASE_DISTRIBUTION=sname
EXPOSE 4000
ENTRYPOINT ["bin/crapetto"]
CMD ["start"]