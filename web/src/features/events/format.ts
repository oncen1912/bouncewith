import { daysBetween, localDateKey } from '@bouncewith/shared'

/** "Today", "Tomorrow", "In 3 days", "2 days ago", in the UI language, counted in workspace days. */
export function relativeDay(startsAt: string, locale: string, timeZone: string, now = new Date()): string {
  const days = daysBetween(localDateKey(now, timeZone), localDateKey(startsAt, timeZone))
  const text = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(days, 'day')
  return text.charAt(0).toUpperCase() + text.slice(1)
}

/** "Every Tue, Thu", "Every 2 weeks on Mon" … in the UI language. */
export function describeWeekly(
  weekdays: number[],
  intervalWeeks: number,
  dayNames: string[],
  t: (key: string, values?: Record<string, unknown>) => string,
): string {
  const days = [...weekdays]
    .sort()
    .map((d) => dayNames[d - 1])
    .join(', ')
  return intervalWeeks > 1
    ? t('events.everyNWeeks', { n: intervalWeeks, days })
    : t('events.everyWeek', { days })
}
