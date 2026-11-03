import { describe, expect, it } from 'vitest'
import { relativeDay } from './format'
import { categoryTone } from './types'

describe('relativeDay', () => {
  const now = new Date('2026-11-03T22:30:00Z') // 23:30 in Zurich

  it('counts calendar days in the workspace timezone', () => {
    expect(relativeDay('2026-11-03T22:45:00Z', 'en', 'Europe/Zurich', now)).toBe('Today')
    expect(relativeDay('2026-11-03T23:30:00Z', 'en', 'Europe/Zurich', now)).toBe('Tomorrow')
    expect(relativeDay('2026-11-06T17:00:00Z', 'en', 'Europe/Zurich', now)).toBe('In 3 days')
  })

  it('is localised', () => {
    expect(relativeDay('2026-11-04T17:00:00Z', 'de', 'Europe/Zurich', now)).toBe('Morgen')
    expect(relativeDay('2026-11-04T17:00:00Z', 'sl', 'Europe/Zurich', now)).toBe('Jutri')
  })
})

describe('categoryTone', () => {
  it.each([
    ['class', 'teal'],
    [null, 'teal'],
    ['Workshop', 'yellow'],
    ['Battle', 'pink'],
    ['performance', 'pink'],
  ] as const)('%s → %s', (category, tone) => {
    expect(categoryTone(category)).toBe(tone)
  })
})
