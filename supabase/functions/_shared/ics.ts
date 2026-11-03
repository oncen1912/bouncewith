// iCalendar (RFC 5545) for the personal calendar feed. Pure TypeScript: runs in Deno and in Vitest.

export type FeedEvent = {
  id: string
  title: string
  description: string // sanitised HTML
  starts_at: string
  ends_at: string
  location: string | null
  location_url: string | null
  status: 'scheduled' | 'cancelled'
  updated_at: string
  workspace_name: string
  workspace_slug: string
}

/** 20270330T163000Z */
export function icsDate(iso: string): string {
  return new Date(iso)
    .toISOString()
    .replace(/[-:]/g, '')
    .replace(/\.\d{3}/, '')
}

/** Escapes TEXT values: backslash, semicolon, comma, newline. */
export function escapeText(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/;/g, '\;').replace(/,/g, '\\,').replace(/\r?\n/g, '\\n')
}

/** Folds a content line at 75 octets without splitting UTF-8 characters. */
export function fold(line: string): string {
  const encoder = new TextEncoder()
  const out: string[] = []
  let current = ''
  let size = 0
  for (const ch of line) {
    const bytes = encoder.encode(ch).length
    const limit = out.length === 0 ? 75 : 74 // continuation lines start with a space
    if (size + bytes > limit) {
      out.push(current)
      current = ''
      size = 0
    }
    current += ch
    size += bytes
  }
  out.push(current)
  return out.join('\r\n ')
}

export function htmlToPlain(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|li|h\d|blockquote)>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

export function buildCalendar(events: FeedEvent[], appUrl: string, name = 'BounceWith'): string {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//BounceWith//Events//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `X-WR-CALNAME:${escapeText(name)}`,
    'REFRESH-INTERVAL;VALUE=DURATION:PT1H',
    'X-PUBLISHED-TTL:PT1H',
  ]
  for (const e of events) {
    const link = `${appUrl}/w/${e.workspace_slug}/events/${e.id}`
    const text = [htmlToPlain(e.description), link].filter(Boolean).join('\n\n')
    lines.push(
      'BEGIN:VEVENT',
      `UID:${e.id}@bouncewith.me`,
      `DTSTAMP:${icsDate(e.updated_at)}`,
      `LAST-MODIFIED:${icsDate(e.updated_at)}`,
      `SEQUENCE:${Math.floor(Date.parse(e.updated_at) / 1000) % 2_000_000_000}`,
      `DTSTART:${icsDate(e.starts_at)}`,
      `DTEND:${icsDate(e.ends_at)}`,
      `SUMMARY:${escapeText(e.title)}`,
      `DESCRIPTION:${escapeText(text)}`,
      `URL:${link}`,
      `CATEGORIES:${escapeText(e.workspace_name)}`,
      `STATUS:${e.status === 'cancelled' ? 'CANCELLED' : 'CONFIRMED'}`,
    )
    if (e.location) lines.push(`LOCATION:${escapeText(e.location)}`)
    lines.push('END:VEVENT')
  }
  lines.push('END:VCALENDAR')
  return lines.map(fold).join('\r\n') + '\r\n'
}
