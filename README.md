# BounceWith

Events, attendance and messaging for dance schools, fitness studios and yoga classes, with an embeddable widget for websites.

- **Product doc:** "BounceWith — Events & Attendance App Spec" (claude.ai)
- **Build spec:** [SPEC.md](SPEC.md)
- **Rules for Claude Code:** [CLAUDE.md](CLAUDE.md)

## Local development

Prerequisites: Node 24 and Docker.

```bash
npm install
npx supabase start          # local Supabase; prints the URL + publishable key
cp .env.example .env.local  # fill in VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY from the output above
npx supabase db reset       # migrations + seed
npm run dev -w web          # http://localhost:5173
```

Seed logins (password `bouncewith`): `owner@niko-dance.example`, `trainer@niko-dance.example`,
`mia@niko-dance.example` (member, en), `ana@niko-dance.example` (member in Juniors, sl), `owner@yoga-zug.example`.
Magic-link e-mails land in Mailpit at http://127.0.0.1:54324.

Checks: `npm run lint`, `npm run typecheck`, `npm test`, `npx supabase test db`, `npm run e2e`.

## Deployment

Pushing a `v*.*.*` tag runs `.github/workflows/deploy.yml`: Playwright smoke against a local Supabase, then
`supabase db push` to the cloud project, then rsync of `web/dist` to Exoscale. GitHub secrets (environment `production`):

| Secret | Value |
| --- | --- |
| `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` | cloud project URL + `sb_publishable_…` key |
| `SUPABASE_PROJECT_REF`, `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD` | for `supabase db push` |
| `REMOTE_HOST`, `REMOTE_USER`, `SSH_PRIVATE_KEY`, `REMOTE_TARGET` | Exoscale server (see `deploy/nginx-app.bouncewith.me.conf`) |
| `E2E_EMAIL`, `E2E_PASSWORD` | demo member from `npm run demo:create`, used by the post-deploy smoke test |

The cloud project has no seed data. `npm run demo:create` (reads the gitignored `.env.cloud`, see `.env.example`)
creates the `demo` workspace with `demo-owner@bouncewith.me` and `demo-member@bouncewith.me`.

## Key files

| Path | What |
| --- | --- |
| `supabase/migrations/20261101000000_init.sql` | Full initial schema with RLS (tested) |
| `supabase/tests/rls.test.sql` | pgTAP RLS tests incl. cross-workspace denial for every table |
