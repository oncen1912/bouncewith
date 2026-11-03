import { supabase } from '@/app/supabase'
import type { Answer, Attendee, Candidate, Counts, HistoryRow, MyAnswer, Summary } from './types'

export async function rsvp(eventId: string, answer: Answer, reason?: string) {
  const { error } = await supabase.rpc('rsvp', { p_event: eventId, p_answer: answer, p_reason: reason })
  if (error) throw error
}

export async function myAnswers(userId: string, eventIds: string[]): Promise<Map<string, MyAnswer>> {
  const { data, error } = await supabase
    .from('rsvps')
    .select('event_id, answer, reason')
    .eq('user_id', userId)
    .in('event_id', eventIds)
  if (error) throw error
  return new Map(data.map((r) => [r.event_id, { answer: r.answer, reason: r.reason }]))
}

export async function countsMany(eventIds: string[]): Promise<Counts[]> {
  const { data, error } = await supabase.rpc('event_counts_many', { p_events: eventIds })
  if (error) throw error
  return data
}

export async function attendees(eventId: string): Promise<Attendee[]> {
  const { data, error } = await supabase.rpc('event_attendees', { p_event: eventId })
  if (error) throw error
  return data as Attendee[]
}

export async function candidates(eventId: string): Promise<Candidate[]> {
  const { data, error } = await supabase.rpc('checkin_candidates', { p_event: eventId })
  if (error) throw error
  return data
}

export async function startCheckin(eventId: string): Promise<number> {
  const { data, error } = await supabase.rpc('start_checkin', { p_event: eventId })
  if (error) throw error
  return data
}

export async function mark(eventId: string, userId: string, present: boolean) {
  const { error } = await supabase.rpc('mark_attendance', {
    p_event: eventId,
    p_user: userId,
    p_present: present,
  })
  if (error) throw error
}

export async function createToken(eventId: string, minutes = 30): Promise<string> {
  const { data, error } = await supabase.rpc('create_checkin_token', { p_event: eventId, p_minutes: minutes })
  if (error) throw error
  return data
}

export async function qrCheckin(token: string): Promise<string> {
  const { data, error } = await supabase.rpc('qr_checkin', { p_token: token })
  if (error) throw error
  return data
}

export async function resetAttendance(eventId: string, title: string): Promise<number> {
  const { data, error } = await supabase.rpc('reset_attendance', { p_event: eventId, p_confirm_title: title })
  if (error) throw error
  return data
}

export async function memberHistory(workspaceId: string, userId: string, days = 90): Promise<HistoryRow[]> {
  const { data, error } = await supabase.rpc('member_attendance', {
    p_ws: workspaceId,
    p_user: userId,
    p_days: days,
  })
  if (error) throw error
  return data as HistoryRow[]
}

export async function summary(workspaceId: string, days = 90): Promise<Summary[]> {
  const { data, error } = await supabase.rpc('attendance_summary', { p_ws: workspaceId, p_days: days })
  if (error) throw error
  return data
}
