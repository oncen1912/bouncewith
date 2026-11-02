import { describe, expect, it } from 'vitest'
import { formatDate, formatTime, formatTimeRange, localDateKey } from './datetime'

describe('datetime', () => {
  it('shows times in the workspace timezone, not UTC', () => {
    // 17:30 UTC in winter = 18:30 in Zurich (CET, UTC+1)
    expect(formatTime('2026-12-01T17:30:00Z', 'de')).toBe('18:30')
  })

  it('follows DST: the same local class time maps to different UTC offsets', () => {
    // 28 Mar 2027 is the DST switch; a 18:30 class is 17:30Z before and 16:30Z after
    expect(formatTime('2027-03-27T17:30:00Z', 'sl')).toBe('18:30')
    expect(formatTime('2027-03-29T16:30:00Z', 'sl')).toBe('18:30')
  })

  it('formats a time range', () => {
    expect(formatTimeRange('2026-12-01T17:30:00Z', '2026-12-01T19:00:00Z', 'en')).toBe('18:30–20:00')
  })

  it('uses the local calendar day near midnight', () => {
    expect(localDateKey('2026-12-01T23:30:00Z')).toBe('2026-12-02')
    expect(localDateKey('2026-12-01T23:30:00Z', 'UTC')).toBe('2026-12-01')
  })

  it('localises date names', () => {
    expect(formatDate('2026-12-01T12:00:00Z', 'de')).toBe('Di., 1. Dez.')
  })
})
