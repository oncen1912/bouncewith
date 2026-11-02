import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/features/auth/store'
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
      { path: 'me', name: 'me', component: () => import('@/features/auth/MeView.vue') },
      {
        path: 'w/:slug',
        children: [
          { path: '', name: 'home', component: () => import('@/features/workspace/HomeView.vue') },
          { path: 'events', name: 'events', component: Placeholder, meta: { titleKey: 'nav.events' } },
          { path: 'inbox', name: 'inbox', component: Placeholder, meta: { titleKey: 'nav.inbox' } },
          {
            path: 'assistant',
            name: 'assistant',
            component: Placeholder,
            meta: { titleKey: 'nav.assistant' },
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
})
