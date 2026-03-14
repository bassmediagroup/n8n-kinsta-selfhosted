# Start from official n8n image
FROM n8nio/n8n:latest

# Switch to root to install packages
USER root

# Install Chromium and dependencies for Puppeteer
RUN apk add --no-cache \
    chromium \
        glib \
            gcompat \
    libgcc \
    libstdc++ \
    dbus-libs \
    libx11 \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxrandr \
    pango \
    cairo \
    alsa-lib \
    mesa-gl \
    eudev-libs \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Set Puppeteer environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

# Switch back to node user for security
USER node
