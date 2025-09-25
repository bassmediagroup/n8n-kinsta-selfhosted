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

Load from `.env` file instead of inline env vars:
```powershell
Copy-Item .env.example .env
# edit .env then:
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

### Deploying to Kinsta (Recommended: Pull Prebuilt Image Instead of Building There)
Kinsta's build environment is currently failing while pulling the BuildKit bootstrap image (`moby/buildkit:buildx-stable-1`) due to anonymous pull limits / auth. Easiest workaround: build the image externally (GitHub Actions already configured) and have Kinsta deploy the pushed image instead of building from the repository Dockerfile.

1. Let the GitHub Action run (or trigger manually) so the image is pushed to GHCR.
2. In Kinsta, choose deployment from Image (Container Registry):
	- Registry: `ghcr.io`
	- Image: `ghcr.io/<org-or-user>/n8n-chromium:latest`
	- Authentication: Use a GitHub Personal Access Token with `read:packages` scope (PAT username = your GitHub username).
3. Set container port to `5678`.
4. Environment variables (examples):
	- `N8N_HOST = n8n-kinsta-selfhosted-kv1ye.kinsta.app`
	- `N8N_PROTOCOL = https`
	- `WEBHOOK_URL = https://n8n-kinsta-selfhosted-kv1ye.kinsta.app/`
	- `N8N_PORT = 5678`
	- `N8N_BASIC_AUTH_ACTIVE = true`
	- `N8N_BASIC_AUTH_USER = admin`
	- `N8N_BASIC_AUTH_PASSWORD = <strong-password>`
	- `N8N_ENCRYPTION_KEY = <32+ char random secret>` (critical if you store credentials)
	- `EXECUTIONS_MODE = regular`
	- `TZ = UTC`
5. (Optional) Add persistence if Kinsta supports volumes: mount to `/home/node/.n8n`.

If you must build inside Kinsta and cannot add Docker Hub credentials, you can try disabling BuildKit (if their UI allows build-time env): set `DOCKER_BUILDKIT=0`. This is less future-proof; external CI builds are recommended.

#### Adding Docker Hub Credentials in Kinsta
If you prefer Docker Hub instead of GHCR, add registry auth in Kinsta settings with your Docker Hub username + PAT. This should unblock the build step pulling `moby/buildkit:buildx-stable-1`.

#### Webhook / URL Considerations
Set `WEBHOOK_URL` (or `WEBHOOK_TUNNEL_URL` if using tunnels) so that external webhooks reach your instance. Make sure the value matches the public domain with protocol.

#### 502 / Connection Refused After Deploy
- Ensure the container listens on `0.0.0.0:5678` (default; no change needed unless overridden).
- Confirm no conflicting `N8N_PORT` or `N8N_LISTEN_ADDRESS` variables.
- Check logs for: `n8n ready on port 5678`. If missing, there may be a startup error (Chromium missing, permission issue, or DB/config mis-set).

### Manual Build Dispatch Version Override (CI)
You can manually run the GitHub Action and specify a different `n8n` version via the workflow input. (See updated workflow: it accepts an input `n8n_version`.)

### Secrets & Encryption
Create a strong encryption key (32+ chars) so credential data remains decryptable across restarts:
```powershell
openssl rand -base64 48 | ForEach-Object { $_ -replace "`n","" }
```
Place it in `.env` as `N8N_ENCRYPTION_KEY=...` (or set in Kinsta UI). Changing it after storing credentials invalidates them.

Recommended sensitive variables (do not commit real values):
- `N8N_ENCRYPTION_KEY`
- `POSTGRES_PASSWORD`
- `N8N_BASIC_AUTH_PASSWORD`
- Any API keys used inside workflows (store in n8n credentials where possible)

### Database (Postgres) vs Default SQLite
The compose file now includes a Postgres 15 service. Benefits:
- Better concurrency & reliability
- Easier scaling (externalize DB later)

Local usage:
```powershell
docker compose up -d --build
```
Data persists in the named volume `pg_data`. For production / Kinsta use a managed Postgres if possible; set:
```
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<host>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=<db>
DB_POSTGRESDB_USER=<user>
DB_POSTGRESDB_PASSWORD=<pass>
```

### Upgrading n8n
1. Trigger workflow with new version in `n8n_version` input (or adjust `.env` / build arg).
2. Confirm image builds & vulnerability scan passes.
3. Deploy new tag to Kinsta.
4. Roll back by redeploying previous tag if issues occur.

### Vulnerability Scanning
The CI workflow runs a Trivy scan and fails on HIGH/CRITICAL. To temporarily ignore failures, remove `exit-code: '1'` or restrict severity.

### Persistence Summary
- Workflows & config: `n8n_data` volume (`/home/node/.n8n`)
- Postgres data: `pg_data` volume (`/var/lib/postgresql/data`)


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

