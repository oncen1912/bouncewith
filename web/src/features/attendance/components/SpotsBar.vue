<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { Tone } from '@/features/events/types'

// "Spots left" progress bar, as on the bouncewith.me event cards.
const props = defineProps<{ capacity: number; going: number; tone: Tone }>()
const { t } = useI18n()
const left = computed(() => Math.max(0, props.capacity - props.going))
const fill = computed(() => Math.min(100, Math.round((props.going / props.capacity) * 100)))
</script>

<template>
  <div class="bw-spots">
    <div class="bw-spots-label">
      <span>{{ left === 0 ? t('rsvp.full') : t('rsvp.spotsLeft') }}</span>
      <span>{{ left }}/{{ capacity }}</span>
    </div>
    <div
      class="bw-spots-track"
      role="progressbar"
      :aria-valuenow="going"
      aria-valuemin="0"
      :aria-valuemax="capacity"
      :aria-label="t('rsvp.spotsTaken', { n: going, total: capacity })"
    >
      <div class="bw-spots-fill" :class="`tone-${tone}`" :style="{ width: `${fill}%` }"></div>
    </div>
  </div>
</template>

<style scoped>
.bw-spots-label {
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--bw-text-muted);
  margin-bottom: 0.35rem;
}

.bw-spots-track {
  height: 4px;
  border-radius: 2px;
  background: rgb(255 255 255 / 8%);
}

.bw-spots-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.4s;
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
