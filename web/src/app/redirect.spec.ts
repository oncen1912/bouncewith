import { describe, expect, it } from 'vitest'
import { safeRedirect } from './redirect'

describe('safeRedirect', () => {
  it('keeps same-origin paths', () => {
    expect(safeRedirect('/w/niko-dance/events?x=1')).toBe('/w/niko-dance/events?x=1')
  })

  it.each([undefined, null, 42, '', 'https://evil.example', '//evil.example', '/\\evil.example', 'w/x'])(
    'rejects %s',
    (value) => {
      expect(safeRedirect(value)).toBe('/w')
    },
  )

  it('does not loop back into auth screens', () => {
    expect(safeRedirect('/login?redirect=/me')).toBe('/w')
    expect(safeRedirect('/auth/callback')).toBe('/w')
  })
})
