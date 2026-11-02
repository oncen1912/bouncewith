<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { NavItem } from './nav'

defineProps<{ items: NavItem[]; title?: string }>()
const { t } = useI18n()
</script>

<template>
  <aside class="bw-sidebar d-none d-md-flex">
    <RouterLink :to="{ name: 'workspaces' }" class="bw-brand">
      <span class="bw-logo" aria-hidden="true"></span>
      BounceWith
    </RouterLink>
    <p v-if="title" class="bw-ws-name text-truncate" :title="title">{{ title }}</p>
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

.bw-ws-name {
  color: var(--bw-text-muted);
  font-size: 0.875rem;
  margin: 0 0 0.5rem;
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
