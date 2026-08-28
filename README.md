# LogicX Loom

LogicX Loom receives JSON events from embedded Loom machines. It stores each payload without
changing its structure and shows the raw event stream on the authenticated Dashboard.

The runtime contains:

- Identity: users, roles, permissions, user roles, and role permissions.
- Loom Data: public machine ingestion and local JSON event persistence.
- Messenger: private conversations between LogicX Loom users.

LogicX Loom uses one MariaDB database configured by `DB_NAME`. The active app contains Login,
Dashboard, and Messenger.
Application code consumes only the public exports of the internal `packages/framework` and
`packages/ui` workspaces; no parent-folder package is required for install, development, build, or
deployment.

The workspace uses only the repository-root `node_modules` and `dist` directories. Framework
runtime output is written to `dist/packages/framework`; API and web output is written to
`dist/platform/api` and `dist/platform/web`.

## Development

Copy `.env.example` to `.env`, fill the database, JWT, encryption, administrator, and Frappe
settings, then run:

```sh
npm install
npm run dev
```

Default endpoints:

- API: `http://127.0.0.1:9350`
- Web: `http://127.0.0.1:9360`

## Machine JSON ingestion

Send a JSON value with an HTTP POST request:

```sh
curl -X POST https://log.logicx.in/loomdata \
  -H "Content-Type: application/json" \
  -d '{"machineId":"loom-01","status":"running","counter":42}'
```

The endpoint accepts JSON objects, arrays, strings, numbers, booleans, and null. The maximum payload
size is 1 MB. The Dashboard checks for new events every three seconds and loads older events in
pages.

Machine writes to `POST /loomdata` are public and do not require an authentication header. Keep
dashboard access authenticated so only signed-in users can read the stored event stream.

Database commands:

```sh
npm run db:migrate
npm run db:seed
npm run db:migrations:list
```

`db:drop` and `dbmigrate:fresh` require the explicit reset guard documented in `.env.example`.

## Local Docker deployment

Run the interactive installer from the repository root:

```sh
./setup.sh
```

On Windows, use Git Bash explicitly when `bash` resolves to WSL but no Linux distribution is
installed:

```powershell
& "C:\Program Files\Git\bin\bash.exe" setup.sh
```

Before prompting, the installer creates the root `.env` from `.env.example` when it is missing.
The interactive flow reviews Docker resource names, bind address, host ports, MariaDB identity, and
the protected administrator. Public URLs, encryption, and Frappe connection values are read
directly from the root `.env`; Frappe is always enabled and those values are not prompted. Existing
secrets can be kept without displaying them. Setup detects unavailable API or web host ports and
asks for replacements. It can either create a dedicated LogicX Loom network and MariaDB volume or
reuse an explicitly named running MariaDB container on an existing Docker network. Reused networks
are marked external, and setup never disconnects, stops, removes, or recreates those existing
infrastructure resources.

After deployment:

- Public Web: `https://log.logicx.in`
- Machine JSON: `https://log.logicx.in/loomdata`
- Messenger WebSocket: `wss://log.logicx.in/api/platform/ws/messaging`
- Loopback Web: `127.0.0.1:19360`
- Loopback API: `127.0.0.1:19350`
- Loopback WebSocket: `127.0.0.1:19351/ws/messaging`
- Runtime configuration: `.env`
- Docker/deployment configuration: `.container/deploy.env`

Point the host HTTPS reverse proxy for `log.logicx.in` to `127.0.0.1:19360`. The Web container
routes API, machine JSON, and Messenger WebSocket traffic to the API container.

### Updating an existing Docker deployment

After pulling or copying the updated repository source, run:

```sh
bash update.sh
```

For a non-interactive update:

```sh
bash update.sh --yes
```

To validate the current deployment without rebuilding anything:

```sh
bash update.sh --check
```

The updater deploys committed source by default. For an explicitly accepted emergency build from
an uncommitted checkout, use `bash update.sh --allow-dirty`; the dirty state and source commit are
recorded in the deployment metadata.

On Windows with Git Bash:

```powershell
& "C:\Program Files\Git\bin\bash.exe" update.sh
```

The updater requires the existing root `.env`, `.container/deploy.env`, and Compose-owned
LogicX Loom containers. Before each release, update `LOGICX_LOOM_VERSION`, `LOGICX_LOOM_IMAGE_TAG`, and
`LOGICX_LOOM_MIGRATION_COMPATIBLE_VERSION` in `.container/deploy.env` to the exact `package.json`
version after reviewing migrations and repeatable seeds for compatibility with the running image.
Mixed source/image versions are refused.

Before downtime, the updater validates container ownership, runtime-file access, committed source,
available backup/build storage, and an exclusive host update lock. It runs the production build and
repository checks in Docker with development dependencies, rebuilds the versioned API and Web
images, creates a timestamped MariaDB dump, verifies its SHA-256 checksum, and runs migrations plus
repeatable seeds with the new API image. It then recreates only the two application containers,
waits for Docker health, and probes both published HTTP endpoints. A failed replacement restores
the prior API and Web images automatically; applied database changes are not automatically reversed.
The SQL backup, checksum sidecar, and per-attempt deployment JSON are retained for audited manual
recovery. `LOGICX_LOOM_BACKUP_RETENTION` controls retained backup sets; the two
`LOGICX_LOOM_UPDATE_MIN_*_FREE_MB` settings control disk-space preflight thresholds.

The updater does not rerun interactive setup, modify either environment file, change credentials,
recreate MariaDB, remove volumes, or touch shared infrastructure.

## Verification

```sh
npm run check
npm run build
npm run dependencies:check
npm run test:e2e:runtime
```

The runtime smoke test uses the configured MariaDB and administrator credentials, starts the built
API twice, and verifies health, anonymous-session rejection, login, authenticated session recovery,
logout, and restart persistence.

Read `assist/AGENT-GUIDE.md` before changing architecture or module ownership.
