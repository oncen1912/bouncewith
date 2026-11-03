<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import LoadingBlock from '@/components/LoadingBlock.vue'
import * as api from '../api'
import { useWorkspaceStore } from '../store'
import type { WorkspacePatch, WorkspaceSettings } from '../types'
import BrandingSettings from './BrandingSettings.vue'
import GeneralSettings from './GeneralSettings.vue'
import InviteSettings from './InviteSettings.vue'
import PageHeader from '@/components/PageHeader.vue'

const { t } = useI18n()
const workspaces = useWorkspaceStore()
const settings = ref<WorkspaceSettings | null>(null)

onMounted(async () => {
  const id = workspaces.current?.workspace_id
  if (!id) return
  try {
    settings.value = await api.getSettings(id)
  } catch {
    toast.error(t('errors.generic'))
  }
})

/** Saves a patch and keeps the local copy and the shell (name, colour, logo) in sync. */
async function save(patch: WorkspacePatch): Promise<boolean> {
  if (!settings.value) return false
  try {
    await api.updateSettings(settings.value.id, patch)
    Object.assign(settings.value, patch)
    workspaces.patchCurrent(patch)
    toast.success(t('me.saved'))
    return true
  } catch (e) {
    toast.error(t(errorKey(e)))
    return false
  }
}
</script>

<template>
  <PageHeader :title="t('nav.settings')" :eyebrow="workspaces.current?.name" />
  <LoadingBlock v-if="!settings" />
  <div v-else class="d-grid gap-3" style="max-width: 640px">
    <GeneralSettings :settings="settings" :save="save" />
    <BrandingSettings :settings="settings" :save="save" />
    <InviteSettings v-model:settings="settings" />
  </div>
</template>
