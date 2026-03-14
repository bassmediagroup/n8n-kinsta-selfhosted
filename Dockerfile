# Start from official n8n image
FROM andrearuffini/n8n-puppeteer:latest
# Switch to root to install packages
USER root

# Set Puppeteer environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

# Switch back to node user for security
USER node
