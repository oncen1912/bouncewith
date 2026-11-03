<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import WorkspaceAvatar from '@/components/WorkspaceAvatar.vue'
import { useWorkspaceStore } from './store'
import PageHeader from '@/components/PageHeader.vue'

const { t } = useI18n()
const router = useRouter()
const workspaces = useWorkspaceStore()
const loading = ref(true)
const code = ref('')

onMounted(async () => {
  try {
    await workspaces.load(true)
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
})

function joinWithCode() {
  const value = code.value.trim().toUpperCase()
  if (value) void router.push({ name: 'join', params: { code: value } })
}
</script>

<template>
  <PageHeader :title="t('workspaces.title')" :eyebrow="t('workspaces.eyebrow')">
    <RouterLink :to="{ name: 'workspace-new' }" class="btn btn-primary">
      <i class="bi bi-plus-lg me-1" aria-hidden="true"></i>{{ t('workspaces.create') }}
    </RouterLink>
  </PageHeader>

  <LoadingBlock v-if="loading" />

  <template v-else>
    <EmptyState
      v-if="workspaces.memberships.length === 0"
      icon="bi-people"
      :title="t('workspaces.emptyTitle')"
      :text="t('workspaces.emptyText')"
      class="mb-4"
    />

    <ul v-else class="list-unstyled d-grid gap-2 mb-4">
      <li v-for="ws in workspaces.mine" :key="ws.workspace_id">
        <RouterLink
          :to="{ name: 'home', params: { slug: ws.slug } }"
          class="card card-body d-flex flex-row align-items-center gap-3 text-decoration-none"
        >
          <WorkspaceAvatar :workspace="ws" />
          <span class="flex-grow-1 min-w-0">
            <span class="d-block fw-semibold text-body text-truncate">{{ ws.name }}</span>
            <span class="small text-muted">{{ t(`roles.${ws.role}`) }}</span>
          </span>
          <i class="bi bi-chevron-right text-muted" aria-hidden="true"></i>
        </RouterLink>
      </li>
      <li v-for="ws in workspaces.pending" :key="ws.workspace_id">
        <div class="card card-body d-flex flex-row align-items-center gap-3 opacity-75">
          <WorkspaceAvatar :workspace="ws" />
          <span class="flex-grow-1 min-w-0">
            <span class="d-block fw-semibold text-truncate">{{ ws.name }}</span>
            <span class="small text-warning">
              <i class="bi bi-hourglass-split me-1" aria-hidden="true"></i>{{ t('workspaces.pending') }}
            </span>
          </span>
        </div>
      </li>
    </ul>

    <form class="card card-body" @submit.prevent="joinWithCode">
      <label for="join-code" class="form-label fw-semibold">{{ t('workspaces.joinTitle') }}</label>
      <p class="small text-muted">{{ t('workspaces.joinText') }}</p>
      <div class="d-flex gap-2">
        <input
          id="join-code"
          v-model="code"
          class="form-control text-uppercase"
          autocomplete="off"
          autocapitalize="characters"
          spellcheck="false"
          maxlength="16"
          required
        />
        <button type="submit" class="btn btn-outline-light flex-none">{{ t('workspaces.join') }}</button>
      </div>
    </form>
  </template>
</template>
