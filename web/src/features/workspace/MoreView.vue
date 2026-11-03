<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { adminItems } from '@/components/nav'
import { useAuthStore } from '@/features/auth/store'
import { useWorkspaceStore } from './store'
import PageHeader from '@/components/PageHeader.vue'

// Phone "More" tab: everything that doesn't fit in the five tabs.
const { t } = useI18n()
const router = useRouter()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const items = computed(() => {
  const slug = workspaces.current?.slug
  return [
    ...(slug ? adminItems(slug, workspaces.role) : []),
    { to: { name: 'workspaces' }, icon: 'bi-arrow-left-right', labelKey: 'nav.switchWorkspace' },
    { to: { name: 'me' }, icon: 'bi-person-circle', labelKey: 'nav.me' },
  ]
})

async function signOut() {
  try {
    await auth.signOut()
    await router.replace({ name: 'login' })
  } catch {
    toast.error(t('errors.generic'))
  }
}
</script>

<template>
  <PageHeader :title="t('nav.more')" :eyebrow="workspaces.current?.name" />
  <nav :aria-label="t('nav.more')">
    <ul class="list-group mb-4">
      <li v-for="item in items" :key="item.labelKey" class="list-group-item p-0">
        <RouterLink :to="item.to" class="bw-more-link">
          <i :class="['bi', item.icon]" aria-hidden="true"></i>
          <span class="flex-grow-1">{{ t(item.labelKey) }}</span>
          <i class="bi bi-chevron-right text-muted" aria-hidden="true"></i>
        </RouterLink>
      </li>
    </ul>
  </nav>
  <button type="button" class="btn btn-outline-danger w-100" @click="signOut">
    <i class="bi bi-box-arrow-right me-2" aria-hidden="true"></i>{{ t('auth.signOut') }}
  </button>
</template>

<style scoped>
.list-group {
  --bs-list-group-bg: var(--bw-bg-3);
  --bs-list-group-border-color: var(--bw-border);
}

.bw-more-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 52px;
  padding: 0 1rem;
  color: var(--bw-text);
  text-decoration: none;
}

.bw-more-link:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: -2px;
}
</style>
