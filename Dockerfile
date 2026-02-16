# SECTION BUILD STAGE
FROM node:25-slim as BUILD

# ANCHOR BUILD ENVS
ARG BASE_PATH=/
ENV BASE_PATH=${BASE_PATH}
ENV PROD="true"
# TODO Set the following ENVs (?):
# NOTE We are NOT going to be injecting variables. No.
# ENV VITE_SENTRY_DSN=""
# ENV VITE_SENTRY_TUNNEL=""
# ENV VITE_API_URL=""
# ENV VITE_WS_URL=""
# ENV VITE_MEDIA_URL=""
# ENV VITE_PROXY_URL=""
# ENV VITE_HCAPTCHA_SITEKEY=""
# ENV VITE_CFG_MAX_REPLIES=""
# ENV VITE_CFG_MAX_ATTACHMENTS=""
# ENV VITE_CFG_MAX_EMOJI=""
# ENV VITE_CFG_MAX_FILE_SIZE=""

WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y curl git libatomic1 && rm -rf /var/lib/apt/lists/*
# Line below is our `git clone --recursive https://github.com/stoatchat/for-web client`
RUN git submodule init && git submodule update
RUN curl https://mise.jdx.dev/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"
RUN mise --version
RUN mise trust /app/.mise/config.toml
# Line below is our `cd client`
WORKDIR /app/packages/client
RUN cp /app/packages/client/.env.example /app/packages/client/.env
RUN mise install:frozen
RUN mise build:deps
RUN mise build
# !SECTION

# SECTION FINAL STAGE
FROM caddy:latest as FINAL
COPY --from=BUILD /app/packages/client/dist /usr/share/caddy
# !SECTION

# ANCHOR EXPOSE & PROD ENVS
EXPOSE 5000
