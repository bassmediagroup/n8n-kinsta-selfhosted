# Use the Debian-based image so apt-get is available
FROM n8nio/n8n:latest-debian

USER root

# Install Chromium + fonts/tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      chromium \
      fonts-liberation \
      fonts-noto-color-emoji \
      ca-certificates \
      wget \
      jq && \
    rm -rf /var/lib/apt/lists/*

# Puppeteer: use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Optional: allow fs/path in Code nodes, and external 'puppeteer'
ENV NODE_FUNCTION_ALLOW_BUILTIN=fs,path,os
ENV NODE_FUNCTION_ALLOW_EXTERNAL=puppeteer

USER node
WORKDIR /home/node
