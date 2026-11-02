<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from '@/features/workspace/store'
import NavSidebar from './NavSidebar.vue'
import NavTabBar from './NavTabBar.vue'
import { navItems } from './nav'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const slug = computed(() => (typeof route.params.slug === 'string' ? route.params.slug : null))
const items = computed(() => navItems(slug.value))
const accent = computed(() => (slug.value ? workspaces.current?.accent_color : null) ?? undefined)

watch(slug, (s) => void workspaces.selectBySlug(s), { immediate: true })

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
    <NavSidebar :items="items" :title="slug ? workspaces.current?.name : undefined" />
    <main id="main" class="bw-main" tabindex="-1">
      <RouterView />
    </main>
    <NavTabBar :items="items" />
  </div>
</template>

<style scoped>
.bw-shell {
  min-height: 100dvh;
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
