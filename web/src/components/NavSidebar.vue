<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { NavItem } from './nav'
import WorkspaceAvatar from './WorkspaceAvatar.vue'

defineProps<{
  items: NavItem[]
  workspace: { name: string; logo_url: string | null; accent_color: string | null } | null
}>()
const { t } = useI18n()
</script>

<template>
  <aside class="bw-sidebar d-none d-md-flex">
    <RouterLink :to="{ name: 'workspaces' }" class="bw-brand">
      <span class="bw-logo" aria-hidden="true"></span>
      BounceWith
    </RouterLink>
    <RouterLink v-if="workspace" :to="{ name: 'workspaces' }" class="bw-ws" :title="t('nav.switchWorkspace')">
      <WorkspaceAvatar :workspace="workspace" size="32" />
      <span class="text-truncate">{{ workspace.name }}</span>
      <i class="bi bi-chevron-expand ms-auto" aria-hidden="true"></i>
      <span class="visually-hidden">{{ t('nav.switchWorkspace') }}</span>
    </RouterLink>
    <nav :aria-label="t('nav.main')">
      <ul class="list-unstyled m-0">
        <li v-for="item in items" :key="item.labelKey">
          <RouterLink
            :to="item.to"
            class="bw-side-link"
            :active-class="item.exact ? '' : 'active'"
            exact-active-class="active"
          >
            <i :class="['bi', item.icon]" aria-hidden="true"></i>
            {{ t(item.labelKey) }}
          </RouterLink>
        </li>
      </ul>
    </nav>
  </aside>
</template>

<style scoped>
.bw-sidebar {
  position: fixed;
  inset: 0 auto 0 0;
  width: var(--bw-sidebar-width);
  flex-direction: column;
  gap: 0.5rem;
  padding: 1.5rem 1rem;
  background: var(--bw-bg-2);
  border-right: 1px solid var(--bw-border);
}

.bw-brand {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  font-weight: 700;
  font-size: 1.25rem;
  color: var(--bw-text);
  text-decoration: none;
  margin-bottom: 0.5rem;
}

.bw-logo {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: radial-gradient(circle, var(--bw-pink) 0 35%, var(--bw-accent) 36%);
}

.bw-ws {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  min-height: 48px;
  padding: 0.25rem 0.5rem;
  margin-bottom: 0.5rem;
  border: 1px solid var(--bw-border);
  border-radius: var(--bw-radius);
  color: var(--bw-text);
  text-decoration: none;
  font-weight: 600;
}

.bw-ws:hover {
  background: var(--bw-bg-3);
}

.bw-ws:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}

.bw-side-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 44px;
  padding: 0 0.875rem;
  border-radius: 999px;
  color: var(--bw-text-muted);
  text-decoration: none;
}

.bw-side-link:hover {
  color: var(--bw-text);
}

.bw-side-link.active {
  color: var(--bw-accent);
  background: color-mix(in srgb, var(--bw-accent) 12%, transparent);
}

.bw-side-link:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}
</style>
