import { supabase } from '@/app/supabase'
import { EVENT_COLUMNS, type EventRow, type Series } from './types'
import type { TablesInsert, TablesUpdate } from '@bouncewith/shared/database.types'

export async function listEvents(
  workspaceId: string,
  from: string,
  to: string,
  order: 'asc' | 'desc' = 'asc',
  limit = 500,
): Promise<EventRow[]> {
  const { data, error } = await supabase
    .from('events')
    .select(EVENT_COLUMNS)
    .eq('workspace_id', workspaceId)
    .gte('ends_at', from)
    .lt('starts_at', to)
    .order('starts_at', { ascending: order === 'asc' })
    .limit(limit)
  if (error) throw error
  return data as unknown as EventRow[]
}

export async function getEvent(id: string): Promise<EventRow | null> {
  const { data, error } = await supabase.from('events').select(EVENT_COLUMNS).eq('id', id).maybeSingle()
  if (error) throw error
  return data as unknown as EventRow | null
}

export async function getSeries(id: string): Promise<Series | null> {
  const { data, error } = await supabase.from('event_series').select('*').eq('id', id).maybeSingle()
  if (error) throw error
  return data
}

export async function createEvent(row: TablesInsert<'events'>): Promise<string> {
  const { data, error } = await supabase.from('events').insert(row).select('id').single()
  if (error) throw error
  return data.id
}

/** Creates the series and materialises its first 12 weeks. Returns the series id and the number created. */
export async function createSeries(
  row: TablesInsert<'event_series'>,
): Promise<{ id: string; created: number }> {
  const { data, error } = await supabase.from('event_series').insert(row).select('id').single()
  if (error) throw error
  const { data: created, error: expandError } = await supabase.rpc('expand_series', { p_series: data.id })
  if (expandError) throw expandError
  return { id: data.id, created }
}

export async function firstOccurrence(seriesId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from('events')
    .select('id')
    .eq('series_id', seriesId)
    .order('starts_at')
    .limit(1)
    .maybeSingle()
  if (error) throw error
  return data?.id ?? null
}

export async function updateEvent(id: string, patch: TablesUpdate<'events'>) {
  const { error } = await supabase.from('events').update(patch).eq('id', id)
  if (error) throw error
}

export type SeriesUpdateResult = { updated: number; cancelled: number; kept: number; created: number }

export async function updateSeries(
  eventId: string,
  changes: Record<string, unknown>,
): Promise<SeriesUpdateResult> {
  const { data, error } = await supabase.rpc('update_series', {
    p_event: eventId,
    p_changes: changes as never,
  })
  if (error) throw error
  return data as unknown as SeriesUpdateResult
}

export async function cancelEvent(eventId: string, scope: 'this' | 'future', message: string | null) {
  const { data, error } = await supabase.rpc('cancel_event', {
    p_event: eventId,
    p_scope: scope,
    p_notify: !!message,
    p_message: message ?? undefined,
  })
  if (error) throw error
  return data
}
