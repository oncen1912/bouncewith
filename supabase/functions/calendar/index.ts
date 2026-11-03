// Personal iCal feed: GET /functions/v1/calendar/<token>.ics
// No user session and no secret key: calendar_feed() (security definer) treats the 48-hex token as the
// credential and applies the same visibility rules as RLS. Calendar apps poll this about once an hour.
import { buildCalendar, type FeedEvent } from '../_shared/ics.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const APP_URL = Deno.env.get('APP_URL') ?? 'https://app.bouncewith.me'

function publishableKey(): string {
  const raw = Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? ''
  try {
    const keys = JSON.parse(raw) as Record<string, string>
    return keys.default ?? Object.values(keys)[0] ?? ''
  } catch {
    return raw
  }
}

const text = (body: string, status: number) =>
  new Response(body, { status, headers: { 'Content-Type': 'text/plain; charset=utf-8' } })

Deno.serve(async (req) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') return text('Method not allowed', 405)
  const token =
    new URL(req.url).pathname
      .split('/')
      .pop()
      ?.replace(/\.ics$/, '') ?? ''
  if (!/^[0-9a-f]{48}$/.test(token)) return text('Not found', 404)

  const key = publishableKey()
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/calendar_feed`, {
    method: 'POST',
    headers: { apikey: key, 'Content-Type': 'application/json' },
    body: JSON.stringify({ p_token: token }),
  })
  if (!res.ok) return text('Calendar unavailable', 502)
  const events = (await res.json()) as FeedEvent[]
  // an unknown token looks the same as an empty calendar would not be helpful: say so
  if (events.length === 0) {
    const known = await fetch(`${SUPABASE_URL}/rest/v1/rpc/calendar_feed_exists`, {
      method: 'POST',
      headers: { apikey: key, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_token: token }),
    }).then((r) => (r.ok ? r.json() : false))
    if (known !== true) return text('Not found', 404)
  }

  return new Response(req.method === 'HEAD' ? null : buildCalendar(events, APP_URL), {
    headers: {
      'Content-Type': 'text/calendar; charset=utf-8',
      'Content-Disposition': 'inline; filename="bouncewith.ics"',
      'Cache-Control': 'private, max-age=900',
    },
  })
})
