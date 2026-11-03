import { describe, expect, it } from 'vitest'
import { durationMinutes, emptyValues, toEventFields, toSeriesInsert, valuesFromEvent } from './form'
import type { EventRow } from './types'

describe('event form', () => {
  it('computes durations, also past midnight', () => {
    expect(durationMinutes('18:30', '20:00')).toBe(90)
    expect(durationMinutes('22:00', '01:00')).toBe(180)
  })

  it('stores a one-off event as instants in the workspace timezone', () => {
    const v = {
      ...emptyValues('2027-03-30'),
      title: ' Hip Hop ',
      startTime: '18:30',
      endTime: '20:00',
      deadlineMinutes: 120,
    }
    const row = toEventFields(v, 'Europe/Zurich')
    expect(row.starts_at).toBe('2027-03-30T16:30:00.000Z')
    expect(row.ends_at).toBe('2027-03-30T18:00:00.000Z')
    expect(row.rsvp_deadline).toBe('2027-03-30T14:30:00.000Z')
    expect(row.title).toBe('Hip Hop')
  })

  it('builds a weekly series row', () => {
    const v = {
      ...emptyValues('2026-11-03'),
      title: 'Breaking',
      repeats: true,
      weekdays: [4, 2],
      intervalWeeks: 2,
    }
    expect(toSeriesInsert(v, 'ws', 'user')).toMatchObject({
      workspace_id: 'ws',
      starts_on: '2026-11-03',
      weekdays: [2, 4],
      interval_weeks: 2,
      start_time: '18:00',
      duration_min: 90,
      until: null,
      created_by: 'user',
    })
  })

  it('loads an event back into the form', () => {
    const ev = {
      title: 'Hip Hop',
      description: '<p>Bring water</p>',
      starts_at: '2027-03-30T16:30:00Z',
      ends_at: '2027-03-30T18:00:00Z',
      rsvp_deadline: '2027-03-30T15:30:00Z',
      category: 'class',
      location: null,
      location_url: null,
      capacity: 20,
      group_ids: [],
      visibility: 'members',
    } as unknown as EventRow
    expect(valuesFromEvent(ev, null, 'Europe/Zurich')).toMatchObject({
      date: '2027-03-30',
      startTime: '18:30',
      endTime: '20:00',
      deadlineMinutes: 60,
      descriptionText: 'Bring water',
      weekdays: [2],
    })
  })
})
