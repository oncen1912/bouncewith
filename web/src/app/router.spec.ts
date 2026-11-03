import { describe, expect, it, vi } from 'vitest'
import { adminItems, sidebarItems, tabItems } from '@/components/nav'

vi.mock('@/app/supabase', () => ({ supabase: {} }))
const { router } = await import('./router')

describe('router', () => {
  const roles = ['member', 'trainer', 'owner'] as const
  const links = [
    ...tabItems(null),
    ...tabItems('niko-dance'),
    ...roles.flatMap((r) => [...sidebarItems('niko-dance', r), ...adminItems('niko-dance', r)]),
  ]

  it.each(links.map((l) => [l.labelKey, l]))('navigation link %s resolves to a real route', (_key, link) => {
    const resolved = router.resolve(link.to)
    expect(resolved.matched.length).toBeGreaterThan(0)
    expect(resolved.name).not.toBe('not-found')
  })

  it.each([
    ['/w/niko-dance/members', 'trainer'],
    ['/w/niko-dance/settings', 'owner'],
  ])('%s requires at least %s', (path, role) => {
    expect(router.resolve(path).meta.minRole).toBe(role)
  })

  it('invite links resolve to the join screen', () => {
    expect(router.resolve('/join/NIKO2026').name).toBe('join')
    expect(router.resolve('/w/new').name).toBe('workspace-new')
  })
})
