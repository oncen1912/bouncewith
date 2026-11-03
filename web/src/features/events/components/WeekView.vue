<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { addDays, formatDayLong, localDateKey, weekdayNames } from '@bouncewith/shared'
import type { EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'
import EventChip from './EventChip.vue'

const props = defineProps<{ events: EventRow[]; slug: string; start: string }>()
const emit = defineEmits<{ move: [days: number | 'today'] }>()
const { t, locale } = useI18n()
const f = useEventFormat()

const names = computed(() => weekdayNames(locale.value))
const today = computed(() => localDateKey(new Date(), f.timeZone.value))
const days = computed(() =>
  Array.from({ length: 7 }, (_, i) => {
    const date = addDays(props.start, i)
    return { date, events: props.events.filter((e) => f.dayKey(e.starts_at) === date) }
  }),
)
const title = computed(
  () =>
    `${formatDayLong(props.start, locale.value)} – ${formatDayLong(addDays(props.start, 6), locale.value)}`,
)
</script>

<template>
  <div class="d-flex align-items-center gap-2 mb-3">
    <button
      type="button"
      class="btn btn-outline-secondary btn-sm"
      :aria-label="t('events.previous')"
      @click="emit('move', -7)"
    >
      <i class="bi bi-chevron-left" aria-hidden="true"></i>
    </button>
    <button type="button" class="btn btn-outline-secondary btn-sm" @click="emit('move', 'today')">
      {{ t('events.today') }}
    </button>
    <button
      type="button"
      class="btn btn-outline-secondary btn-sm"
      :aria-label="t('events.next')"
      @click="emit('move', 7)"
    >
      <i class="bi bi-chevron-right" aria-hidden="true"></i>
    </button>
    <h2 class="h6 m-0 ms-2 text-truncate" aria-live="polite">{{ title }}</h2>
  </div>

  <div class="bw-week">
    <section
      v-for="(day, i) in days"
      :key="day.date"
      class="bw-week-day"
      :class="{ 'is-today': day.date === today }"
      :aria-label="formatDayLong(day.date, locale)"
    >
      <header class="bw-week-head">
        <span>{{ names[i] }}</span>
        <strong>{{ Number(day.date.slice(8)) }}</strong>
      </header>
      <div class="d-grid gap-1">
        <EventChip v-for="e in day.events" :key="e.id" :event="e" :slug="slug" />
        <span v-if="!day.events.length" class="bw-week-empty" aria-hidden="true">–</span>
      </div>
    </section>
  </div>
</template>

<style scoped>
.bw-week {
  display: grid;
  gap: 0.5rem;
}

@media (min-width: 768px) {
  .bw-week {
    grid-template-columns: repeat(7, minmax(0, 1fr));
  }
}

.bw-week-day {
  background: var(--bw-bg-2);
  border: 1px solid var(--bw-border);
  border-radius: var(--bw-radius);
  padding: 0.5rem;
  min-height: 3.5rem;
}

@media (max-width: 767.98px) {
  .bw-week-day {
    display: grid;
    grid-template-columns: 3rem 1fr;
    gap: 0.5rem;
  }
}

.bw-week-day.is-today {
  border-color: var(--bw-accent);
}

.bw-week-head {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 0.4rem;
  font-size: 0.75rem;
  color: var(--bw-text-muted);
  text-transform: uppercase;
}

.bw-week-head strong {
  font-family: var(--bw-font-display);
  font-size: 1.5rem;
  font-weight: 400;
  color: var(--bw-text);
  line-height: 1;
}

.is-today .bw-week-head strong {
  color: var(--bw-accent);
}

.bw-week-empty {
  color: var(--bw-text-muted);
  opacity: 0.4;
  text-align: center;
}
</style>
