import type { RouteLocationRaw } from 'vue-router'

export type NavItem = {
  to: RouteLocationRaw
  icon: string
  labelKey: string
  /** Active only on an exact match (home), not for nested routes */
  exact?: boolean
}

export function navItems(slug: string | null): NavItem[] {
  if (!slug) {
    return [
      { to: { name: 'workspaces' }, icon: 'bi-grid', labelKey: 'nav.workspaces' },
      { to: { name: 'me' }, icon: 'bi-person-circle', labelKey: 'nav.me' },
    ]
  }
  const params = { slug }
  return [
    { to: { name: 'home', params }, icon: 'bi-house', labelKey: 'nav.home', exact: true },
    { to: { name: 'events', params }, icon: 'bi-calendar-event', labelKey: 'nav.events' },
    { to: { name: 'inbox', params }, icon: 'bi-chat-dots', labelKey: 'nav.inbox' },
    { to: { name: 'assistant', params }, icon: 'bi-stars', labelKey: 'nav.assistant' },
    { to: { name: 'me' }, icon: 'bi-three-dots', labelKey: 'nav.more' },
  ]
}
