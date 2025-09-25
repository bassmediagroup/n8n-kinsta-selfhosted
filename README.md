## n8n (Self-hosted) + Chromium for Puppeteer / Firecrawl

Custom Alpine-based n8n image that includes system Chromium + fonts for Puppeteer flows (e.g., SSO, scraping, Firecrawl integration).

### Features
- System `chromium` installed (no bundled Puppeteer download needed)
- Environment pre-configured: `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD`, executable path, sandbox disabled
- Healthcheck (`/healthz`)
- Optional GitHub Actions workflow to build & push to GHCR and/or Docker Hub
- `docker-compose.yml` for quick local start with persistent volume & basic auth

### Build Locally
```powershell
# (Optional) export credentials if pushing
# $env:DOCKERHUB_USERNAME='youruser'
# $env:DOCKERHUB_TOKEN='yourtoken'

docker build -t n8n-chromium:local --build-arg N8N_VERSION=1.52.4 .
```

### Run with Docker Compose
```powershell
docker compose up -d --build
# Open http://localhost:5678
```
Change default basic auth:
```powershell
$env:N8N_BASIC_AUTH_USER='admin'
$env:N8N_BASIC_AUTH_PASSWORD='strongPassword123!'
docker compose up -d --build
```

### GitHub Actions (CI)
Workflow file: `.github/workflows/build-and-push.yml`

Secrets to set (optional but recommended for Docker Hub):
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (Docker Hub PAT)

Build produces tags:
- `ghcr.io/<org>/n8n-chromium:1.52.4`
- `ghcr.io/<org>/n8n-chromium:latest`
- And (if Docker Hub secrets present) `<user>/n8n-chromium:...`

### Override n8n Version
```powershell
docker build -t n8n-chromium:1.53.0 --build-arg N8N_VERSION=1.53.0 .
```
Or in compose:
```powershell
N8N_VERSION=1.53.0 docker compose build
```

### Using Puppeteer in n8n Code Node
Reference the executable (usually auto-detected with ENV):
```javascript
const puppeteer = require('puppeteer');
const browser = await puppeteer.launch({
  executablePath: process.env.PUPPETEER_EXECUTABLE_PATH,
  args: process.env.CHROMIUM_FLAGS.split(' '),
});
// ...
```

### Troubleshooting
Unauthorized pulling `moby/buildkit:buildx-stable-1`:
1. Authenticate first:
	```powershell
	docker login -u youruser -p 'YOUR_DOCKERHUB_TOKEN'
	docker pull moby/buildkit:buildx-stable-1
	```
2. If still blocked, disable BuildKit temporarily:
	```powershell
	$env:DOCKER_BUILDKIT='0'
	docker build -t n8n-chromium:local .
	```
3. Or use buildx docker driver:
	```powershell
	docker buildx create --name nodl --driver docker --use
	docker buildx build -t n8n-chromium:local .
	```

Health endpoint failing: Ensure container logs show `n8n ready on port 5678`. Increase `--start-period` in the Dockerfile healthcheck if startup is slow.

### Persistence
`docker-compose.yml` mounts a named volume `n8n_data` at `/home/node/.n8n` for workflows & credentials.

### Security Notes
- Replace default basic auth values before exposing publicly.
- Consider a reverse proxy (Caddy, Traefik, Nginx) for TLS & rate limiting.
- Keep Chromium & n8n versions pinned to mitigate supply-chain drift.

### License
This repo only contains a Docker build context; n8n is distributed under its respective license. See https://github.com/n8n-io/n8n

