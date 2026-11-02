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
