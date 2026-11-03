<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import BaseDialog from '@/components/BaseDialog.vue'
import * as workspaceApi from '@/features/workspace/api'
import { useWorkspaceStore } from '@/features/workspace/store'
import type { MyMembership } from '@/features/workspace/types'

const { t } = useI18n()
const workspaces = useWorkspaceStore()
const leaving = ref<MyMembership | null>(null)
const busy = ref(false)

onMounted(() => void workspaces.load().catch(() => undefined))

async function leave() {
  if (!leaving.value) return
  busy.value = true
  try {
    await workspaceApi.leaveWorkspace(leaving.value.workspace_id)
    toast.success(t('me.left', { name: leaving.value.name }))
    leaving.value = null
    await workspaces.load(true)
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="card card-body mb-3" aria-labelledby="me-ws">
    <h2 id="me-ws" class="h5">{{ t('me.workspaces') }}</h2>
    <p v-if="workspaces.loaded && workspaces.memberships.length === 0" class="text-muted mb-0">
      {{ t('workspaces.emptyTitle') }}
    </p>
    <ul v-else class="list-unstyled m-0">
      <li
        v-for="ws in workspaces.memberships"
        :key="ws.workspace_id"
        class="d-flex align-items-center gap-2 py-1"
      >
        <RouterLink
          v-if="ws.status === 'active'"
          :to="{ name: 'home', params: { slug: ws.slug } }"
          class="flex-grow-1 text-truncate py-2"
          >{{ ws.name }}</RouterLink
        >
        <span v-else class="flex-grow-1 text-truncate py-2">{{ ws.name }}</span>
        <span class="small text-muted">
          {{ ws.status === 'pending' ? t('workspaces.pending') : t(`roles.${ws.role}`) }}
        </span>
        <button
          type="button"
          class="btn btn-link text-danger btn-sm"
          :disabled="ws.is_last_owner"
          :title="ws.is_last_owner ? t('errors.codes.last_owner') : undefined"
          @click="leaving = ws"
        >
          {{ ws.status === 'pending' ? t('me.withdraw') : t('me.leave') }}
        </button>
      </li>
    </ul>

    <BaseDialog
      :open="!!leaving"
      :title="t('me.leaveTitle', { name: leaving?.name ?? '' })"
      @update:open="(v) => !v && (leaving = null)"
    >
      <p class="mb-0">{{ t('me.leaveText') }}</p>
      <template #footer>
        <button type="button" class="btn btn-outline-secondary" @click="leaving = null">
          {{ t('common.cancel') }}
        </button>
        <button type="button" class="btn btn-danger" :disabled="busy" @click="leave">
          {{ t('me.leave') }}
        </button>
      </template>
    </BaseDialog>
  </section>
</template>
