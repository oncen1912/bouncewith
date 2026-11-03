<script setup lang="ts">
import { computed } from 'vue'
import { formatTime } from '@bouncewith/shared'
import { useI18n } from 'vue-i18n'
import { categoryTone, type EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

// Compact event for week and month views.
const props = defineProps<{ event: EventRow; slug: string }>()
const { locale, t } = useI18n()
const f = useEventFormat()
const tone = computed(() => categoryTone(props.event.category))
</script>

<template>
  <RouterLink
    :to="{ name: 'event', params: { slug, id: event.id } }"
    class="bw-chip"
    :class="[`tone-${tone}`, { 'is-cancelled': event.status === 'cancelled' }]"
  >
    <span class="bw-chip-time">{{ formatTime(event.starts_at, locale, f.timeZone.value) }}</span>
    <span class="bw-chip-title">{{ event.title }}</span>
    <span v-if="event.status === 'cancelled'" class="visually-hidden">({{ t('events.cancelled') }})</span>
  </RouterLink>
</template>

<style scoped>
.bw-chip {
  display: block;
  padding: 0.45rem 0.6rem;
  border-left: 3px solid var(--tone);
  border-radius: 6px;
  background: color-mix(in srgb, var(--tone) 10%, var(--bw-bg-3));
  color: var(--bw-text);
  text-decoration: none;
  font-size: 0.8125rem;
  line-height: 1.25;
}

.bw-chip:hover {
  background: color-mix(in srgb, var(--tone) 20%, var(--bw-bg-3));
}

.bw-chip:focus-visible {
  outline: 2px solid var(--tone);
  outline-offset: 2px;
}

.tone-teal {
  --tone: var(--bw-teal);
}

.tone-yellow {
  --tone: var(--bw-yellow);
}

.tone-pink {
  --tone: var(--bw-pink);
}

.bw-chip-time {
  display: block;
  font-weight: 700;
  color: var(--tone);
}

.bw-chip-title {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.is-cancelled {
  opacity: 0.55;
}

.is-cancelled .bw-chip-title {
  text-decoration: line-through;
}
</style>
