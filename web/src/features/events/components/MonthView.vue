<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatDayLong, formatMonth, localDateKey, monthGrid, weekdayNames } from '@bouncewith/shared'
import EmptyState from '@/components/EmptyState.vue'
import { categoryTone, type EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'
import EventChip from './EventChip.vue'

const props = defineProps<{ events: EventRow[]; slug: string; anchor: string }>()
const emit = defineEmits<{ move: [months: number | 'today'] }>()
const { t, locale } = useI18n()
const f = useEventFormat()

const today = computed(() => localDateKey(new Date(), f.timeZone.value))
const month = computed(() => props.anchor.slice(0, 7))
const grid = computed(() => monthGrid(props.anchor))
const byDay = computed(() => {
  const map = new Map<string, EventRow[]>()
  for (const e of props.events) {
    const key = f.dayKey(e.starts_at)
    map.set(key, [...(map.get(key) ?? []), e])
  }
  return map
})
const selected = ref<string>(today.value.startsWith(month.value) ? today.value : `${month.value}-01`)
watch(month, (m) => (selected.value = today.value.startsWith(m) ? today.value : `${m}-01`))
const selectedEvents = computed(() => byDay.value.get(selected.value) ?? [])
</script>

<template>
  <div class="d-flex align-items-center gap-2 mb-3">
    <button
      type="button"
      class="btn btn-outline-secondary btn-sm"
      :aria-label="t('events.previous')"
      @click="emit('move', -1)"
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
      @click="emit('move', 1)"
    >
      <i class="bi bi-chevron-right" aria-hidden="true"></i>
    </button>
    <h2 class="h4 m-0 ms-2 text-capitalize" aria-live="polite">{{ formatMonth(anchor, locale) }}</h2>
  </div>

  <div class="bw-month">
    <div
      v-for="(name, i) in weekdayNames(locale, 'narrow')"
      :key="`wd-${i}`"
      class="bw-month-name"
      aria-hidden="true"
    >
      {{ name }}
    </div>
    <button
      v-for="day in grid"
      :key="day"
      type="button"
      class="bw-month-day"
      :class="{
        'is-other': !day.startsWith(month),
        'is-today': day === today,
        'is-selected': day === selected,
      }"
      :aria-pressed="day === selected"
      :aria-label="`${formatDayLong(day, locale)}: ${t('events.count', { n: byDay.get(day)?.length ?? 0 })}`"
      @click="selected = day"
    >
      <span class="bw-month-num">{{ Number(day.slice(8)) }}</span>
      <span class="bw-dots" aria-hidden="true">
        <span
          v-for="e in (byDay.get(day) ?? []).slice(0, 4)"
          :key="e.id"
          class="bw-dot"
          :class="`tone-${categoryTone(e.category)}`"
        ></span>
      </span>
    </button>
  </div>

  <section class="mt-4" :aria-label="formatDayLong(selected, locale)">
    <h3 class="h6 text-muted text-uppercase">{{ formatDayLong(selected, locale) }}</h3>
    <div v-if="selectedEvents.length" class="d-grid gap-2">
      <EventChip v-for="e in selectedEvents" :key="e.id" :event="e" :slug="slug" />
    </div>
    <EmptyState v-else icon="bi-calendar" :title="t('events.noneThatDay')" />
  </section>
</template>

<style scoped>
.bw-month {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 4px;
}

.bw-month-name {
  text-align: center;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--bw-text-muted);
  padding-bottom: 0.25rem;
}

.bw-month-day {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-height: 52px;
  padding: 6px 2px;
  border: 1px solid var(--bw-border);
  border-radius: 10px;
  background: var(--bw-bg-2);
  color: var(--bw-text);
}

.bw-month-day.is-other {
  opacity: 0.35;
}

.bw-month-day.is-today .bw-month-num {
  color: var(--bw-accent);
  font-weight: 700;
}

.bw-month-day.is-selected {
  border-color: var(--bw-accent);
  background: color-mix(in srgb, var(--bw-accent) 12%, var(--bw-bg-2));
}

.bw-month-day:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 1px;
}

.bw-dots {
  display: flex;
  gap: 3px;
}

.bw-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.tone-teal {
  background: var(--bw-teal);
}

.tone-yellow {
  background: var(--bw-yellow);
}

.tone-pink {
  background: var(--bw-pink);
}
</style>
