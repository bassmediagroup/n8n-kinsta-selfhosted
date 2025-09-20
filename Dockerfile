# Base: official n8n image
FROM n8nio/n8n:latest

USER root

# Install a system Chromium + fonts for better rendering
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      chromium \
      fonts-liberation \
      fonts-noto-color-emoji \
      ca-certificates \
      wget \
      jq && \
    rm -rf /var/lib/apt/lists/*

# Tell Puppeteer to use system Chromium (skip bundling)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Optional: allow fs/path in Code nodes (useful for saving cookies)
ENV NODE_FUNCTION_ALLOW_BUILTIN=fs,path,os

# Optional: allow requiring puppeteer in Code node if you ever need it
ENV NODE_FUNCTION_ALLOW_EXTERNAL=puppeteer

# n8n runs as "node"; its home is /home/node
USER node
WORKDIR /home/node

