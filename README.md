# BounceWith

Events, attendance and messaging for dance schools, fitness studios and yoga classes, with an embeddable widget for websites.

- **Product doc:** "BounceWith — Events & Attendance App Spec" (claude.ai)
- **Build spec:** [SPEC.md](SPEC.md)
- **Rules for Claude Code:** [CLAUDE.md](CLAUDE.md)

## Getting started with Claude Code

1. Open this folder in VS Code and start Claude Code.
2. First prompt:
   > Read CLAUDE.md and SPEC.md. Plan milestone M0, then implement it task by task. Ask me before creating the Supabase cloud project.
3. Prerequisites: Node 24, Docker (for `npx supabase start`), a Supabase account, and a GitHub repo for this folder.

## Files already here

| Path | What |
| --- | --- |
| `supabase/migrations/20261101000000_init.sql` | Full initial schema with RLS (tested) |
| `supabase/tests/manual/` | Plain-Postgres stub and RLS smoke test (21 checks); convert to pgTAP in M0 |
