<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { weekdayNames } from '@bouncewith/shared'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import { listGroups } from '@/features/members/api'
import type { Group } from '@/features/members/types'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import AttendeeLists from '@/features/attendance/components/AttendeeLists.vue'
import RsvpButtons from '@/features/attendance/components/RsvpButtons.vue'
import SpotsBar from '@/features/attendance/components/SpotsBar.vue'
import { useAttendanceStore } from '@/features/attendance/store'
import CancelEventDialog from './components/CancelEventDialog.vue'
import EventFacts from './components/EventFacts.vue'
import EventHero from './components/EventHero.vue'
import { sanitizeHtml } from './description'
import { describeWeekly } from './format'
import { categoryTone, type EventRow, type Series } from './types'

const { t, locale } = useI18n()
const route = useRoute()
const workspaces = useWorkspaceStore()
const attendance = useAttendanceStore()

const event = ref<EventRow | null>(null)
const series = ref<Series | null>(null)
const groups = ref<Group[]>([])
const loading = ref(true)
const cancelOpen = ref(false)

async function load() {
  loading.value = true
  try {
    event.value = await api.getEvent(String(route.params.id))
    series.value = event.value?.series_id ? await api.getSeries(event.value.series_id) : null
    if (event.value) {
      ;[groups.value] = await Promise.all([
        listGroups(event.value.workspace_id),
        attendance.load([event.value.id]),
      ])
    }
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
}
watch(() => route.params.id, load, { immediate: true })

const tone = computed(() => categoryTone(event.value?.category))
const counts = computed(() => (event.value ? attendance.counts[event.value.id] : undefined))
const html = computed(() => sanitizeHtml(event.value?.description ?? ''))
const audience = computed(() => {
  const ids = event.value?.group_ids ?? []
  if (!ids.length) return t('events.wholeWorkspace')
  return groups.value
    .filter((g) => ids.includes(g.id))
    .map((g) => g.name)
    .join(', ')
})
const repeat = computed(() =>
  series.value
    ? describeWeekly(series.value.weekdays, series.value.interval_weeks, weekdayNames(locale.value), t)
    : null,
)

async function restore() {
  if (!event.value) return
  try {
    await api.updateEvent(event.value.id, { status: 'scheduled' })
    toast.success(t('events.restored'))
    await load()
  } catch (e) {
    toast.error(t(errorKey(e)))
  }
}
</script>

<template>
  <LoadingBlock v-if="loading" />
  <EmptyState v-else-if="!event || !workspaces.current" icon="bi-calendar-x" :title="t('events.notFound')" />

  <article v-else>
    <RouterLink
      :to="{ name: 'events', params: { slug: workspaces.current.slug } }"
      class="btn btn-link px-0 mb-2"
    >
      <i class="bi bi-arrow-left me-1" aria-hidden="true"></i>{{ t('nav.events') }}
    </RouterLink>

    <EventHero :event="event" />

    <div class="row g-4 mt-1">
      <div class="col-lg-7 order-2 order-lg-1">
        <!-- eslint-disable-next-line vue/no-v-html -- sanitised with DOMPurify (CLAUDE.md rule 10) -->
        <div v-if="html" class="bw-description" v-html="html"></div>
        <p v-else class="text-muted">{{ t('events.noDescription') }}</p>
      </div>

      <aside class="col-lg-5 order-1 order-lg-2 d-grid gap-3 align-content-start">
        <section class="card card-body" aria-labelledby="rsvp-title">
          <h2 id="rsvp-title" class="h5">{{ t('rsvp.question') }}</h2>
          <RsvpButtons :event="event" size="lg" />
          <SpotsBar
            v-if="event.capacity && counts"
            :capacity="event.capacity"
            :going="counts.going"
            :tone="tone"
            class="mt-3"
          />
          <p v-if="counts" class="small text-muted mt-3 mb-0">
            {{
              t('rsvp.summary', { going: counts.going, notGoing: counts.not_going, open: counts.no_answer })
            }}
          </p>
        </section>

        <EventFacts :event="event" :repeat="repeat" :audience="audience" />

        <div v-if="workspaces.isTrainer" class="d-flex flex-wrap gap-2">
          <RouterLink
            v-if="event.status === 'scheduled'"
            :to="{ name: 'event-checkin', params: { slug: workspaces.current.slug, id: event.id } }"
            class="btn btn-pink"
          >
            <i class="bi bi-person-check me-1" aria-hidden="true"></i>{{ t('attendance.checkin') }}
          </RouterLink>
          <RouterLink
            :to="{ name: 'event-edit', params: { slug: workspaces.current.slug, id: event.id } }"
            class="btn btn-primary"
          >
            <i class="bi bi-pencil me-1" aria-hidden="true"></i>{{ t('events.edit') }}
          </RouterLink>
          <button
            v-if="event.status === 'scheduled'"
            type="button"
            class="btn btn-outline-danger"
            @click="cancelOpen = true"
          >
            {{ t('events.cancelEvent') }}
          </button>
          <button v-else type="button" class="btn btn-outline-light" @click="restore">
            {{ t('events.restore') }}
          </button>
        </div>
      </aside>
    </div>

    <AttendeeLists v-if="workspaces.isTrainer" :event="event" class="mt-4" />

    <CancelEventDialog v-if="cancelOpen" v-model:open="cancelOpen" :event="event" @cancelled="load" />
  </article>
</template>

<style scoped>
.bw-description :deep(p) {
  line-height: 1.65;
}
</style>
