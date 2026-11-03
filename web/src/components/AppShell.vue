<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from '@/features/workspace/store'
import NavSidebar from './NavSidebar.vue'
import NavTabBar from './NavTabBar.vue'
import WorkspaceAvatar from './WorkspaceAvatar.vue'
import { sidebarItems, tabItems } from './nav'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const slug = computed(() => (typeof route.params.slug === 'string' ? route.params.slug : null))
const current = computed(() => (slug.value ? workspaces.current : null))
const accent = computed(() => current.value?.accent_color ?? undefined)

watch(slug, (s) => void workspaces.selectBySlug(s).catch(() => undefined), { immediate: true })

// session ended (sign-out in another tab, expired refresh token) → back to login
watch(
  () => auth.isAuthenticated,
  (signedIn) => {
    if (!signedIn) void router.replace({ name: 'login', query: { redirect: route.fullPath } })
  },
)
</script>

<template>
  <div class="bw-shell" :style="accent ? { '--bw-accent': accent } : undefined">
    <a class="visually-hidden-focusable" href="#main">{{ t('nav.skipToContent') }}</a>
    <NavSidebar :items="sidebarItems(slug, workspaces.role)" :workspace="current" />

    <header v-if="current" class="bw-topbar d-md-none">
      <RouterLink :to="{ name: 'workspaces' }" class="bw-topbar-link" :aria-label="t('nav.switchWorkspace')">
        <WorkspaceAvatar :workspace="current" size="28" />
        <span class="text-truncate">{{ current.name }}</span>
        <i class="bi bi-chevron-expand ms-auto" aria-hidden="true"></i>
      </RouterLink>
    </header>

    <main id="main" class="bw-main" tabindex="-1">
      <RouterView />
    </main>
    <NavTabBar :items="tabItems(slug)" />
  </div>
</template>

<style scoped>
.bw-shell {
  min-height: 100dvh;
}

.bw-topbar {
  position: sticky;
  top: 0;
  z-index: 1020;
  background: rgb(12 12 12 / 95%);
  backdrop-filter: blur(20px);
  padding-top: env(safe-area-inset-top);
}

/* gradient underline: teal → pink → yellow, as on bouncewith.me */
.bw-topbar::after {
  content: '';
  display: block;
  height: 2px;
  background: var(--bw-gradient);
}

.bw-topbar-link {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  min-height: 48px;
  padding: 0 1rem;
  color: var(--bw-text);
  text-decoration: none;
  font-weight: 600;
}

.bw-main {
  padding: 1rem 1rem calc(var(--bw-tabbar-height) + 1rem + env(safe-area-inset-bottom));
  max-width: 960px;
  margin: 0 auto;
  outline: none;
}

@media (min-width: 768px) {
  .bw-main {
    margin-left: var(--bw-sidebar-width);
    padding: 2rem;
    max-width: calc(960px + var(--bw-sidebar-width));
  }
}
</style>
