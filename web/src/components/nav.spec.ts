import { describe, expect, it } from 'vitest'
import { navItems } from './nav'

describe('navItems', () => {
  it('shows the five member tabs inside a workspace', () => {
    expect(navItems('niko-dance').map((i) => i.labelKey)).toEqual([
      'nav.home',
      'nav.events',
      'nav.inbox',
      'nav.assistant',
      'nav.more',
    ])
  })

  it('shows workspaces and profile outside a workspace', () => {
    expect(navItems(null).map((i) => i.labelKey)).toEqual(['nav.workspaces', 'nav.me'])
  })
})
