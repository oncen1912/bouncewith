<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { categoryTone, type EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

const props = defineProps<{ event: EventRow }>()
const { t } = useI18n()
const f = useEventFormat()
const tone = computed(() => categoryTone(props.event.category))
</script>

<template>
  <div :class="`tone-${tone}`">
    <div
      class="bw-hero"
      :style="event.image_url ? { backgroundImage: `url(${JSON.stringify(event.image_url)})` } : undefined"
    >
      <div class="d-flex flex-wrap gap-2">
        <span class="bw-badge bw-badge--glass">{{ f.date(event.starts_at) }}</span>
        <span v-if="event.category" class="bw-badge" :class="`bw-badge--${tone}`">{{ event.category }}</span>
        <span v-if="event.status === 'cancelled'" class="bw-badge bw-badge--danger">{{
          t('events.cancelled')
        }}</span>
        <span v-else class="bw-badge bw-badge--glass">{{ f.relative(event.starts_at) }}</span>
        <span v-if="event.visibility === 'public'" class="bw-badge bw-badge--glass">
          <i class="bi bi-globe2 me-1" aria-hidden="true"></i>{{ t('events.public') }}
        </span>
      </div>
      <h1
        class="bw-hero-title"
        :class="[`text-${tone}`, { 'text-decoration-line-through': event.status === 'cancelled' }]"
      >
        {{ event.title }}
      </h1>
    </div>
  </div>
</template>

<style scoped>
.bw-hero {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 2rem;
  min-height: 200px;
  padding: 1.25rem;
  border-radius: var(--bw-radius-lg);
  border: 1px solid var(--bw-border);
  background-size: cover;
  background-position: center;
  overflow: hidden;
}

.tone-teal .bw-hero:not([style]) {
  background:
    radial-gradient(ellipse at top right, rgb(27 189 191 / 30%), transparent 60%),
    radial-gradient(ellipse at bottom left, rgb(240 26 127 / 12%), transparent 60%), var(--bw-bg-3);
}

.tone-yellow .bw-hero:not([style]) {
  background:
    radial-gradient(ellipse at top right, rgb(248 184 48 / 30%), transparent 60%),
    radial-gradient(ellipse at bottom left, rgb(240 26 127 / 12%), transparent 60%), var(--bw-bg-3);
}

.tone-pink .bw-hero:not([style]) {
  background:
    radial-gradient(ellipse at top right, rgb(240 26 127 / 30%), transparent 60%),
    radial-gradient(ellipse at bottom left, rgb(27 189 191 / 12%), transparent 60%), var(--bw-bg-3);
}

.bw-hero[style]::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgb(0 0 0 / 20%), rgb(0 0 0 / 75%));
}

.bw-hero > * {
  position: relative;
}

.bw-hero-title {
  font-size: clamp(2.5rem, 9vw, 4.5rem);
  margin: 0;
}
</style>
