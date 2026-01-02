# Debian-based n8n image (n8nio/n8n:latest is Debian, not Alpine)
FROM n8nio/n8n:latest

USER root

# Install Chromium + fonts/tools on Debian
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-liberation \
    ca-certificates \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Puppeteer: point to Chromium binary
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Helpful in containers
ENV CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage"

# (Optional) allow Code nodes to use fs/path and require('puppeteer')
ENV NODE_FUNCTION_ALLOW_BUILTIN=fs,path,os
ENV NODE_FUNCTION_ALLOW_EXTERNAL=puppeteer

USER node
WORKDIR /home/node

USER root
RUN mkdir -p /home/node/.cache /home/node/.config /tmp && \
    chown -R node:node /home/node /tmp

ENV XDG_CACHE_HOME=/home/node/.cache \
    XDG_CONFIG_HOME=/home/node/.config \
    XDG_RUNTIME_DIR=/tmp \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

USER node
