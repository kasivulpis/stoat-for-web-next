# SECTION BUILD STAGE
FROM node:25-slim as BUILD

# ANCHOR BUILD ENVS
ARG BASE_PATH=/
ENV BASE_PATH=${BASE_PATH}
ENV PROD="true"
# TODO Set ALL the following ENVs (?):
# NOTE Fiiiiiiiiine we'll inject variables for now... T-T
# ENV VITE_SENTRY_DSN=""
# ENV VITE_SENTRY_TUNNEL=""
ENV VITE_INVITE_ONLY=__VITE_INVITE_ONLY__
ENV VITE_API_URL=__VITE_API_URL__
ENV VITE_WS_URL=__VITE_WS_URL__
ENV VITE_MEDIA_URL=__VITE_MEDIA_URL__
ENV VITE_PROXY_URL=__VITE_PROXY_URL__
ENV VITE_HCAPTCHA_SITEKEY=__VITE_HCAPTCHA_SITEKEY__
# ENV VITE_CFG_MAX_REPLIES=""
# ENV VITE_CFG_MAX_ATTACHMENTS=""
# ENV VITE_CFG_MAX_EMOJI=""
ENV VITE_CFG_MAX_FILE_SIZE=__VITE_CFG_MAX_FILE_SIZE__
ENV NODE_OPTIONS="--max-old-space-size=4096"

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
# ANCHOR CADDY
FROM caddy:latest as FINAL
COPY --from=BUILD /app/packages/client/dist /usr/share/caddy
RUN printf "%s\n" \
  ":80 {" \
  "  root * /srv" \
  "  try_files {path} /index.html" \
  "  file_server" \
  "}" \
  > /etc/caddy/Caddyfile
# ANCHOR ENV INJECTION
COPY entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
# !SECTION

# ANCHOR EXPOSE & PROD ENVS
EXPOSE 5000
ENTRYPOINT ["/docker-entrypoint.sh"]