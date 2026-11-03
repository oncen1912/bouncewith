<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import { useAttendanceStore } from '@/features/attendance/store'
import * as api from '../api'
import type { EventRow } from '../types'
import EventCard from './EventCard.vue'

// Home: the next three scheduled events (RSVP buttons arrive with M3).
const props = defineProps<{ workspaceId: string; slug: string; isTrainer: boolean }>()
const { t } = useI18n()
const events = ref<EventRow[] | null>(null)
const attendance = useAttendanceStore()

watch(
  () => props.workspaceId,
  async (id) => {
    events.value = null
    const now = new Date()
    const later = new Date(now.getTime() + 120 * 86_400_000)
    const list = await api.listEvents(id, now.toISOString(), later.toISOString(), 'asc', 20).catch(() => [])
    const next = list.filter((e) => e.status === 'scheduled').slice(0, 3)
    await attendance.load(next.map((e) => e.id)).catch(() => undefined)
    events.value = next
  },
  { immediate: true },
)
</script>

<template>
  <LoadingBlock v-if="!events" />
  <EmptyState
    v-else-if="events.length === 0"
    icon="bi-calendar-event"
    :title="t('home.noEventsTitle')"
    :text="isTrainer ? t('events.emptyTrainer') : t('home.noEventsText')"
  >
    <RouterLink v-if="isTrainer" :to="{ name: 'event-new', params: { slug } }" class="btn btn-primary mt-3">{{
      t('events.new')
    }}</RouterLink>
  </EmptyState>
  <div v-else class="d-grid gap-3">
    <EventCard v-for="e in events" :key="e.id" :event="e" :slug="slug" />
    <RouterLink
      :to="{ name: 'events', params: { slug } }"
      class="btn btn-outline-accent align-self-start justify-self-start"
    >
      {{ t('home.allEvents') }}<i class="bi bi-arrow-right ms-1" aria-hidden="true"></i>
    </RouterLink>
  </div>
</template>
