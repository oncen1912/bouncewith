# BounceWith — Build Specification

Version 1.0 · 1 Nov 2026 · Product doc: "BounceWith — Events & Attendance App Spec" (claude.ai)

This file is written for Claude Code. It turns the product doc into buildable tasks.
Conventions and rules are in `CLAUDE.md`.

---

## 1. Goal and scope

A web app (installable PWA; app stores later via Capacitor) at **app.bouncewith.me** where:

- an **Owner** creates a workspace (dance school, fitness studio, yoga class…) and invites trainers and members,
- **Trainers** create one-off or weekly events, see who confirmed, record who actually came, and message members,
- **Members** see their schedule, confirm or decline, check in by QR, chat with trainers and ask an AI assistant,
- **External websites** show a workspace's public events with an embeddable widget and push their own events in through an API.

Out of scope for v1: payments, native apps, member-to-member private chat, file/document storage, the "student learning" area of the original concept.

## 2. Glossary

| Term | Meaning |
| --- | --- |
| Workspace | One organisation (e.g. Niko Dance School). Everything belongs to exactly one workspace. |
| Membership | A user's role (`owner` / `trainer` / `member`) and status (`pending` / `active` / `blocked`) in a workspace. |
| Group | A subset of members (e.g. Juniors). Events and broadcasts can target groups. |
| Event | One occurrence with a start and end time. Recurring events are materialised from an `event_series`. |
| RSVP | A member's answer before the event: `going` / `not_going`. No row = "no answer". |
| Attendance | What actually happened: `present` true or false per member per event, with a full change log. |
| Broadcast | A one-to-many message from a trainer to a chosen audience. Replies go to the member's direct chat. |

## 3. Roles and permissions

| Action | Owner | Trainer | Member |
| --- | :-: | :-: | :-: |
| Edit workspace settings, branding, integrations (API keys, webhooks, widget origins) | ✓ | | |
| Invite / approve / remove members; manage groups | ✓ | ✓ | |
| Promote to trainer, transfer ownership | ✓ | | |
| Create / edit / cancel events and series | ✓ | ✓ | |
| See all RSVPs and attendance; record attendance; reset attendance | ✓ | ✓ | |
| Send broadcasts; read all direct chats | ✓ | ✓ | |
| See events addressed to me (whole workspace or my groups) | ✓ | ✓ | ✓ |
| RSVP for myself; report my absence (if `allow_self_absence`) | ✓ | ✓ | ✓ |
| Check in by QR | | | ✓ |
| Chat: my direct chat with trainers, my groups, events I'm invited to | ✓ | ✓ | ✓ |
| Ask the AI assistant | ✓ | ✓ | ✓ |

A workspace must always have at least one active owner.

## 4. Data model

The starting migration is `supabase/migrations/20261101000000_init.sql` (tested: 21 RLS checks pass on Postgres 16).
Tables: `workspaces, profiles, memberships, groups, group_members, event_series, events, rsvps, attendance,
attendance_log, checkin_tokens, conversations, messages, message_recipients, push_subscriptions, ai_logs,
api_keys, webhooks, webhook_deliveries, pending_signups`.

Key points:
- `events.group_ids = '{}'` means the whole workspace; otherwise only members of those groups (and trainers) see it.
- `events.visibility = 'public'` makes an event available to the public API and the widget.
- `unique (workspace_id, external_id)` on events makes API upserts idempotent.
- `messages.audience` is non-null only for broadcasts; members see a broadcast only if they have a `message_recipients` row.
- Membership writes, RSVPs and attendance have **no** insert/update policies: they go through the functions in §5.

Migrations still to add (in the milestone that needs them):
- M1: RPCs for workspaces and memberships (§5.1)
- M2: `expand_series()` + cron to keep 12 weeks of occurrences ahead
- M3: attendance RPCs, `event_counts()`
- M4: `api_rate_limits` table, `public_events` view for the API
- M5: `send_broadcast()`, realtime broadcast triggers, `realtime.messages` policies

## 5. Database functions (RPC)

All are `security definer`, `set search_path = public`, check permissions with `is_member / is_trainer / is_owner`
and raise errors with stable codes (`raise exception using errcode = 'P0001', message = 'event_full'`) so the UI can translate them.

### 5.1 Workspaces and members (M1)
| Function | Rules |
| --- | --- |
| `create_workspace(p_name text, p_slug text, p_type workspace_type) → uuid` | Any signed-in user. Inserts the workspace + an `owner/active` membership. |
| `join_workspace(p_code text) → membership_status` | Finds a workspace by `join_code`. Creates a membership: `pending` if `require_approval`, else `active`. Idempotent. |
| `approve_member(p_ws uuid, p_user uuid)` / `block_member` / `remove_member` | Trainer+. Can't act on owners unless the caller is an owner. |
| `set_member_role(p_ws, p_user, p_role)` | Owner only. Refuses to demote the last owner. |
| `regenerate_join_code(p_ws) → text` | Owner only. |

### 5.2 Events (M2)
| Function | Rules |
| --- | --- |
| `expand_series(p_series uuid, p_until date default current_date + 84) → int` | Trainer+. Creates missing occurrences for `weekdays` / `interval_weeks` in the workspace timezone (DST-safe: build local timestamps, then `at time zone ws.timezone`). Never touches past or individually edited occurrences. Returns the number created. |
| `update_series(p_series, …, p_scope text)` | `p_scope` ∈ `this` / `future`. `future` updates upcoming occurrences that have no RSVPs, so answered events aren't changed silently. |
| `cancel_event(p_event uuid, p_notify boolean)` | Trainer+. Sets `status = 'cancelled'`; if `p_notify`, sends a broadcast to everyone invited. |

### 5.3 Attendance (M3)
| Function | Rules |
| --- | --- |
| `rsvp(p_event uuid, p_answer rsvp_answer, p_reason text default null)` | Member who can see the event. Event must be `scheduled` and `now() < coalesce(rsvp_deadline, starts_at)`. When `going` and `capacity` is set, raise `event_full` if the count of going ≥ capacity. Upsert. `not_going` respects `allow_self_absence`. |
| `event_counts(p_event uuid) → (invited int, going int, not_going int, no_answer int, present int, absent int)` | Any member who can see the event (counts only, no names). |
| `start_checkin(p_event uuid)` | Trainer+. Inserts `present = true, method = 'default'` for every `going` RSVP without an attendance row (the original concept: confirmed members are present by default and the trainer marks only the exceptions). |
| `mark_attendance(p_event uuid, p_user uuid, p_present boolean)` | Trainer+. Upsert + `attendance_log` row. Also allowed for invited members with no RSVP (walk-ins). |
| `create_checkin_token(p_event uuid, p_minutes int default 30) → text` | Trainer+. Returns a random token (stores only its sha256). The app shows it as a QR code. |
| `qr_checkin(p_token text)` | Member. Token valid and not expired, member can see the event → `present = true, method = 'qr'` + log. |
| `reset_attendance(p_event uuid, p_confirm_title text)` | Trainer+. `p_confirm_title` must equal the event title (the UI asks the user to type it). Logs every removed row (`new_present = null`), then deletes attendance rows **for that event only**. |

### 5.4 Messaging (M5)
| Function | Rules |
| --- | --- |
| `get_or_create_direct(p_ws uuid) → uuid` | Member: their own direct conversation with the trainers. Trainer: pass `p_member`. |
| `send_broadcast(p_ws uuid, p_body text, p_audience jsonb) → uuid` | Trainer+. Audience: `{"scope":"workspace"}`, `{"scope":"group","group_id":…}` or `{"scope":"event","event_id":…,"filter":"confirmed"\|"not_confirmed"\|"all"}`. `not_confirmed` = invited and (no RSVP or `not_going`). Inserts the message + one `message_recipients` row per active recipient, then queues delivery (pg_net → `send-broadcast`). |
| `mark_read(p_message uuid)` | Recipient sets `read_at`. |

## 6. Realtime

Database triggers call `realtime.broadcast_changes(topic, …)` with these topics:

| Topic | Source tables | Who may subscribe (policy on `realtime.messages`) |
| --- | --- | --- |
| `ws:{id}:events` | events | `is_member(id)` |
| `ws:{id}:rsvps` | rsvps (counts only in payload) | `is_member(id)` |
| `ws:{id}:attendance` | attendance | `is_trainer(id)` |
| `conv:{conversation_id}` | messages | `can_see_conversation(conversation_id)` |
| `user:{user_id}:inbox` | message_recipients | `user_id = auth.uid()` |

Channels are created with `{ config: { private: true } }` after `supabase.realtime.setAuth()`.

## 7. Web app

### 7.1 Routes
| Path | Who | Screen |
| --- | --- | --- |
| `/login` | public | Email magic link, email + password, Google |
| `/join/:code` | public → login | Join a workspace by code (also the target of the invite QR) |
| `/w` | signed in | Workspace picker; "Create workspace" |
| `/w/:slug` | member | Home: next 3 events with RSVP buttons, unread messages, "Ask assistant" |
| `/w/:slug/events` | member | List / week / month; filter by group and category; past events |
| `/w/:slug/events/new`, `/w/:slug/events/:id/edit` | trainer | Event form: one-off or weekly series, groups, visibility, capacity, deadline |
| `/w/:slug/events/:id` | member | Details, my RSVP, counts, event chat; trainer: attendee lists by status, broadcast to confirmed / not confirmed / all |
| `/w/:slug/events/:id/checkin` | trainer | Check-in screen: everyone confirmed pre-ticked, tap to toggle, walk-ins, "Show QR", reset (type title to confirm) |
| `/checkin/:token` | member | QR landing: "You're checked in" |
| `/w/:slug/inbox` | member | Broadcasts + my chats; trainer: all direct chats with unread badges |
| `/w/:slug/chat/:conversationId` | member | Chat thread |
| `/w/:slug/members` | trainer | Members, pending approvals, groups, attendance rate per member, CSV export |
| `/w/:slug/settings` | owner | General, branding, join code / invite QR, FAQ for the assistant, **Integrations** (widget snippet + allowed origins, API keys, webhooks) |
| `/me` | signed in | Profile, language, notification settings, my workspaces, delete account |
| `/confirm/:token` | public | Widget sign-up confirmation |

### 7.2 UX rules
- Mobile first: bottom tab bar on phones (Home, Events, Inbox, Assistant, More); sidebar on desktop.
- RSVP is always one tap from the home screen and from push notifications.
- Workspace accent colour themes the app; default dark theme matching bouncewith.me (see `../nikodanceschool/DESIGN-PLAN.md`).
- Empty states explain the next action ("No events yet — create the first one").

## 8. Website integration

### 8.1 Public read API — Edge Function `public-api`
Served at `https://api.bouncewith.me/v1/…` (nginx on Exoscale proxies to `https://<ref>.supabase.co/functions/v1/public-api/…`).
CORS: `Access-Control-Allow-Origin` = the request origin if it is in `workspaces.allowed_origins`, otherwise `*` for GET (read data is public anyway).

| Method + path | Auth | Response |
| --- | --- | --- |
| `GET /v1/w/{slug}/events?from&to&group&limit` | none | `{ data: PublicEvent[] }`, only `visibility = 'public'` and `status = 'scheduled'`; `Cache-Control: public, max-age=60` |
| `GET /v1/w/{slug}/events/{id}` | none | `PublicEvent` incl. `spots_left` |
| `GET /v1/w/{slug}/calendar.ics` | none | iCal feed of public events |
| `PUT /v1/w/{slug}/events/by-external-id/{external_id}` | API key `events:write` | Upsert; body `EventInput`; returns `{ id, created: boolean }` |
| `DELETE /v1/w/{slug}/events/by-external-id/{external_id}` | API key `events:write` | Sets `status = 'cancelled'` |
| `GET /v1/w/{slug}/events/{id}/attendance` | API key `attendance:read` | `{ going, not_going, no_answer, present }` — counts only, never names |

```ts
type PublicEvent = { id: string; title: string; description_html: string; starts_at: string; ends_at: string;
  timezone: string; location: string | null; location_url: string | null; category: string | null;
  image_url: string | null; capacity: number | null; spots_left: number | null; url: string /* app deep link */ }
type EventInput = { title: string; description_html?: string; starts_at: string; ends_at?: string /* default +90 min */;
  location?: string; category?: string; image_url?: string; capacity?: number;
  visibility?: 'public' | 'members' /* default public */; group?: string /* group name */; external_url?: string }
```
- API key format `bw_live_` + 32 random chars, sent as `Authorization: Bearer …`; stored as sha256 in `api_keys.key_hash`. Shown once on creation.
- Errors: `{ error: { code, message } }` with 400 / 401 / 403 / 404 / 409 / 429. Rate limit 60 requests/min per key or IP (`api_rate_limits` table).
- Write calls set `events.source = 'api'`.

### 8.2 Widget — package `widget/`
```html
<script src="https://app.bouncewith.me/widget.js" async></script>
<bouncewith-events workspace="niko-dance" group="Juniors" limit="6" theme="dark" lang="sl"></bouncewith-events>
```
- Vue custom element with Shadow DOM, built to a single file under 60 kB gzipped; no Bootstrap inside (own small CSS).
- Data from the public read API only, with no Supabase client in the widget.
- Each card has a **"Count me in"** button:
  - opens a small form (name, email, consent checkbox with a link to the privacy policy) → `POST /v1/w/{slug}/signup` (Edge Function `widget-signup`): origin must be in `allowed_origins`, rate-limited, honeypot field; stores `pending_signups` and e-mails a confirmation link via Resend;
  - `/confirm/:token` signs the person in (magic link), creates the membership (`pending` or `active` per `require_approval`) and the RSVP;
  - plus a "Already a member? Open in app" link → `https://app.bouncewith.me/w/{slug}/events/{id}?rsvp=going`.
- Also export `<bouncewith-event id="…">` and `<bouncewith-calendar>`. Attributes are reactive. Fires DOM events `bouncewith:rsvp-started` and `bouncewith:signup-sent`.
- Settings → Integrations shows a copy-paste snippet and a live preview.

### 8.3 Outgoing webhooks — Edge Function `webhook-dispatch` (M7)
Event types: `event.created`, `event.updated`, `event.cancelled`, `rsvp.changed`, `attendance.recorded`.
Body `{ id, type, created_at, workspace: slug, data }`; header `BounceWith-Signature: t=<unix>,v1=<hex hmac_sha256(secret, t + "." + body)>`.
Retries with backoff (1 min, 5 min, 30 min, 2 h, 12 h), then `failed`.

### 8.4 bouncewith.me bridge (M4)
In the **nikodanceschool** repo (not this one):
1. Edge Function `push-to-bouncewith`, triggered by a Database Webhook on `events` insert/update/delete.
2. Mapping: `external_id = 'nds-' || id`; `date` + `time` → `starts_at` in Europe/Zurich; `ends_at = starts_at + 90 min`;
   `type` (free/paid/workshop) → `category`; `capacity`, `image_url`, `title`, `description` copied; `visibility = 'public'`;
   `external_url = https://bouncewith.me/events/<id>`. Delete → `DELETE …/by-external-id/nds-<id>`.
3. Secrets: `BOUNCEWITH_API_KEY` (scope `events:write`), `BOUNCEWITH_WORKSPACE=niko-dance`.
4. One-off backfill script pushes all existing upcoming events.
5. Later (M7): the site's Events page uses `<bouncewith-events workspace="niko-dance">`; its own bookings table is retired after
   existing bookers are invited (CSV export → invitation e-mails with the join link).

## 9. Notifications

| Trigger | Channel | Default |
| --- | --- | --- |
| Broadcast | in-app + push + email | all on; the member can switch off push/email |
| RSVP reminder ("no answer" members, 24 h before; configurable per workspace) | push, email fallback | on |
| Event cancelled / time changed | in-app + push + email | always |
| New direct message | in-app + push | on |
| Membership approved | email | always |

Edge Functions: `send-broadcast` (fan-out: push via VAPID, email via Resend in batches of 50, sets `pushed_at` / `emailed_at`),
`reminders` (Supabase Cron every 15 min). Expired push endpoints (HTTP 404/410) are deleted.

## 10. AI assistant — Edge Function `ai-assistant`

- Input `{ workspace_id, messages[] }` with the user's JWT; verifies `is_member`. Model name from secret `CLAUDE_MODEL` (a small, fast model).
- Tools (each runs SQL **as the calling user**, so RLS applies):
  `list_events(from, to, group?)`, `get_event(id)`, `get_my_rsvps(from, to)`, `get_workspace_info()` (name, timezone, FAQ),
  `rsvp(event_id, answer)` (only after the user explicitly confirms in the chat), `handoff_to_trainer(question)` (posts into the user's direct chat).
- System prompt rules: answer only about this workspace's schedule, places and FAQ; say "I don't know" and offer a hand-off otherwise;
  short answers in the user's language; never reveal other members' names or answers; age-appropriate tone.
- Log question, answer and `handed_off` to `ai_logs`; trainers can review them to improve the FAQ.
- Limit: 30 questions per user per day.

## 11. Non-functional

- **Privacy:** Supabase project in an EU region; privacy policy covering minors (parental consent where required); account deletion removes the profile (cascade) and anonymises `attendance_log.changed_by`. Only first names in AI prompts.
- **Security:** RLS on every table; pgTAP cross-workspace tests; DOMPurify on rich text; CSP on app.bouncewith.me; no secrets in `VITE_*`.
- **Accessibility:** WCAG 2.2 AA contrast, keyboard navigation, 44 px touch targets.
- **Performance:** first load < 200 kB JS gzipped for `/w/:slug`; widget < 60 kB.
- **CI:** Node 24; actions pinned to release tags or SHAs; lint + typecheck + unit + pgTAP on every PR; Playwright smoke on tag.

## 12. Milestones and tasks

Phase 1 of the product doc = M0 to M4. Tick boxes as you finish.

### M0 — Foundation
- [x] npm workspaces (`web`, `widget`, `shared`), TypeScript strict, ESLint + Prettier, Vitest, Playwright
- [x] Supabase project (EU) + local `supabase start`; add the init migration; `npm run db:types` — cloud: `opfanxmublhjxyjgyjqu`, Zurich
- [x] Convert `supabase/tests/manual/rls_smoke.sql` into pgTAP tests (`supabase/tests/rls.test.sql`)
- [x] `seed.sql`: workspace `niko-dance`, 1 owner, 1 trainer, 6 members, group Juniors, 4 upcoming events
- [x] Web shell: router, i18n (en/sl/de), layout (tab bar / sidebar), dark theme tokens, vue-sonner
- [ ] Auth: magic link, email + password, Google; `/me` page — magic link, password and `/me` done and e2e-tested locally; Google is wired but needs OAuth credentials in the cloud project
- [ ] CI workflow; deploy workflow to Exoscale (`app.bouncewith.me`) on tags — CI green on PR #1; deploy waits for production secrets + server
- **Done when:** a seeded user logs in on the deployed URL and sees the empty home; CI is green.

### M1 — Workspaces and members
- [ ] RPCs §5.1 + pgTAP
- [ ] Create workspace, workspace picker, switcher
- [ ] Join by code, link and QR; pending approvals list
- [ ] Members list, roles, groups CRUD
- [ ] Settings: general, branding (logo upload to Storage, accent colour), timezone, approval toggle
- **Done when:** a second user joins by QR, is approved, and only sees that workspace.

### M2 — Events
- [ ] Event form (one-off + weekly series), `expand_series()`, cron to extend series
- [ ] Event list / week / month views, filters, past events
- [ ] Event detail; edit "this / future"; cancel with notification
- [ ] Personal iCal feed per user (secret URL)
- **Done when:** a weekly class appears 12 weeks ahead in the correct local time across the DST change on 28 Mar 2027.

### M3 — Attendance
- [ ] RPCs §5.3 + pgTAP (deadline, capacity, cross-workspace, reset keeps other events' history)
- [ ] RSVP buttons on home, list and detail; reasons for "Can't make it"
- [ ] Trainer counts + attendee lists by status
- [ ] Check-in screen (default present for confirmed, toggles, walk-ins), QR check-in
- [ ] Reset with typed confirmation; attendance history per member; CSV export
- **Done when:** a trainer checks in a class of 15 in under 30 seconds on a phone.

### M4 — Website integration
- [ ] `public-api` read endpoints + iCal, CORS, caching, rate limit
- [ ] API keys UI (create, show once, revoke) + write endpoints (upsert by external_id, cancel)
- [ ] `widget/` custom elements, `widget-signup`, `/confirm/:token`, allowed origins UI, snippet + preview
- [ ] nikodanceschool bridge (§8.4) + backfill
- **Done when:** an event created in the bouncewith.me admin appears in BounceWith within 10 s, and a visitor can sign up and RSVP from the widget.

### M5 — Messaging and notifications
- [ ] Conversations, chat UI, realtime topics §6
- [ ] Broadcasts with audiences; replies go to the direct chat; read receipts for trainers
- [ ] Web push (service worker, VAPID), email via Resend, notification settings
- [ ] RSVP reminders cron
- **Done when:** a broadcast to "not confirmed" for an event reaches exactly those members by push and email.

### M6 — AI assistant
- [ ] `ai-assistant` function with tools §10, FAQ editor, hand-off, `ai_logs` review screen, daily limit
- **Done when:** "When is my next class?" is answered correctly in sl, de and en, and unknown questions are handed off.

### M7 — Grow
- [ ] Outgoing webhooks + delivery log UI
- [ ] Member attendance stats dashboard
- [ ] bouncewith.me switched to the widget; bookings retired
- [ ] PWA install prompts; Capacitor spike for app stores

## 13. Open questions (defaults used until answered)

| Question | Default in this spec |
| --- | --- |
| Can trainers message people who aren't in the app? | No. They're reached through the widget sign-up and invite links. |
| Do parents need linked accounts? | Not in v1; a parent can use the child's account. Revisit before M5. |
| Free or paid product? | Free; no billing code in v1. |
| Languages | en, sl, de at launch; fr later. |

## Decisions log
(Claude Code: append dated one-line decisions here.)
- 2026-11-01 · M0 · Local Supabase runs Postgres 17 (CLI default); the init migration applies unchanged on 17.
- 2026-11-01 · M0 · TypeScript pinned to ~6.0 (typescript-eslint supports < 6.1); Pinia pinned to 3 as CLAUDE.md says, although Pinia 4 exists.
- 2026-11-01 · M0 · Generated types live at `shared/database.types.ts`; CI fails if they are stale.
- 2026-11-01 · M0 · `rls.test.sql` adds a cross-workspace denial check for every tenant table (with positive controls) and checks that members can't write rsvps/attendance/memberships directly. The manual smoke files were removed after the port.
- 2026-11-01 · M0 · Seed adds a second small workspace `yoga-zug` for cross-tenant checks; all seed users sign in locally with password `bouncewith`. One niko-dance member is `pending`.
- 2026-11-01 · M0 · Magic link, sign-up confirmation and Google all return through `/auth/callback?next=…` (PKCE). `next` only accepts same-origin paths.
- 2026-11-01 · M0 · UI language: stored choice → browser language → en; once signed in, `profiles.locale` wins and `/me` saves it.
- 2026-11-01 · M0 · System font stack instead of Google Fonts (no third-party requests, simpler CSP, GDPR).
- 2026-11-01 · M0 · Events/Inbox/Assistant tabs point to a "Coming soon" placeholder until M2/M5/M6. "More" opens `/me`.
- 2026-11-01 · M0 · `/me` → "Delete account" is deferred to M1: it needs an Edge Function with the secret key (§11 anonymisation).
- 2026-11-01 · M0 · The deploy workflow runs a Playwright smoke against a local Supabase in CI, then `supabase db push`, then rsyncs `web/dist` (which includes `widget.js`). nginx config in `deploy/`.
- 2026-11-01 · M0 · vue-i18n uses the full build (≈42 kB gz); first-load JS is ≈127 kB gz. Switch to precompiled messages if the 200 kB budget gets tight.
- 2026-11-02 · M0 · Cloud project in Supabase region Zurich (`eu-central-2`), org "oncen1912's Org". This replaces "EU region" in §11: Switzerland has an EU adequacy decision.
- 2026-11-02 · M0 · The cloud project gets no seed data. `npm run demo:create` (secret key from the gitignored `.env.cloud`, run locally) creates workspace `demo` with a demo owner and member; the deploy workflow's `verify` job signs in as the demo member on app.bouncewith.me.
