##
## n8n + Chromium (Alpine) image for Puppeteer-based workflows
##
## Notes:
##  - Pin the n8n version for reproducibility (override at build time with --build-arg N8N_VERSION=...).
##  - We install system Chromium and tell Puppeteer to skip downloading its own.
##  - Consolidated ENV to reduce layers.
##

ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

USER root

# Install Chromium + supporting fonts/tools (Alpine)
RUN apk add --no-cache \
            chromium \
            nss \
            freetype \
            harfbuzz \
            ttf-freefont \
            ttf-liberation \
            font-noto \
            font-noto-emoji \
            ca-certificates \
            wget \
            jq \
        && mkdir -p /home/node/.cache /home/node/.config /tmp \
        && chown -R node:node /home/node /tmp

# Single ENV layer for clarity & fewer layers
ENV \
    # Chromium / Puppeteer
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage" \
    # Allow selected builtins/external modules in n8n Code nodes
    NODE_FUNCTION_ALLOW_BUILTIN=fs,path,os \
    NODE_FUNCTION_ALLOW_EXTERNAL=puppeteer \
    # XDG + runtime dirs (avoid permission issues)
    XDG_CACHE_HOME=/home/node/.cache \
    XDG_CONFIG_HOME=/home/node/.config \
    XDG_RUNTIME_DIR=/tmp

WORKDIR /home/node
USER node

# (Optional) you can add: HEALTHCHECK CMD wget -q --spider http://localhost:5678/healthz || exit 1
