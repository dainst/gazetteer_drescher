FROM elixir:alpine

COPY . /gazetteer_drescher

WORKDIR /gazetteer_drescher

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile
