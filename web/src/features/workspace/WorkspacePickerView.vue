<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import EmptyState from '@/components/EmptyState.vue'
import { useWorkspaceStore } from './store'

const { t } = useI18n()
const workspaces = useWorkspaceStore()
const loading = ref(true)

onMounted(async () => {
  try {
    await workspaces.load(true)
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <h1 class="h3 mb-4">{{ t('workspaces.title') }}</h1>

  <div v-if="loading" class="text-center py-5" role="status">
    <span class="spinner-border" aria-hidden="true"></span>
    <span class="visually-hidden">{{ t('common.loading') }}</span>
  </div>

  <EmptyState
    v-else-if="workspaces.mine.length === 0"
    icon="bi-people"
    :title="t('workspaces.emptyTitle')"
    :text="t('workspaces.emptyText')"
  />

  <ul v-else class="list-unstyled d-grid gap-2 m-0">
    <li v-for="ws in workspaces.mine" :key="ws.id">
      <RouterLink
        :to="{ name: 'home', params: { slug: ws.slug } }"
        class="card card-body d-flex flex-row align-items-center gap-3 text-decoration-none"
      >
        <span
          class="bw-ws-dot"
          :style="{ background: ws.accent_color ?? 'var(--bw-accent)' }"
          aria-hidden="true"
        ></span>
        <span class="flex-grow-1 min-w-0">
          <span class="d-block fw-semibold text-body text-truncate">{{ ws.name }}</span>
          <span class="small text-muted">{{ t(`roles.${ws.role}`) }}</span>
        </span>
        <i class="bi bi-chevron-right text-muted" aria-hidden="true"></i>
      </RouterLink>
    </li>
  </ul>
</template>

<style scoped>
.bw-ws-dot {
  width: 40px;
  height: 40px;
  flex: none;
  border-radius: 12px;
}
</style>
