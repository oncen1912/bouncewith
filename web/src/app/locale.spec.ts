import { describe, expect, it } from 'vitest'
import { detectLocale } from './locale'

describe('detectLocale', () => {
  it('prefers a stored supported choice', () => {
    expect(detectLocale('sl', ['de-CH'])).toBe('sl')
  })

  it('falls back to the first supported browser language', () => {
    expect(detectLocale(null, ['fr-CH', 'de-CH', 'en'])).toBe('de')
    expect(detectLocale('xx', ['SL-si'])).toBe('sl')
  })

  it('defaults to English', () => {
    expect(detectLocale(null, ['fr', 'it'])).toBe('en')
  })
})
