import { describe, expect, it } from 'vitest'
import { buildCalendar, escapeText, fold, htmlToPlain, icsDate, type FeedEvent } from './ics.ts'

const event: FeedEvent = {
  id: 'e1',
  title: 'Hip Hop; Basics, Level 1',
  description: '<p>Bring water &amp; shoes</p><p>Second</p>',
  starts_at: '2027-03-30T16:30:00Z',
  ends_at: '2027-03-30T18:00:00Z',
  location: 'Studio Bounce',
  location_url: null,
  status: 'scheduled',
  updated_at: '2026-11-03T10:00:00Z',
  workspace_name: 'Niko Dance School',
  workspace_slug: 'niko-dance',
}

describe('ics', () => {
  it('formats UTC dates', () => {
    expect(icsDate('2027-03-30T16:30:00.000Z')).toBe('20270330T163000Z')
  })

  it('escapes text values', () => {
    expect(escapeText('a;b,c\\d\ne')).toBe('a\;b\\,c\\\\d\\ne')
  })

  it('folds long lines at 75 octets without breaking characters', () => {
    const folded = fold('DESCRIPTION:' + 'č'.repeat(60))
    for (const line of folded.split('\r\n'))
      expect(new TextEncoder().encode(line).length).toBeLessThanOrEqual(75)
    expect(folded.replace(/\r\n /g, '')).toBe('DESCRIPTION:' + 'č'.repeat(60))
  })

  it('strips HTML for descriptions', () => {
    expect(htmlToPlain(event.description)).toBe('Bring water & shoes\nSecond')
  })

  it('builds a calendar with CRLF lines', () => {
    const ics = buildCalendar(
      [event, { ...event, id: 'e2', status: 'cancelled' }],
      'https://app.bouncewith.me',
    )
    expect(ics.startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n')).toBe(true)
    expect(ics.endsWith('END:VCALENDAR\r\n')).toBe(true)
    expect(ics).toContain('SUMMARY:Hip Hop\; Basics\\, Level 1')
    expect(ics).toContain('DTSTART:20270330T163000Z')
    expect(ics).toContain('URL:https://app.bouncewith.me/w/niko-dance/events/e1')
    expect(ics).toContain('STATUS:CANCELLED')
    expect(ics.match(/BEGIN:VEVENT/g)).toHaveLength(2)
    expect(ics.split('\r\n').every((l) => !l.includes('\n'))).toBe(true)
  })
})
