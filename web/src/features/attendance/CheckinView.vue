<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import * as eventsApi from '@/features/events/api'
import type { EventRow } from '@/features/events/types'
import { useEventFormat } from '@/features/events/useEventFormat'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import CheckinQrDialog from './components/CheckinQrDialog.vue'
import CheckinRow from './components/CheckinRow.vue'
import ResetAttendanceDialog from './components/ResetAttendanceDialog.vue'
import type { Attendee, Candidate } from './types'

// Check-in (SPEC §7.1): confirmed members are present by default; the trainer taps the exceptions.
const START_WINDOW_MS = 3 * 3_600_000 // auto-start from 3 h before the event

const { t } = useI18n()
const route = useRoute()
const workspaces = useWorkspaceStore()
const f = useEventFormat()

const event = ref<EventRow | null>(null)
const rows = ref<Attendee[]>([])
const candidates = ref<Candidate[]>([])
const loading = ref(true)
const busy = ref<Set<string>>(new Set())
const query = ref('')
const qrOpen = ref(false)
const resetOpen = ref(false)

const started = computed(() => rows.value.some((r) => r.present !== null))
const confirmed = computed(() => rows.value.filter((r) => r.answer === 'going'))
const others = computed(() => rows.value.filter((r) => r.answer !== 'going'))
const presentCount = computed(() => rows.value.filter((r) => r.present === true).length)
const walkIns = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return []
  const known = new Set(rows.value.map((r) => r.user_id))
  return candidates.value
    .filter((c) => !known.has(c.user_id) && c.full_name.toLowerCase().includes(q))
    .slice(0, 8)
})

async function load() {
  const id = String(route.params.id)
  loading.value = true
  try {
    event.value = await eventsApi.getEvent(id)
    if (!event.value) return
    ;[rows.value, candidates.value] = await Promise.all([api.attendees(id), api.candidates(id)])
    const soon = Date.parse(event.value.starts_at) - Date.now() <= START_WINDOW_MS
    if (!started.value && soon && event.value.status === 'scheduled') await start(false)
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
}
watch(() => route.params.id, load, { immediate: true })

async function start(announce = true) {
  if (!event.value) return
  const n = await api.startCheckin(event.value.id)
  rows.value = await api.attendees(event.value.id)
  if (announce || n) toast.success(t('attendance.started', { n }))
}

async function toggle(userId: string, current: boolean | null) {
  if (!event.value || busy.value.has(userId)) return
  const next = current !== true
  const row = rows.value.find((r) => r.user_id === userId)
  if (row) row.present = next // optimistic: taps must feel instant
  busy.value.add(userId)
  try {
    await api.mark(event.value.id, userId, next)
  } catch (e) {
    if (row) row.present = current
    toast.error(t(errorKey(e)))
  } finally {
    busy.value.delete(userId)
  }
}

async function addWalkIn(c: Candidate) {
  if (!event.value) return
  rows.value.push({
    user_id: c.user_id,
    full_name: c.full_name,
    role: null,
    in_audience: false,
    answer: null,
    reason: null,
    answered_at: null,
    present: null,
    method: null,
    marked_at: null,
  })
  query.value = ''
  await toggle(c.user_id, null)
}

const note = (r: Attendee) =>
  r.answer === 'not_going'
    ? [t('rsvp.youCantShort'), r.reason].filter(Boolean).join(': ')
    : !r.answer
      ? t('attendance.answer.none')
      : null
</script>

<template>
  <LoadingBlock v-if="loading" />
  <EmptyState v-else-if="!event || !workspaces.current" icon="bi-calendar-x" :title="t('events.notFound')" />

  <div v-else class="bw-checkin">
    <RouterLink
      :to="{ name: 'event', params: { slug: workspaces.current.slug, id: event.id } }"
      class="btn btn-link px-0"
    >
      <i class="bi bi-arrow-left me-1" aria-hidden="true"></i>{{ event.title }}
    </RouterLink>

    <header class="bw-checkin-head">
      <div class="min-w-0">
        <div class="section-eyebrow pink">
          {{ t('attendance.checkin') }} · {{ f.date(event.starts_at) }} {{ f.time(event.starts_at) }}
        </div>
        <h1 class="section-title text-truncate">{{ event.title }}</h1>
      </div>
      <p class="bw-checkin-count" aria-live="polite">
        <strong>{{ presentCount }}</strong>
        <span>{{ t('attendance.presentOf', { n: confirmed.length }) }}</span>
      </p>
    </header>

    <div class="d-flex flex-wrap gap-2 mb-3">
      <button v-if="!started" type="button" class="btn btn-primary" @click="start()">
        <i class="bi bi-play-fill me-1" aria-hidden="true"></i>{{ t('attendance.start') }}
      </button>
      <button type="button" class="btn btn-outline-light" @click="qrOpen = true">
        <i class="bi bi-qr-code me-1" aria-hidden="true"></i>{{ t('attendance.showQr') }}
      </button>
      <button
        type="button"
        class="btn btn-outline-danger ms-auto"
        :disabled="!started"
        @click="resetOpen = true"
      >
        {{ t('attendance.reset') }}
      </button>
    </div>

    <section aria-labelledby="ci-confirmed" class="mb-4">
      <h2 id="ci-confirmed" class="h6 text-muted text-uppercase">
        {{ t('attendance.tabs.going', { n: confirmed.length }) }}
      </h2>
      <p v-if="!confirmed.length" class="small text-muted">{{ t('attendance.nobody') }}</p>
      <div class="d-grid gap-2">
        <CheckinRow
          v-for="r in confirmed"
          :key="r.user_id"
          :name="r.full_name"
          :present="r.present"
          :busy="busy.has(r.user_id)"
          @toggle="toggle(r.user_id, r.present)"
        />
      </div>
    </section>

    <section aria-labelledby="ci-others" class="mb-4">
      <h2 id="ci-others" class="h6 text-muted text-uppercase">
        {{ t('attendance.others', { n: others.length }) }}
      </h2>
      <div class="d-grid gap-2">
        <CheckinRow
          v-for="r in others"
          :key="r.user_id"
          :name="r.full_name"
          :note="note(r)"
          :present="r.present"
          :busy="busy.has(r.user_id)"
          @toggle="toggle(r.user_id, r.present)"
        />
      </div>
    </section>

    <section aria-labelledby="ci-walkin">
      <h2 id="ci-walkin" class="h6 text-muted text-uppercase">{{ t('attendance.walkIn') }}</h2>
      <label for="walkin-search" class="visually-hidden">{{ t('attendance.walkInSearch') }}</label>
      <input
        id="walkin-search"
        v-model="query"
        type="search"
        class="form-control mb-2"
        :placeholder="t('attendance.walkInSearch')"
      />
      <div class="d-grid gap-2">
        <button
          v-for="c in walkIns"
          :key="c.user_id"
          type="button"
          class="btn btn-outline-light text-start"
          @click="addWalkIn(c)"
        >
          <i class="bi bi-plus-lg me-2" aria-hidden="true"></i>{{ c.full_name }}
        </button>
      </div>
    </section>

    <CheckinQrDialog v-if="qrOpen" v-model:open="qrOpen" :event-id="event.id" :title="event.title" />
    <ResetAttendanceDialog v-model:open="resetOpen" :event-id="event.id" :title="event.title" @reset="load" />
  </div>
</template>

<style scoped>
.bw-checkin {
  max-width: 640px;
}

.bw-checkin-head {
  display: flex;
  align-items: flex-end;
  gap: 1rem;
  margin: 0.5rem 0 1rem;
}

.bw-checkin-head > div {
  flex: 1;
}

.bw-checkin-count {
  margin: 0;
  text-align: right;
  line-height: 1;
}

.bw-checkin-count strong {
  display: block;
  font-family: var(--bw-font-display);
  font-size: 3rem;
  font-weight: 400;
  color: var(--bw-teal);
}

.bw-checkin-count span {
  font-size: 0.75rem;
  color: var(--bw-text-muted);
}
</style>
