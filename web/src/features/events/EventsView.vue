<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { addDays, localDateKey, monthGrid, startOfWeek, zonedToUtc } from '@bouncewith/shared'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import PageHeader from '@/components/PageHeader.vue'
import { listGroups } from '@/features/members/api'
import type { Group } from '@/features/members/types'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import EventFilters, { type EventsQuery } from './components/EventFilters.vue'
import EventListView from './components/EventListView.vue'
import MonthView from './components/MonthView.vue'
import WeekView from './components/WeekView.vue'
import type { EventRow } from './types'
import { useEventFormat } from './useEventFormat'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const workspaces = useWorkspaceStore()
const f = useEventFormat()

const ws = computed(() => workspaces.current)
const events = ref<EventRow[]>([])
const groups = ref<Group[]>([])
const loading = ref(true)

// view, anchor date and filters live in the URL so reload / back work
const str = (v: unknown) => (typeof v === 'string' && v ? v : null)
const query = computed<EventsQuery>({
  get: () => ({
    view: (['week', 'month'].includes(String(route.query.view))
      ? route.query.view
      : 'list') as EventsQuery['view'],
    past: route.query.past === '1',
    group: str(route.query.group),
    category: str(route.query.category),
  }),
  set: (q) => void router.replace({ query: { ...route.query, ...toQuery(q) } }),
})
const toQuery = (q: EventsQuery) => ({
  view: q.view === 'list' ? undefined : q.view,
  past: q.past ? '1' : undefined,
  group: q.group ?? undefined,
  category: q.category ?? undefined,
})
const today = computed(() => localDateKey(new Date(), f.timeZone.value))
const anchor = computed(() => str(route.query.date) ?? today.value)
const weekStart = computed(() => startOfWeek(anchor.value))

function range(): [string, string, 'asc' | 'desc'] {
  const at = (d: string) => zonedToUtc(d, '00:00', f.timeZone.value).toISOString()
  const now = new Date().toISOString()
  if (query.value.view === 'week') return [at(weekStart.value), at(addDays(weekStart.value, 7)), 'asc']
  if (query.value.view === 'month') {
    const grid = monthGrid(anchor.value)
    return [at(grid[0]!), at(addDays(grid.at(-1)!, 1)), 'asc']
  }
  return query.value.past
    ? [at(addDays(today.value, -180)), now, 'desc']
    : [now, at(addDays(today.value, 120)), 'asc']
}

async function load() {
  if (!ws.value) return
  loading.value = true
  try {
    const [from, to, order] = range()
    events.value = await api.listEvents(ws.value.workspace_id, from, to, order)
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
}

watch(
  () => [ws.value?.workspace_id, query.value.view, query.value.past, anchor.value],
  () => void load(),
  { immediate: true },
)
watch(
  () => ws.value?.workspace_id,
  async (id) => (groups.value = id ? await listGroups(id).catch(() => []) : []),
  { immediate: true },
)

const categories = computed(() =>
  [...new Set(events.value.map((e) => e.category?.toLowerCase()).filter((c): c is string => !!c))].sort(),
)
const visible = computed(() =>
  events.value.filter(
    (e) =>
      (!query.value.group || e.group_ids.includes(query.value.group)) &&
      (!query.value.category || e.category?.toLowerCase() === query.value.category),
  ),
)

function move(step: number | 'today', unit: 'day' | 'month') {
  let date = today.value
  if (step !== 'today') {
    if (unit === 'day') date = addDays(anchor.value, step)
    else {
      const [y, m] = anchor.value.split('-').map(Number) as [number, number]
      const d = new Date(Date.UTC(y, m - 1 + step, 1))
      date = d.toISOString().slice(0, 10)
    }
  }
  void router.replace({ query: { ...route.query, date: date === today.value ? undefined : date } })
}
</script>

<template>
  <PageHeader :title="t('nav.events')" :eyebrow="t('events.eyebrow')">
    <RouterLink
      v-if="workspaces.isTrainer && ws"
      :to="{ name: 'event-new', params: { slug: ws.slug } }"
      class="btn btn-primary"
    >
      <i class="bi bi-plus-lg me-1" aria-hidden="true"></i>{{ t('events.new') }}
    </RouterLink>
  </PageHeader>

  <EventFilters v-model="query" :groups="groups" :categories="categories" />

  <template v-if="ws">
    <WeekView
      v-if="query.view === 'week'"
      :events="visible"
      :slug="ws.slug"
      :start="weekStart"
      @move="(s) => move(s, 'day')"
    />
    <MonthView
      v-else-if="query.view === 'month'"
      :events="visible"
      :slug="ws.slug"
      :anchor="anchor"
      @move="(s) => move(s, 'month')"
    />
    <LoadingBlock v-else-if="loading" />
    <EmptyState
      v-else-if="visible.length === 0"
      icon="bi-calendar-event"
      :title="query.past ? t('events.noPast') : t('home.noEventsTitle')"
      :text="workspaces.isTrainer && !query.past ? t('events.emptyTrainer') : undefined"
    >
      <RouterLink
        v-if="workspaces.isTrainer && !query.past"
        :to="{ name: 'event-new', params: { slug: ws.slug } }"
        class="btn btn-primary mt-3"
        >{{ t('events.new') }}</RouterLink
      >
    </EmptyState>
    <EventListView v-else :events="visible" :slug="ws.slug" />
  </template>
</template>
