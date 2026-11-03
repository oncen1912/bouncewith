// Display helpers. Values are stored as timestamptz (ISO strings in the API) and shown
// in the workspace timezone, never in the browser's timezone (CLAUDE.md rule 7).

export const DEFAULT_TIMEZONE = 'Europe/Zurich'

type DateInput = string | Date

const toDate = (value: DateInput) => (typeof value === 'string' ? new Date(value) : value)

/** "Tue, 3 Nov" style date in the given timezone and locale. */
export function formatDate(value: DateInput, locale: string, timeZone = DEFAULT_TIMEZONE): string {
  return new Intl.DateTimeFormat(locale, {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    timeZone,
  }).format(toDate(value))
}

/** "18:30" style time (24 h for en too, matching the European audience). */
export function formatTime(value: DateInput, locale: string, timeZone = DEFAULT_TIMEZONE): string {
  return new Intl.DateTimeFormat(locale, {
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
    timeZone,
  }).format(toDate(value))
}

/** "18:30–20:00" for a single event. */
export function formatTimeRange(
  start: DateInput,
  end: DateInput,
  locale: string,
  timeZone = DEFAULT_TIMEZONE,
): string {
  return `${formatTime(start, locale, timeZone)}–${formatTime(end, locale, timeZone)}`
}

/** Calendar date (YYYY-MM-DD) of an instant in the given timezone. */
export function localDateKey(value: DateInput, timeZone = DEFAULT_TIMEZONE): string {
  // en-CA formats as YYYY-MM-DD
  return new Intl.DateTimeFormat('en-CA', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    timeZone,
  }).format(toDate(value))
}

// ───────── wall-clock time in a timezone ↔ instants ─────────
// Date-only values are 'YYYY-MM-DD' strings and times 'HH:MM', always meant in the workspace timezone.

const partsFormatters = new Map<string, Intl.DateTimeFormat>()
function partsFormatter(timeZone: string) {
  let f = partsFormatters.get(timeZone)
  if (!f) {
    f = new Intl.DateTimeFormat('en-US', {
      timeZone,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })
    partsFormatters.set(timeZone, f)
  }
  return f
}

function zonedParts(ts: number, timeZone: string) {
  const p = Object.fromEntries(
    partsFormatter(timeZone)
      .formatToParts(ts)
      .map((x) => [x.type, x.value]),
  )
  return { y: +p.year!, m: +p.month!, d: +p.day!, h: +p.hour!, mi: +p.minute!, s: +p.second! }
}

/** Offset of the timezone at an instant, in ms (local − UTC). */
function offsetAt(ts: number, timeZone: string) {
  const p = zonedParts(ts, timeZone)
  return Date.UTC(p.y, p.m - 1, p.d, p.h, p.mi, p.s) - Math.floor(ts / 1000) * 1000
}

/** Instant of a local date + time in the given timezone (DST-safe; times in a spring-forward gap move forward). */
export function zonedToUtc(date: string, time: string, timeZone = DEFAULT_TIMEZONE): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number]
  const [h, mi] = time.split(':').map(Number) as [number, number]
  const guess = Date.UTC(y, m - 1, d, h, mi)
  const first = guess - offsetAt(guess, timeZone)
  const second = guess - offsetAt(first, timeZone)
  return new Date(second)
}

/** Local date and time of an instant in the given timezone. */
export function utcToZoned(value: DateInput, timeZone = DEFAULT_TIMEZONE): { date: string; time: string } {
  const p = zonedParts(toDate(value).getTime(), timeZone)
  const pad = (n: number) => String(n).padStart(2, '0')
  return { date: `${p.y}-${pad(p.m)}-${pad(p.d)}`, time: `${pad(p.h)}:${pad(p.mi)}` }
}

// ───────── calendar-day arithmetic on 'YYYY-MM-DD' strings ─────────

const dayMs = 86_400_000
const toDay = (date: string) => Date.UTC(+date.slice(0, 4), +date.slice(5, 7) - 1, +date.slice(8, 10))
const fromDay = (ts: number) => new Date(ts).toISOString().slice(0, 10)

export function addDays(date: string, days: number): string {
  return fromDay(toDay(date) + days * dayMs)
}

/** ISO weekday: 1 = Monday … 7 = Sunday. */
export function isoWeekday(date: string): number {
  return ((new Date(toDay(date)).getUTCDay() + 6) % 7) + 1
}

export function startOfWeek(date: string): string {
  return addDays(date, 1 - isoWeekday(date))
}

export function daysBetween(from: string, to: string): number {
  return Math.round((toDay(to) - toDay(from)) / dayMs)
}

/** Monday-first grid of whole weeks covering the month of `date` (35 or 42 days). */
export function monthGrid(date: string): string[] {
  const first = `${date.slice(0, 7)}-01`
  const nextMonth = addDays(first, 32).slice(0, 7) + '-01'
  const start = startOfWeek(first)
  const weeks = Math.ceil(daysBetween(start, nextMonth) / 7)
  return Array.from({ length: weeks * 7 }, (_, i) => addDays(start, i))
}

/** "Mon 3", "Tue 4"… labels for a Monday-first week in the given locale. */
export function weekdayNames(locale: string, style: 'short' | 'narrow' | 'long' = 'short'): string[] {
  const f = new Intl.DateTimeFormat(locale, { weekday: style, timeZone: 'UTC' })
  return Array.from({ length: 7 }, (_, i) => f.format(Date.UTC(2024, 0, 1 + i))) // 1 Jan 2024 is a Monday
}

export function formatMonth(date: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, { month: 'long', year: 'numeric', timeZone: 'UTC' }).format(
    toDay(date),
  )
}

export function formatDayLong(date: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    timeZone: 'UTC',
  }).format(toDay(date))
}
