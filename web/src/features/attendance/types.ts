import type { Database, Enums } from '@bouncewith/shared/database.types'

type Fn<N extends keyof Database['public']['Functions']> = Database['public']['Functions'][N]['Returns']
type Nullable<T, K extends keyof T> = Omit<T, K> & { [P in K]: T[P] | null }

export type Answer = Enums<'rsvp_answer'>
export type MyAnswer = { answer: Answer; reason: string | null }
export type Counts = Fn<'event_counts_many'>[number]
// generated types mark every column of `returns table` as non-null; restore the nullable ones
export type Attendee = Nullable<
  Fn<'event_attendees'>[number],
  'role' | 'answer' | 'reason' | 'answered_at' | 'present' | 'method' | 'marked_at'
>
export type Candidate = Fn<'checkin_candidates'>[number]
export type HistoryRow = Nullable<Fn<'member_attendance'>[number], 'answer' | 'reason' | 'present' | 'method'>
export type Summary = Fn<'attendance_summary'>[number]

/** Share of recorded events the member attended, or null without any. */
export function attendanceRate(s: Pick<Summary, 'present' | 'absent'>): number | null {
  const recorded = s.present + s.absent
  return recorded ? Math.round((s.present / recorded) * 100) : null
}
