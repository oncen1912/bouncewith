<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatDayLong } from '@bouncewith/shared'
import type { EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'
import EventCard from './EventCard.vue'

const props = defineProps<{ events: EventRow[]; slug: string }>()
const { locale } = useI18n()
const f = useEventFormat()

const days = computed(() => {
  const map = new Map<string, EventRow[]>()
  for (const e of props.events) {
    const key = f.dayKey(e.starts_at)
    map.set(key, [...(map.get(key) ?? []), e])
  }
  return [...map.entries()]
})
</script>

<template>
  <section v-for="[day, list] in days" :key="day" class="mb-4" :aria-labelledby="`day-${day}`">
    <h2 :id="`day-${day}`" class="bw-day">{{ formatDayLong(day, locale) }}</h2>
    <div class="row g-3">
      <div v-for="e in list" :key="e.id" class="col-md-6">
        <EventCard :event="e" :slug="slug" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.bw-day {
  font-family: var(--bw-font-body);
  font-size: 0.8125rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--bw-text-muted);
  margin-bottom: 0.75rem;
}
</style>
