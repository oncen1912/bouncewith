<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import type { EventRow } from '@/features/events/types'
import { useEventFormat } from '@/features/events/useEventFormat'
import * as api from '../api'
import { useAttendanceStore } from '../store'
import { downloadCsv } from '../csv'
import type { Attendee } from '../types'

// Trainer view on the event page: who answered what, and who came.
const props = defineProps<{ event: EventRow }>()
const { t } = useI18n()
const f = useEventFormat()
const attendance = useAttendanceStore()
const rows = ref<Attendee[]>([])
const tab = ref<'going' | 'not_going' | 'none'>('going')

// reload when the event changes or its counts change (e.g. the trainer answered "Are you coming?" above)
watch(
  () => [props.event.id, attendance.counts[props.event.id]] as const,
  async ([id]) => {
    try {
      rows.value = await api.attendees(id)
    } catch {
      toast.error(t('errors.generic'))
    }
  },
  { immediate: true },
)

const groups = computed(() => ({
  going: rows.value.filter((r) => r.answer === 'going'),
  not_going: rows.value.filter((r) => r.answer === 'not_going'),
  none: rows.value.filter((r) => !r.answer),
}))

const presence = (r: Attendee) => (r.present === true ? 'present' : r.present === false ? 'absent' : null)

function exportCsv() {
  downloadCsv(`${props.event.title}-${f.dayKey(props.event.starts_at)}.csv`, [
    [
      t('attendance.csv.name'),
      t('attendance.csv.answer'),
      t('attendance.csv.reason'),
      t('attendance.csv.attendance'),
    ],
    ...rows.value.map((r) => [
      r.full_name,
      r.answer ? t(`attendance.answer.${r.answer}`) : t('attendance.answer.none'),
      r.reason,
      presence(r) ? t(`attendance.${presence(r)}`) : '',
    ]),
  ])
}
</script>

<template>
  <section class="card card-body" aria-labelledby="att-title">
    <div class="d-flex align-items-center gap-2 mb-3">
      <h2 id="att-title" class="h5 m-0 flex-grow-1">{{ t('attendance.answers') }}</h2>
      <button type="button" class="btn btn-link btn-sm" :disabled="!rows.length" @click="exportCsv">
        <i class="bi bi-download me-1" aria-hidden="true"></i>CSV
      </button>
    </div>
    <div class="d-flex flex-wrap gap-2 mb-3" role="group" :aria-label="t('attendance.answers')">
      <button
        v-for="k in ['going', 'not_going', 'none'] as const"
        :key="k"
        type="button"
        class="bw-pill"
        :aria-pressed="tab === k"
        @click="tab = k"
      >
        {{ t(`attendance.tabs.${k}`, { n: groups[k].length }) }}
      </button>
    </div>
    <p v-if="!groups[tab].length" class="text-muted small mb-0">{{ t('attendance.nobody') }}</p>
    <ul v-else class="list-unstyled m-0 d-grid gap-2">
      <li v-for="r in groups[tab]" :key="r.user_id" class="d-flex align-items-center gap-2">
        <span class="flex-grow-1 min-w-0">
          <span class="d-block text-truncate">{{ r.full_name || t('members.noName') }}</span>
          <span v-if="r.reason" class="d-block small text-muted text-truncate">{{ r.reason }}</span>
        </span>
        <span
          v-if="presence(r)"
          class="bw-badge"
          :class="presence(r) === 'present' ? 'bw-badge--teal' : 'bw-badge--muted'"
        >
          {{ t(`attendance.${presence(r)}`) }}
        </span>
      </li>
    </ul>
  </section>
</template>
