# B-NAKOWA Modern Guest House — Render Free deployment guide

This package is a compact, standalone **React + Express + tRPC + Drizzle + PostgreSQL** application. The public booking experience and staff operations workspace remain in the same application architecture, while the source has been consolidated into one client entry point and one server entry point. The package contains **ten tracked files**, including the Render Blueprint, the PostgreSQL schema, the PostgreSQL seed script, the lockfile, and this guide.

| File | Purpose |
|---|---|
| `package.json` | Runtime dependencies and local/Render commands. |
| `pnpm-lock.yaml` | Reproducible dependency resolution. |
| `client.tsx` | React UI, routing, booking, staff login, operations, and analytics. |
| `server.ts` | Express server, tRPC router, PostgreSQL access, transactions, sessions, health check, and database validation. |
| `index.html` | Browser document shell. |
| `styles.css` | Consolidated responsive styling. |
| `001_schema.sql` | PostgreSQL enums, tables, indexes, and foreign-key constraints. |
| `002_seed.sql` | Fresh-database B-NAKOWA property, rooms, guests, reservations, payments, and housekeeping data. |
| `render.yaml` | Render Free Blueprint configuration. |
| `DEPLOYMENT.md` | This deployment and troubleshooting guide. |

> **Important:** Render Free is configured without a pre-deploy command. Run the two SQL files manually in the Neon SQL Editor before the first Render deployment. The server validates that the schema and seed are already present; it does not automatically create them at runtime.

## 1. Create the GitHub repository

Create a private GitHub repository, for example `bnakowa-modern-guest-house`. From the extracted project directory, run:

```bash
git init
git add .
git commit -m "Consolidate B-NAKOWA for Render Free"
git branch -M main
git remote add origin https://github.com/YOUR_ORGANIZATION/bnakowa-modern-guest-house.git
git push -u origin main
```

Do not commit `.env` files, database URLs, JWT secrets, or staff passwords. This cleaned package contains no Manus/OAuth connector code and no secret file.

## 2. Create the Neon PostgreSQL project

Create a PostgreSQL project at [Neon](https://neon.tech). Copy its full PostgreSQL connection string. Keep the connection string private; it belongs only in Render’s server-side environment variables and in a private local shell when needed.

The database should be new or otherwise empty for the supplied seed. The seed contains demonstration data for B-NAKOWA and a retained inactive legacy property. Do not run it against a database that already contains production reservations, guest information, payments, or audit records unless you have taken a backup and deliberately reconciled the IDs and sample data.

## 3. Initialize Neon through the SQL Editor

This is the required replacement for Render pre-deploy setup.

Open the Neon project dashboard and select **SQL Editor**. Open `001_schema.sql` from this repository, copy its complete contents, paste them into a new Neon SQL Editor query, and run the query. Wait for it to finish successfully before continuing.

Next, open `002_seed.sql`, copy its complete contents, paste it into a new SQL Editor query, and run it. Execute the files in this exact order:

```text
001_schema.sql
002_seed.sql
```

The first script creates the PostgreSQL enums, tables, indexes, and foreign keys. The second script inserts the B-NAKOWA property, twelve physical B-NAKOWA rooms, room types, amenities, sample guests, sample reservations, payment records, housekeeping tasks, and audit events. The seed script intentionally does **not** contain a hard-coded staff password. The deployed server creates the owner account from `BNAKOWA_ADMIN_USERNAME` and `BNAKOWA_ADMIN_PASSWORD` after the SQL scripts have completed.

Run these verification queries in Neon SQL Editor:

```sql
select count(*) as properties from public.properties;
select count(*) as bnakowa_rooms
from public.rooms r
join public.properties p on p.id = r.property_id
where p.slug = 'b-nakowa';
select count(*) as staff_accounts from public.staff_accounts;
```

Expected fresh-seed results are two properties, twelve B-NAKOWA rooms, and zero staff accounts before the Render service’s first successful startup. Room 202 is intentionally seeded with `maintenance` status, leaving eleven B-NAKOWA rooms available in the initial inventory.

If Neon reports duplicate-key errors, stop. Do not keep rerunning the seed script. Restore a clean database or reconcile the existing data in a staging database first.

## 4. Configure the Render service

The repository root contains `render.yaml`. Render recognizes this as a Blueprint file. The Blueprint deliberately contains a Node web service only; it does not create a Render Postgres database because this deployment uses Neon.

In the Render Dashboard, choose **New → Blueprint**, connect the GitHub repository, select the `main` branch, and review the service definition. Render’s Blueprint specification supports the Node runtime, build command, start command, environment variables, and health-check path used by this project.[1]

The Render Free service uses these commands:

```text
Build Command:     corepack enable && pnpm install --frozen-lockfile && pnpm build
Start Command:     pnpm start
Health Check Path: /healthz
```

There is intentionally **no `preDeployCommand`** in `render.yaml`. Database initialization has already been completed manually in Neon SQL Editor. The server start routine checks that the schema and B-NAKOWA seed exist and returns a clear error if the Neon SQL steps were skipped.

Render web services must bind to `0.0.0.0` and the port supplied by the `PORT` environment variable. This project does both in `server.ts`.[2]

## 5. Add Render environment variables

When the Blueprint prompts for `sync: false` values, enter them in the Render Dashboard. You can edit them later under **Environment → Environment Variables**. Render supports environment variables and secrets from the service configuration and Advanced settings.[2]

| Variable | Value | Purpose |
|---|---|---|
| `DATABASE_URL` | Neon’s full PostgreSQL connection string | Server-side connection to the initialized Neon database. |
| `JWT_SECRET` | Use Render’s generated value | Signs eight-hour staff sessions. |
| `BNAKOWA_ADMIN_USERNAME` | For example, `admin` | Username for the initial owner account. |
| `BNAKOWA_ADMIN_PASSWORD` | A unique password of at least 10 characters | Password for the initial owner account. Required in production. |
| `DB_POOL_MAX` | `10` | PostgreSQL connection-pool ceiling. |
| `NODE_ENV` | `production` | Enables production behavior and secure cookies. The Blueprint sets it. |
| `NODE_VERSION` | `22.13.0` | Aligns Render with the tested Node version. |

The first successful server startup checks the Neon schema and seed, then creates an owner account with the configured username and password if that username does not already exist. Changing `BNAKOWA_ADMIN_PASSWORD` later does not overwrite an existing account.

## 6. Deploy on Render Free

After adding the variables, click **Apply** or create the Blueprint service. Render runs the build command, then starts the service with `pnpm start`. Render’s Node/Express deployment flow uses the repository build and start commands, and linked Git branches can deploy on future pushes.[3]

If you create the service manually instead of using the Blueprint, use the following settings:

| Render field | Value |
|---|---|
| Language | Node |
| Branch | `main` |
| Build Command | `corepack enable && pnpm install --frozen-lockfile && pnpm build` |
| Start Command | `pnpm start` |
| Health Check Path | `/healthz` |
| Plan | Free for testing and small workloads |

Do not add a pre-deploy command. Complete Neon SQL initialization before clicking the first deployment.

## 7. Verify the first deployment

Once Render reports a successful deploy, open the service URL and perform the following checks.

| Check | Expected result |
|---|---|
| `GET https://YOUR-SERVICE.onrender.com/healthz` | HTTP 200 with `{"status":"ok"}`. |
| `/` | Public B-NAKOWA landing page loads. |
| `/book` | Room search returns Classic Queen, Executive King, and Family Residence for a future valid stay. |
| Booking submission | A confirmation code is returned and the reservation is persisted in Neon. |
| `/operations` | Staff login is shown. |
| Staff login | The Render-configured username and password open the operations dashboard. |
| Inventory | Twelve B-NAKOWA rooms are present; room 202 is in maintenance. |
| Reservation update | Staff can update reservation and housekeeping statuses. |
| CSV export | The reservations export downloads from the Reservations workspace. |

The `/healthz` endpoint checks database connectivity rather than only checking that the Node process is alive. If Neon is unreachable or the SQL scripts were not completed, Render will show an unhealthy service and the logs will identify the missing setup step.

## 8. Security and production readiness

Use a private GitHub repository and restrict GitHub and Render collaborator access. Store `DATABASE_URL`, `JWT_SECRET`, and `BNAKOWA_ADMIN_PASSWORD` only in Render secret environment variables or an approved password manager. Never put them in `client.tsx`, `index.html`, browser storage, or committed files.

The initial owner account is created only when the configured username is absent. Log in after the first deployment, verify the account, and change the password through your controlled staff-account process. If a secret is exposed, rotate the password and `JWT_SECRET`; rotating `JWT_SECRET` invalidates current staff sessions.

The application uses an in-process PostgreSQL pool. Keep `DB_POOL_MAX` conservative and account for every running web instance. Render documents database connection limits and recommends pooling or an appropriately sized database when connection limits are approached.[4]

The seed data includes sample guests, reservations, payment records, and an inactive demonstration property. Before accepting real bookings, remove or reconcile demonstration records and confirm pricing, tax treatment, property details, room inventory, payment workflow, privacy notices, and staff roles.

## 9. Troubleshooting

### The build fails during dependency installation

Confirm that both `package.json` and `pnpm-lock.yaml` are committed. The build uses `pnpm install --frozen-lockfile`, so any dependency change must be committed with a regenerated lockfile:

```bash
pnpm install
pnpm check
pnpm build
git add package.json pnpm-lock.yaml
git commit -m "Update dependencies"
```

### The service says the database schema is missing

Return to Neon SQL Editor and run the complete `001_schema.sql` script. Then run the complete `002_seed.sql` script. The two scripts must be run in that order. Redeploy the Render service after both scripts finish successfully.

### The service says B-NAKOWA seed data is missing

The schema exists but the property seed is absent. Run `002_seed.sql` in Neon SQL Editor once, after confirming that the database is empty or that the data has been reconciled safely.

### `/healthz` returns HTTP 503

Open the Render logs and verify that `DATABASE_URL` is present, begins with `postgres://` or `postgresql://`, and points to the correct Neon database. Confirm that Neon accepts the connection and that the database is not suspended or restricted. The health check intentionally returns 503 when PostgreSQL cannot be reached.

### Login fails after changing `BNAKOWA_ADMIN_PASSWORD`

The variable is used when creating a missing username; it does not overwrite an existing account on every restart. Use the original password, configure a new username for a new owner account, or update the existing account through the controlled staff-account process.

### The seed script reports duplicate-key errors

Stop rerunning `002_seed.sql`. It is a fresh-database seed with fixed demonstration IDs. Use a clean Neon database or reconcile the existing database in staging before trying again.

### Render cannot detect the web port

Confirm that `server.ts` listens on `process.env.PORT` and host `0.0.0.0`. These settings are already present in the supplied project. Render requires a web service to bind to `0.0.0.0` for public traffic.[2]

## 10. Local verification

Run these commands from the project root before pushing:

```bash
pnpm install --frozen-lockfile
pnpm check
pnpm build
```

For a database-backed local smoke test, set the same five server variables in a private shell environment after running the SQL scripts against a safe Neon database:

```bash
export DATABASE_URL='postgresql://...'
export JWT_SECRET='local-development-secret'
export BNAKOWA_ADMIN_USERNAME='admin'
export BNAKOWA_ADMIN_PASSWORD='use-a-private-password'
export DB_POOL_MAX='10'
pnpm dev
curl http://localhost:3000/healthz
```

The expected response is:

```json
{"status":"ok"}
```

## References

[1]: https://render.com/docs/blueprint-spec "Render: Blueprint YAML Reference"
[2]: https://render.com/docs/web-services "Render: Web Services"
[3]: https://render.com/docs/deploy-node-express-app "Render: Deploy a Node Express App"
[4]: https://render.com/docs/postgresql-creating-connecting "Render: Create and Connect to Render Postgres"
