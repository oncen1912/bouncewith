import type { RouteLocationRaw } from 'vue-router'
import { hasRole, type Role } from '@/features/workspace/types'

export type NavItem = {
  to: RouteLocationRaw
  icon: string
  labelKey: string
  /** Active only on an exact match (home), not for nested routes */
  exact?: boolean
}

const outside: NavItem[] = [
  { to: { name: 'workspaces' }, icon: 'bi-grid', labelKey: 'nav.workspaces' },
  { to: { name: 'me' }, icon: 'bi-person-circle', labelKey: 'nav.me' },
]

function core(slug: string): NavItem[] {
  const params = { slug }
  return [
    { to: { name: 'home', params }, icon: 'bi-house', labelKey: 'nav.home', exact: true },
    { to: { name: 'events', params }, icon: 'bi-calendar-event', labelKey: 'nav.events' },
    { to: { name: 'inbox', params }, icon: 'bi-chat-dots', labelKey: 'nav.inbox' },
    { to: { name: 'assistant', params }, icon: 'bi-stars', labelKey: 'nav.assistant' },
  ]
}

/** Trainer/owner screens, shown in the desktop sidebar and on the phone "More" page. */
export function adminItems(slug: string, role: Role | null): NavItem[] {
  const params = { slug }
  const items: NavItem[] = []
  if (hasRole(role, 'trainer'))
    items.push({ to: { name: 'members', params }, icon: 'bi-people', labelKey: 'nav.members' })
  if (hasRole(role, 'owner'))
    items.push({ to: { name: 'settings', params }, icon: 'bi-gear', labelKey: 'nav.settings' })
  return items
}

/** Desktop sidebar: everything visible at once. */
export function sidebarItems(slug: string | null, role: Role | null): NavItem[] {
  if (!slug) return outside
  return [
    ...core(slug),
    ...adminItems(slug, role),
    { to: { name: 'me' }, icon: 'bi-person-circle', labelKey: 'nav.me' },
  ]
}

/** Phone tab bar: always five tabs, the rest lives under "More". */
export function tabItems(slug: string | null): NavItem[] {
  if (!slug) return outside
  return [
    ...core(slug),
    { to: { name: 'more', params: { slug } }, icon: 'bi-three-dots', labelKey: 'nav.more' },
  ]
}
