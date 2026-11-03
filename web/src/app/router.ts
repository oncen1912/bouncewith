import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from '@/features/workspace/store'
import { hasRole, type Role } from '@/features/workspace/types'
import { safeRedirect } from './redirect'
import AppShell from '@/components/AppShell.vue'

declare module 'vue-router' {
  interface RouteMeta {
    /** Reachable without a session */
    public?: boolean
    /** Signed-in users are sent on to their workspaces */
    guestOnly?: boolean
    /** i18n key for placeholder screens and the document title */
    titleKey?: string
    /** Minimum workspace role (UX only: RLS and the RPCs enforce the real rules) */
    minRole?: Role
  }
}

const Placeholder = () => import('@/components/PlaceholderView.vue')

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/features/auth/LoginView.vue'),
    meta: { public: true, guestOnly: true },
  },
  {
    path: '/auth/callback',
    name: 'auth-callback',
    component: () => import('@/features/auth/AuthCallbackView.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: AppShell,
    children: [
      { path: '', redirect: '/w' },
      {
        path: 'w',
        name: 'workspaces',
        component: () => import('@/features/workspace/WorkspacePickerView.vue'),
      },
      {
        path: 'w/new',
        name: 'workspace-new',
        component: () => import('@/features/workspace/CreateWorkspaceView.vue'),
      },
      { path: 'join/:code', name: 'join', component: () => import('@/features/workspace/JoinView.vue') },
      {
        path: 'checkin/:token',
        name: 'checkin',
        component: () => import('@/features/attendance/CheckinLandingView.vue'),
      },
      { path: 'me', name: 'me', component: () => import('@/features/auth/MeView.vue') },
      {
        path: 'w/:slug',
        children: [
          { path: '', name: 'home', component: () => import('@/features/workspace/HomeView.vue') },
          { path: 'events', name: 'events', component: () => import('@/features/events/EventsView.vue') },
          {
            path: 'events/new',
            name: 'event-new',
            component: () => import('@/features/events/EventFormView.vue'),
            meta: { minRole: 'trainer' },
          },
          {
            path: 'events/:id',
            name: 'event',
            component: () => import('@/features/events/EventDetailView.vue'),
          },
          {
            path: 'events/:id/checkin',
            name: 'event-checkin',
            component: () => import('@/features/attendance/CheckinView.vue'),
            meta: { minRole: 'trainer' },
          },
          {
            path: 'events/:id/edit',
            name: 'event-edit',
            component: () => import('@/features/events/EventFormView.vue'),
            meta: { minRole: 'trainer' },
          },
          { path: 'inbox', name: 'inbox', component: Placeholder, meta: { titleKey: 'nav.inbox' } },
          {
            path: 'assistant',
            name: 'assistant',
            component: Placeholder,
            meta: { titleKey: 'nav.assistant' },
          },
          { path: 'more', name: 'more', component: () => import('@/features/workspace/MoreView.vue') },
          {
            path: 'members',
            name: 'members',
            component: () => import('@/features/members/MembersView.vue'),
            meta: { minRole: 'trainer' },
          },
          {
            path: 'settings',
            name: 'settings',
            component: () => import('@/features/workspace/settings/SettingsView.vue'),
            meta: { minRole: 'owner' },
          },
        ],
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/components/NotFoundView.vue'),
    meta: { public: true },
  },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: (_to, _from, saved) => saved ?? { top: 0 },
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.init()

  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.meta.guestOnly && auth.isAuthenticated) {
    return safeRedirect(to.query.redirect)
  }
  const slug = to.params.slug
  if (to.meta.minRole && typeof slug === 'string') {
    const workspaces = useWorkspaceStore()
    await workspaces.selectBySlug(slug).catch(() => undefined)
    if (!hasRole(workspaces.role, to.meta.minRole)) return { name: 'home', params: { slug } }
  }
})
