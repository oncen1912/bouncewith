import { describe, expect, it } from 'vitest'
import { sidebarItems, tabItems } from './nav'

const labels = (items: { labelKey: string }[]) => items.map((i) => i.labelKey)

describe('navigation', () => {
  it('phones always get five tabs inside a workspace', () => {
    expect(labels(tabItems('niko-dance'))).toEqual([
      'nav.home',
      'nav.events',
      'nav.inbox',
      'nav.assistant',
      'nav.more',
    ])
  })

  it('outside a workspace: workspaces and profile', () => {
    expect(labels(tabItems(null))).toEqual(['nav.workspaces', 'nav.me'])
    expect(labels(sidebarItems(null, null))).toEqual(['nav.workspaces', 'nav.me'])
  })

  it.each([
    ['member', []],
    ['trainer', ['nav.members']],
    ['owner', ['nav.members', 'nav.settings']],
  ] as const)('sidebar for a %s shows the right admin entries', (role, admin) => {
    const items = labels(sidebarItems('niko-dance', role))
    expect(items.slice(4, -1)).toEqual(admin)
    expect(items.at(-1)).toBe('nav.me')
  })
})
