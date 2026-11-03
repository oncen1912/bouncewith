<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { NavItem } from './nav'

defineProps<{ items: NavItem[] }>()
const { t } = useI18n()
</script>

<template>
  <nav class="bw-tabbar d-md-none" :aria-label="t('nav.main')">
    <RouterLink
      v-for="item in items"
      :key="item.labelKey"
      :to="item.to"
      class="bw-tab"
      :active-class="item.exact ? '' : 'active'"
      exact-active-class="active"
    >
      <i :class="['bi', item.icon]" aria-hidden="true"></i>
      <span>{{ t(item.labelKey) }}</span>
    </RouterLink>
  </nav>
</template>

<style scoped>
.bw-tabbar {
  position: fixed;
  inset: auto 0 0 0;
  z-index: 1030;
  display: flex;
  height: calc(var(--bw-tabbar-height) + env(safe-area-inset-bottom));
  padding-bottom: env(safe-area-inset-bottom);
  background: rgb(12 12 12 / 95%);
  backdrop-filter: blur(20px);
  border-top: 1px solid var(--bw-border);
}

.bw-tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  min-width: 44px;
  font-size: 0.75rem;
  color: var(--bw-text-muted);
  text-decoration: none;
}

.bw-tab .bi {
  font-size: 1.35rem;
}

.bw-tab.active {
  color: var(--bw-accent);
  font-weight: 600;
}

.bw-tab:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: -4px;
  border-radius: var(--bw-radius);
}
</style>
