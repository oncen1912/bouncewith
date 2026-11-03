import { describe, expect, it } from 'vitest'
import {
  addDays,
  formatDate,
  formatTime,
  formatTimeRange,
  isoWeekday,
  localDateKey,
  monthGrid,
  startOfWeek,
  utcToZoned,
  weekdayNames,
  zonedToUtc,
} from './datetime'

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

describe('zonedToUtc / utcToZoned', () => {
  it('converts local wall-clock time to an instant, both sides of DST', () => {
    expect(zonedToUtc('2027-03-23', '18:30').toISOString()).toBe('2027-03-23T17:30:00.000Z')
    expect(zonedToUtc('2027-03-30', '18:30').toISOString()).toBe('2027-03-30T16:30:00.000Z')
    expect(zonedToUtc('2026-12-01', '09:00', 'Europe/Ljubljana').toISOString()).toBe(
      '2026-12-01T08:00:00.000Z',
    )
    expect(zonedToUtc('2026-07-01', '09:00', 'America/New_York').toISOString()).toBe(
      '2026-07-01T13:00:00.000Z',
    )
  })

  it('moves a time inside the spring-forward gap to a real instant', () => {
    // 02:30 doesn't exist in Zurich on 28 Mar 2027; the result must be a valid instant that day
    const t = zonedToUtc('2027-03-28', '02:30')
    expect(utcToZoned(t).date).toBe('2027-03-28')
  })

  it('round-trips', () => {
    for (const [date, time] of [
      ['2027-03-27', '23:45'],
      ['2027-10-31', '01:15'],
      ['2026-11-03', '00:00'],
    ] as const) {
      expect(utcToZoned(zonedToUtc(date, time))).toEqual({ date, time })
    }
  })
})

describe('calendar days', () => {
  it('adds days across month ends and DST without drifting', () => {
    expect(addDays('2027-03-27', 2)).toBe('2027-03-29')
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01')
  })

  it('knows ISO weekdays and week starts', () => {
    expect(isoWeekday('2026-11-02')).toBe(1)
    expect(isoWeekday('2026-11-08')).toBe(7)
    expect(startOfWeek('2026-11-05')).toBe('2026-11-02')
  })

  it('builds a Monday-first month grid of whole weeks', () => {
    const grid = monthGrid('2026-11-15')
    expect(grid[0]).toBe('2026-10-26')
    expect(grid.length % 7).toBe(0)
    expect(grid).toContain('2026-11-30')
    expect(grid.at(-1)).toBe('2026-12-06')
  })

  it('names weekdays Monday first', () => {
    expect(weekdayNames('en')[0]).toBe('Mon')
    expect(weekdayNames('de')[6]).toBe('So')
  })
})
