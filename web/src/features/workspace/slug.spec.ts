import { describe, expect, it } from 'vitest'
import { SLUG_PATTERN, slugify } from './slug'

describe('slugify', () => {
  it.each([
    ['Niko Dance School', 'niko-dance-school'],
    ['Plesna šola Čarovnija', 'plesna-sola-carovnija'],
    ['Großer Saal Zürich!', 'grosser-saal-zurich'],
    ['  --Yoga   & Co-- ', 'yoga-co'],
  ])('%s → %s', (name, slug) => {
    expect(slugify(name)).toBe(slug)
    expect(slug).toMatch(new RegExp(SLUG_PATTERN))
  })

  it('caps the length at 40 without a trailing dash', () => {
    const slug = slugify('a'.repeat(39) + ' b')
    expect(slug.length).toBeLessThanOrEqual(40)
    expect(slug.endsWith('-')).toBe(false)
  })
})
