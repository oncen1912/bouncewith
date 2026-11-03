import type { Tables } from '@bouncewith/shared/database.types'

export type EventRow = Pick<
  Tables<'events'>,
  | 'id'
  | 'workspace_id'
  | 'series_id'
  | 'occurrence_date'
  | 'is_exception'
  | 'title'
  | 'description'
  | 'starts_at'
  | 'ends_at'
  | 'location'
  | 'location_url'
  | 'category'
  | 'image_url'
  | 'capacity'
  | 'rsvp_deadline'
  | 'status'
  | 'visibility'
  | 'group_ids'
>
export type Series = Tables<'event_series'>

export const EVENT_COLUMNS =
  'id, workspace_id, series_id, occurrence_date, is_exception, title, description, starts_at, ends_at, location, ' +
  'location_url, category, image_url, capacity, rsvp_deadline, status, visibility, group_ids'

export const CATEGORY_SUGGESTIONS = ['class', 'workshop', 'battle', 'performance', 'trip'] as const

export type Tone = 'teal' | 'yellow' | 'pink'

/** Colour coding as on bouncewith.me: workshops yellow, battles/shows pink, everything else teal. */
export function categoryTone(category: string | null | undefined): Tone {
  const c = (category ?? '').toLowerCase()
  if (/workshop|paid|seminar|camp|trip/.test(c)) return 'yellow'
  if (/battle|competition|show|performance|jam/.test(c)) return 'pink'
  return 'teal'
}

/** Values of the event form, all in the workspace timezone. */
export type EventFormValues = {
  title: string
  descriptionText: string
  category: string
  date: string
  startTime: string
  endTime: string
  repeats: boolean
  weekdays: number[]
  intervalWeeks: number
  until: string
  location: string
  locationUrl: string
  capacity: number | null
  deadlineMinutes: number | null
  groupIds: string[]
  visibility: 'members' | 'public'
}

export const DEADLINE_OPTIONS = [null, 60, 120, 240, 1440, 2880] as const
