# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20230522-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.14.5-erlang-26.0.1-debian-bullseye-20230522-slim
#
ARG ELIXIR_VERSION=1.14.5
ARG OTP_VERSION=26.0.1
ARG DEBIAN_VERSION=bullseye-20230522-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm software-properties-common wget curl \
  python3 python3-pip python-is-python3 \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

RUN cd assets && npm install

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel

RUN git clone https://github.com/aubio/aubio.git priv/aubio

RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y build-essential software-properties-common wget curl libstdc++6 openssl libncurses5 locales ffmpeg \
  libavcodec-dev libavutil-dev libavformat-dev python3 python3-pip python-is-python3 aubio-tools libaubio-dev libaubio-doc \
  libswresample-dev libavresample-dev libsamplerate-dev libsndfile-dev txt2man doxygen \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
  apt-get install xdg-utils -y && dpkg -i google-chrome-stable_current_amd64.deb

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/audius_live ./

RUN cd /app/lib/audius_live-0.1.0/priv/aubio && make
RUN cd /app/lib/audius_live-0.1.0/priv/threemotion && npm install --legacy-peer-deps

USER nobody

CMD ["sh", "-c", "/app/bin/migrate && /app/bin/server"]