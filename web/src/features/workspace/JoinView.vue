<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import WorkspaceAvatar from '@/components/WorkspaceAvatar.vue'
import * as api from './api'
import { useWorkspaceStore } from './store'
import type { MembershipStatus, WorkspacePreview } from './types'

// Target of invite links and the invite QR code: /join/:code
const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const workspaces = useWorkspaceStore()

const code = computed(() => String(route.params.code ?? ''))
const preview = ref<WorkspacePreview | null>(null)
const loading = ref(true)
const busy = ref(false)
const status = ref<MembershipStatus | null>(null)

onMounted(async () => {
  try {
    preview.value = await api.previewByCode(code.value)
    status.value = preview.value?.my_status ?? null
    if (status.value === 'active') await openWorkspace()
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
})

async function openWorkspace() {
  await workspaces.load(true)
  if (preview.value) await router.replace({ name: 'home', params: { slug: preview.value.slug } })
}

async function join() {
  busy.value = true
  try {
    status.value = await api.joinByCode(code.value)
    if (status.value === 'active') {
      toast.success(t('join.welcome', { name: preview.value?.name ?? '' }))
      await openWorkspace()
    } else {
      await workspaces.load(true)
    }
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="mx-auto" style="max-width: 480px">
    <LoadingBlock v-if="loading" />

    <EmptyState
      v-else-if="!preview"
      icon="bi-question-circle"
      :title="t('join.invalidTitle')"
      :text="t('join.invalidText')"
    >
      <RouterLink :to="{ name: 'workspaces' }" class="btn btn-primary mt-3">{{
        t('nav.workspaces')
      }}</RouterLink>
    </EmptyState>

    <div v-else class="card card-body text-center p-4">
      <div class="d-flex justify-content-center mb-3">
        <WorkspaceAvatar :workspace="preview" size="72" />
      </div>
      <h1 class="section-title fs-1">{{ preview.name }}</h1>
      <p class="text-muted">{{ t(`workspaceTypes.${preview.type}`) }}</p>

      <div v-if="status === 'pending'" role="status">
        <i class="bi bi-hourglass-split fs-2 text-warning" aria-hidden="true"></i>
        <p class="mt-2 mb-3">{{ t('join.pending', { name: preview.name }) }}</p>
        <RouterLink :to="{ name: 'workspaces' }" class="btn btn-outline-light">{{
          t('nav.workspaces')
        }}</RouterLink>
      </div>

      <p v-else-if="status === 'blocked'" class="text-danger mb-0" role="alert">
        {{ t('errors.codes.blocked') }}
      </p>

      <template v-else>
        <p v-if="preview.require_approval" class="small text-muted">{{ t('join.needsApproval') }}</p>
        <button type="button" class="btn btn-primary w-100" :disabled="busy" @click="join">
          {{ t('join.submit', { name: preview.name }) }}
        </button>
      </template>
    </div>
  </div>
</template>
