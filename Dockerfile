# Stage 1: Install Chromium and dependencies on standard Alpine
FROM alpine:3.19 AS chromium-installer

RUN apk add --no-cache \
  chromium \
  nss \
  glib \
  freetype \
  freetype-dev \
  harfbuzz \
  ca-certificates \
  ttf-freefont \
  udev \
  ttf-liberation \
  font-noto-emoji

# Stage 2: Build on official n8n image with Chromium support
FROM n8nio/n8n:latest

USER root

# Copy Chromium and all its dependencies from the Alpine image
COPY --from=chromium-installer /usr/lib/chromium/ /usr/lib/chromium/
COPY --from=chromium-installer /usr/bin/chromium-browser /usr/bin/chromium-browser
COPY --from=chromium-installer /lib/ /lib/

# Copy fonts
COPY --from=chromium-installer /usr/share/fonts/ /usr/share/fonts/

# Chromium wrapper script for Docker-friendly flags
COPY <<EOF /usr/bin/chromium-wrapper
#!/bin/sh
exec chromium-browser \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  "$@"
EOF

RUN chmod +x /usr/bin/chromium-wrapper

# Create symlink for chromium-browser to use wrapper
RUN ln -sf /usr/bin/chromium-wrapper /usr/bin/chromium-browser

# Tell Puppeteer to use installed Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
  NODE_OPTIONS=--max-old-space-size=4096

# Install n8n-nodes-puppeteer community node
RUN mkdir -p /opt/n8n-custom-nodes && \
  cd /opt/n8n-custom-nodes && \
  npm install n8n-nodes-puppeteer && \
  chown -R node:node /opt/n8n-custom-nodes

USER node
