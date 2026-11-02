# BounceWith — CLAUDE.md

Multi-workspace app for scheduling events, tracking attendance and messaging members
(dance schools, fitness studios, yoga classes). Trainers create events, members confirm,
trainers record who showed up and message the group. Public websites (first: bouncewith.me)
embed events through a widget and an API.

**Read `SPEC.md` before starting any task.** It is the source of truth for scope, data model,
API and milestones. If code and SPEC disagree, ask before changing the SPEC.

## Stack

| Layer | Choice |
| --- | --- |
| Frontend | Vue 3.5 (Composition API, `<script setup lang="ts">`), TypeScript, Vite 8, Pinia 3, Vue Router 5 |
| UI | Bootstrap 5.3 + bootstrap-icons, `vue-sonner` for toasts, `vue-i18n` (en, sl, de; fr later) |
| Backend | Supabase: Postgres + RLS, Auth, Realtime **Broadcast** (private channels), Edge Functions (Deno), Cron |
| Email | Resend (sender domain bouncewith.me) |
| Push | Web Push (VAPID) via service worker |
| AI | Claude API (small, fast model) called only from the `ai-assistant` Edge Function |
| Widget | Vue custom element (`defineCustomElement`) built as a single `widget.js` |
| Tests | Vitest (unit), pgTAP via `supabase test db` (RLS + SQL functions), Playwright (e2e smoke) |
| Hosting | Static build on Exoscale (`my.bouncewith.me`), deployed by GitHub Actions on `v*.*.*` tags |

The reference implementation for patterns (auth store, router guards, TinyMCE, deploy workflow)
is the sibling repo `../nikodanceschool`. Reuse ideas from it, but follow the rules below where they differ.

## Repo layout

```
bouncewith/
├── CLAUDE.md, SPEC.md
├── package.json              # npm workspaces: web, widget, shared
├── web/                      # the app (Vite + Vue)
│   └── src/
│       ├── app/              # main.ts, router, i18n, supabase client
│       ├── features/         # events/, attendance/, messaging/, workspace/, assistant/, auth/
│       │   └── <feature>/    # components/, store.ts, api.ts, types.ts, *.spec.ts
│       ├── components/       # shared UI only
│       └── locales/          # en.json, sl.json, de.json
├── widget/                   # <bouncewith-events> custom element → dist/widget.js
├── shared/                   # database.types.ts (generated), date/format helpers used by web + widget
├── supabase/
│   ├── config.toml
│   ├── migrations/           # ALL schema changes, never edit the DB in the dashboard
│   ├── functions/            # public-api, widget-signup, ai-assistant, send-broadcast, reminders, webhook-dispatch
│   ├── tests/                # pgTAP tests (*.test.sql)
│   └── seed.sql              # demo workspace "niko-dance" with trainers, members, events
└── .github/workflows/        # ci.yml (lint, typecheck, tests), deploy.yml (tag → Exoscale)
```

## Commands

```bash
npm install
npx supabase start                 # local Supabase (Docker)
npx supabase db reset              # apply migrations + seed.sql
npm run db:types                   # supabase gen types typescript --local > shared/database.types.ts
npm run dev -w web                 # http://localhost:5173
npm run dev -w widget              # widget playground page
npx supabase functions serve       # Edge Functions locally
npm run lint && npm run typecheck
npm test                           # vitest
npx supabase test db               # pgTAP / RLS tests
npm run e2e                        # playwright
```

## Non-negotiable rules

1. **Tenancy.** Every table except `profiles` has `workspace_id`. RLS is enabled on every table and is the real
   security boundary. Never rely on the UI to hide data.
2. **Schema changes only by migration.** `npx supabase migration new <name>`, then `npm run db:types`.
   Every new table ships with RLS policies and a pgTAP test that proves another workspace can't read it.
3. **Business rules live in SQL functions** (RPC), not in the browser: `rsvp()`, `mark_attendance()`,
   `reset_attendance()`, `qr_checkin()`, `send_broadcast()`, membership changes. Members have no direct
   insert or update rights on `rsvps`, `attendance` or `memberships`.
4. **Keys.** The browser and widget use only `VITE_SUPABASE_URL` + `VITE_SUPABASE_PUBLISHABLE_KEY` (`sb_publishable_…`).
   The secret key (`sb_secret_…`), Resend, VAPID and Claude keys exist only as Edge Function secrets.
   Never use legacy `anon` / `service_role` JWT keys.
5. **Realtime = Broadcast from database** on private channels named `ws:{workspace_id}:{entity}`
   (`events`, `rsvps`, `attendance`, `conv:{conversation_id}`). Do not use `postgres_changes`.
6. **Minors are users.** There are no member-to-member private chats. Direct chats are member ↔ the workspace's trainers,
   and every trainer can read them. Keep personal data minimal and never send it to the AI beyond what a question needs.
7. **Time.** Store `timestamptz`; display in `workspaces.timezone` (default `Europe/Zurich`). Never store local times as text.
8. **i18n.** No hard-coded UI strings: use `t('…')`, add keys to `en.json` first.
9. **Never hard-delete** events or attendance. Cancel events (`status = 'cancelled'`); attendance changes are logged in `attendance_log`.
10. **Rich text** (event descriptions, FAQ) is sanitised on save (DOMPurify) and rendered with `v-html` only after sanitising.

## Definition of done (every task)

- `npm run lint`, `npm run typecheck`, `npm test` and `npx supabase test db` pass
- New SQL has pgTAP coverage, including a cross-workspace denial test
- UI works at 375 px width (phone) and with keyboard only; strings exist in en/sl/de
- The milestone checklist in `SPEC.md` is ticked for what was finished

## Working style

- Work one milestone task at a time (SPEC.md §12). Start with a short plan, then implement, then run the checks.
- Prefer small, readable components (< 250 lines). Split before a file becomes a second `AdminDashboard.vue`.
- When a SPEC detail is missing, choose the simplest option, note it under "Decisions log" at the end of SPEC.md, and continue.
