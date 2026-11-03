import { isoWeekday, utcToZoned, zonedToUtc } from '@bouncewith/shared'
import type { TablesInsert, TablesUpdate } from '@bouncewith/shared/database.types'
import { htmlToText, textToHtml } from './description'
import type { EventFormValues, EventRow, Series } from './types'

const toMinutes = (time: string) => {
  const [h, m] = time.split(':').map(Number) as [number, number]
  return h * 60 + m
}

/** Length of the event; an end time before the start means it ends the next day. */
export function durationMinutes(startTime: string, endTime: string): number {
  const d = toMinutes(endTime) - toMinutes(startTime)
  return d > 0 ? d : d + 1440
}

export function emptyValues(today: string): EventFormValues {
  return {
    title: '',
    descriptionText: '',
    category: 'class',
    date: today,
    startTime: '18:00',
    endTime: '19:30',
    repeats: false,
    weekdays: [isoWeekday(today)],
    intervalWeeks: 1,
    until: '',
    location: '',
    locationUrl: '',
    capacity: null,
    deadlineMinutes: null,
    groupIds: [],
    visibility: 'members',
  }
}

export function valuesFromEvent(ev: EventRow, series: Series | null, timeZone: string): EventFormValues {
  const start = utcToZoned(ev.starts_at, timeZone)
  const end = utcToZoned(ev.ends_at, timeZone)
  const deadline = ev.rsvp_deadline
    ? Math.round((Date.parse(ev.starts_at) - Date.parse(ev.rsvp_deadline)) / 60_000)
    : null
  return {
    title: ev.title,
    descriptionText: htmlToText(ev.description),
    category: ev.category ?? '',
    date: start.date,
    startTime: start.time,
    endTime: end.time,
    repeats: !!series,
    weekdays: series ? [...series.weekdays] : [isoWeekday(start.date)],
    intervalWeeks: series?.interval_weeks ?? 1,
    until: series?.until ?? '',
    location: ev.location ?? '',
    locationUrl: ev.location_url ?? '',
    capacity: ev.capacity,
    deadlineMinutes: deadline,
    groupIds: [...ev.group_ids],
    visibility: ev.visibility,
  }
}

const orNull = (s: string) => s.trim() || null

/** Fields of one event row (create a one-off event, or edit a single occurrence). */
export function toEventFields(v: EventFormValues, timeZone: string) {
  const startsAt = zonedToUtc(v.date, v.startTime, timeZone)
  const endsAt = new Date(startsAt.getTime() + durationMinutes(v.startTime, v.endTime) * 60_000)
  return {
    title: v.title.trim(),
    description: textToHtml(v.descriptionText),
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    location: orNull(v.location),
    location_url: orNull(v.locationUrl),
    category: orNull(v.category)?.toLowerCase() ?? null,
    capacity: v.capacity || null,
    rsvp_deadline:
      v.deadlineMinutes == null
        ? null
        : new Date(startsAt.getTime() - v.deadlineMinutes * 60_000).toISOString(),
    visibility: v.visibility,
    group_ids: v.groupIds,
  } satisfies TablesUpdate<'events'>
}

/** Series-level fields, shared by creating a series and update_series(…, 'future'). */
function seriesFields(v: EventFormValues) {
  return {
    title: v.title.trim(),
    description: textToHtml(v.descriptionText),
    location: orNull(v.location),
    location_url: orNull(v.locationUrl),
    category: orNull(v.category)?.toLowerCase() ?? null,
    capacity: v.capacity || null,
    visibility: v.visibility,
    group_ids: v.groupIds,
    start_time: v.startTime,
    duration_min: durationMinutes(v.startTime, v.endTime),
    weekdays: [...v.weekdays].sort(),
    interval_weeks: v.intervalWeeks,
    until: v.until || null,
    rsvp_deadline_minutes: v.deadlineMinutes,
  }
}

export function toSeriesInsert(
  v: EventFormValues,
  workspaceId: string,
  userId: string,
): TablesInsert<'event_series'> {
  return { ...seriesFields(v), workspace_id: workspaceId, starts_on: v.date, created_by: userId }
}

export const toSeriesChanges = (v: EventFormValues): Record<string, unknown> => seriesFields(v)
