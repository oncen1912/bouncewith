<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { localDateKey } from '@bouncewith/shared'
import { errorKey } from '@/app/errors'
import LoadingBlock from '@/components/LoadingBlock.vue'
import PageHeader from '@/components/PageHeader.vue'
import { useAuthStore } from '@/features/auth/store'
import { listGroups } from '@/features/members/api'
import type { Group } from '@/features/members/types'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import AudienceFields from './components/AudienceFields.vue'
import RepeatFields from './components/RepeatFields.vue'
import { emptyValues, toEventFields, toSeriesChanges, toSeriesInsert, valuesFromEvent } from './form'
import { CATEGORY_SUGGESTIONS, DEADLINE_OPTIONS, type EventFormValues, type EventRow } from './types'
import { useEventFormat } from './useEventFormat'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()
const f = useEventFormat()

const editingId = computed(() => (route.name === 'event-edit' ? String(route.params.id) : null))
const ws = computed(() => workspaces.current)
const original = ref<EventRow | null>(null)
const values = ref<EventFormValues>(emptyValues(localDateKey(new Date(), f.timeZone.value)))
const groups = ref<Group[]>([])
const scope = ref<'this' | 'future'>('this')
const loading = ref(true)
const busy = ref(false)

const isSeries = computed(() => !!original.value?.series_id)
const showRepeat = computed(() =>
  editingId.value ? isSeries.value && scope.value === 'future' : values.value.repeats,
)
const deadlineOptions = computed(() => {
  const m = values.value.deadlineMinutes
  return m == null || (DEADLINE_OPTIONS as readonly (number | null)[]).includes(m)
    ? DEADLINE_OPTIONS
    : [...DEADLINE_OPTIONS, m]
})

watch(
  () => [ws.value?.workspace_id, editingId.value],
  async () => {
    if (!ws.value) return
    loading.value = true
    try {
      groups.value = await listGroups(ws.value.workspace_id)
      if (editingId.value) {
        original.value = await api.getEvent(editingId.value)
        if (original.value) {
          const series = original.value.series_id ? await api.getSeries(original.value.series_id) : null
          values.value = valuesFromEvent(original.value, series, f.timeZone.value)
        }
      }
    } catch {
      toast.error(t('errors.generic'))
    } finally {
      loading.value = false
    }
  },
  { immediate: true },
)

function deadlineLabel(m: number | null) {
  if (m == null) return t('events.deadlineAtStart')
  return m % 1440 === 0
    ? t('events.deadlineDays', { n: m / 1440 })
    : t('events.deadlineHours', { n: Math.round(m / 6) / 10 })
}

async function submit() {
  if (!ws.value || !auth.user) return
  busy.value = true
  try {
    const v = values.value
    const tz = f.timeZone.value
    let target: string | null = editingId.value
    if (!editingId.value && v.repeats) {
      const { id, created } = await api.createSeries(toSeriesInsert(v, ws.value.workspace_id, auth.user.id))
      toast.success(t('events.seriesCreated', { n: created }))
      target = await api.firstOccurrence(id)
    } else if (!editingId.value) {
      target = await api.createEvent({
        ...toEventFields(v, tz),
        workspace_id: ws.value.workspace_id,
        created_by: auth.user.id,
      })
      toast.success(t('events.created'))
    } else if (scope.value === 'future') {
      const r = await api.updateSeries(editingId.value, toSeriesChanges(v))
      toast.success(t('events.seriesUpdated', r))
    } else {
      await api.updateEvent(editingId.value, toEventFields(v, tz))
      toast.success(t('me.saved'))
    }
    await router.replace(
      target
        ? { name: 'event', params: { slug: ws.value.slug, id: target } }
        : { name: 'events', params: { slug: ws.value.slug } },
    )
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <PageHeader :title="editingId ? t('events.editTitle') : t('events.new')" :eyebrow="ws?.name" />
  <LoadingBlock v-if="loading" />

  <form v-else class="d-grid gap-3" style="max-width: 720px" @submit.prevent="submit">
    <section v-if="isSeries" class="card card-body">
      <h2 class="h6">{{ t('events.whichEvents') }}</h2>
      <div class="form-check">
        <input id="sc-this" v-model="scope" class="form-check-input" type="radio" value="this" />
        <label class="form-check-label" for="sc-this">{{ t('events.scopeThis') }}</label>
      </div>
      <div class="form-check">
        <input id="sc-future" v-model="scope" class="form-check-input" type="radio" value="future" />
        <label class="form-check-label" for="sc-future">{{ t('events.scopeFuture') }}</label>
        <div class="form-text">{{ t('events.scopeFutureHelp') }}</div>
      </div>
    </section>

    <section class="card card-body d-grid gap-3">
      <div>
        <label for="ev-title" class="form-label">{{ t('events.title') }}</label>
        <input id="ev-title" v-model="values.title" class="form-control" maxlength="140" required />
      </div>
      <div>
        <label for="ev-category" class="form-label">{{ t('events.category') }}</label>
        <input
          id="ev-category"
          v-model="values.category"
          class="form-control"
          list="ev-categories"
          maxlength="40"
        />
        <datalist id="ev-categories">
          <option v-for="c in CATEGORY_SUGGESTIONS" :key="c" :value="c" />
        </datalist>
      </div>
      <div>
        <label for="ev-description" class="form-label">{{ t('events.description') }}</label>
        <textarea
          id="ev-description"
          v-model="values.descriptionText"
          class="form-control"
          rows="4"
          maxlength="5000"
        ></textarea>
      </div>
    </section>

    <section class="card card-body d-grid gap-3">
      <div class="row g-3">
        <div class="col-sm-4">
          <label for="ev-date" class="form-label">{{
            values.repeats || isSeries ? t('events.firstDate') : t('events.date')
          }}</label>
          <input
            id="ev-date"
            v-model="values.date"
            type="date"
            class="form-control"
            required
            :disabled="isSeries && scope === 'future'"
          />
        </div>
        <div class="col-6 col-sm-4">
          <label for="ev-start" class="form-label">{{ t('events.start') }}</label>
          <input id="ev-start" v-model="values.startTime" type="time" class="form-control" required />
        </div>
        <div class="col-6 col-sm-4">
          <label for="ev-end" class="form-label">{{ t('events.end') }}</label>
          <input id="ev-end" v-model="values.endTime" type="time" class="form-control" required />
        </div>
      </div>
      <p class="form-text m-0">{{ t('events.timezoneHint', { tz: f.timeZone.value }) }}</p>
      <div v-if="!editingId" class="form-check form-switch">
        <input
          id="ev-repeats"
          v-model="values.repeats"
          class="form-check-input"
          type="checkbox"
          role="switch"
        />
        <label class="form-check-label" for="ev-repeats">{{ t('events.repeatsWeekly') }}</label>
      </div>
      <RepeatFields v-if="showRepeat" v-model="values" :min-until="values.date" />
    </section>

    <section class="card card-body d-grid gap-3">
      <div class="row g-3">
        <div class="col-sm-6">
          <label for="ev-location" class="form-label">{{ t('events.location') }}</label>
          <input id="ev-location" v-model="values.location" class="form-control" maxlength="140" />
        </div>
        <div class="col-sm-6">
          <label for="ev-location-url" class="form-label">{{ t('events.locationUrl') }}</label>
          <input
            id="ev-location-url"
            v-model="values.locationUrl"
            type="url"
            class="form-control"
            placeholder="https://"
          />
        </div>
        <div class="col-sm-6">
          <label for="ev-capacity" class="form-label">{{ t('events.capacity') }}</label>
          <input
            id="ev-capacity"
            v-model.number="values.capacity"
            type="number"
            min="1"
            max="10000"
            class="form-control"
            :placeholder="t('events.unlimited')"
          />
        </div>
        <div class="col-sm-6">
          <label for="ev-deadline" class="form-label">{{ t('events.deadline') }}</label>
          <select id="ev-deadline" v-model="values.deadlineMinutes" class="form-select">
            <option v-for="m in deadlineOptions" :key="String(m)" :value="m">{{ deadlineLabel(m) }}</option>
          </select>
        </div>
      </div>
    </section>

    <section class="card card-body">
      <AudienceFields v-model="values" :groups="groups" />
    </section>

    <div class="d-flex gap-2 justify-content-end">
      <button type="button" class="btn btn-outline-secondary" @click="router.back()">
        {{ t('common.cancel') }}
      </button>
      <button type="submit" class="btn btn-primary" :disabled="busy">
        {{ editingId ? t('common.save') : t('events.create') }}
      </button>
    </div>
  </form>
</template>
