<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import * as eventsApi from '@/features/events/api'
import type { EventRow } from '@/features/events/types'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'

// Target of the check-in QR code: /checkin/:token (signed in; the router sends guests to /login first).
const { t } = useI18n()
const route = useRoute()
const workspaces = useWorkspaceStore()
const event = ref<EventRow | null>(null)
const errorText = ref<string | null>(null)
const slug = ref<string | null>(null)

onMounted(async () => {
  try {
    const id = await api.qrCheckin(String(route.params.token))
    event.value = await eventsApi.getEvent(id)
    await workspaces.load(true)
    slug.value = workspaces.mine.find((w) => w.workspace_id === event.value?.workspace_id)?.slug ?? null
  } catch (e) {
    errorText.value = t(errorKey(e))
  }
})
</script>

<template>
  <div class="mx-auto text-center py-4" style="max-width: 420px">
    <EmptyState v-if="errorText" icon="bi-qr-code" :title="t('attendance.landingFailed')" :text="errorText">
      <RouterLink :to="{ name: 'workspaces' }" class="btn btn-primary mt-3">{{
        t('nav.workspaces')
      }}</RouterLink>
    </EmptyState>
    <LoadingBlock v-else-if="!event" />
    <div v-else role="status">
      <div class="bw-done" aria-hidden="true"><i class="bi bi-check-lg"></i></div>
      <div class="section-eyebrow mt-4">{{ t('attendance.landingEyebrow') }}</div>
      <h1 class="section-title">{{ event.title }}</h1>
      <p class="text-muted mt-2">{{ t('attendance.landingText') }}</p>
      <RouterLink
        v-if="slug"
        :to="{ name: 'event', params: { slug, id: event.id } }"
        class="btn btn-outline-accent mt-2"
      >
        {{ t('attendance.landingOpen') }}
      </RouterLink>
    </div>
  </div>
</template>

<style scoped>
.bw-done {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 96px;
  height: 96px;
  border-radius: 50%;
  background: var(--bw-teal);
  color: #000;
  font-size: 3.5rem;
  box-shadow: 0 0 60px rgb(27 189 191 / 45%);
}
</style>
