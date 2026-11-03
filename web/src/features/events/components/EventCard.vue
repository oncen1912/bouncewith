<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { categoryTone, type EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

// The bouncewith.me event card: banner with glass badges, colour-coded by category.
const props = defineProps<{ event: EventRow; slug: string }>()
const { t } = useI18n()
const f = useEventFormat()

const tone = computed(() => categoryTone(props.event.category))
const cancelled = computed(() => props.event.status === 'cancelled')
</script>

<template>
  <RouterLink
    :to="{ name: 'event', params: { slug, id: event.id } }"
    class="bw-card bw-event"
    :class="[`tone-${tone}`, { 'is-cancelled': cancelled }]"
  >
    <div
      class="bw-event-banner"
      :style="event.image_url ? { backgroundImage: `url(${JSON.stringify(event.image_url)})` } : undefined"
    >
      <div class="bw-event-badges">
        <span class="bw-badge bw-badge--glass">{{ f.date(event.starts_at) }}</span>
        <span v-if="event.category" class="bw-badge" :class="`bw-badge--${tone}`">{{ event.category }}</span>
        <span v-if="cancelled" class="bw-badge bw-badge--danger">{{ t('events.cancelled') }}</span>
        <span v-else class="bw-badge bw-badge--glass text-muted">{{ f.relative(event.starts_at) }}</span>
      </div>
    </div>
    <div class="bw-event-body">
      <h3 class="bw-event-title" :class="`text-${tone}`">{{ event.title }}</h3>
      <p class="bw-event-meta">
        <span
          ><i class="bi bi-clock-fill me-1" aria-hidden="true"></i
          >{{ f.timeRange(event.starts_at, event.ends_at) }}</span
        >
        <span v-if="event.location" class="text-truncate">
          <i class="bi bi-geo-alt-fill me-1" aria-hidden="true"></i>{{ event.location }}
        </span>
        <span v-if="event.series_id"
          ><i class="bi bi-arrow-repeat" aria-hidden="true"></i>
          <span class="visually-hidden">{{ t('events.repeats') }}</span></span
        >
        <span v-if="event.visibility === 'public'"
          ><i class="bi bi-globe2" aria-hidden="true"></i>
          <span class="visually-hidden">{{ t('events.public') }}</span></span
        >
      </p>
    </div>
  </RouterLink>
</template>

<style scoped>
.bw-event-banner {
  position: relative;
  height: 112px;
  background-size: cover;
  background-position: center;
}

.tone-teal .bw-event-banner:not([style]) {
  background: radial-gradient(ellipse at top right, rgb(27 189 191 / 35%), transparent 65%), var(--bw-bg-4);
}

.tone-yellow .bw-event-banner:not([style]) {
  background: radial-gradient(ellipse at top right, rgb(248 184 48 / 35%), transparent 65%), var(--bw-bg-4);
}

.tone-pink .bw-event-banner:not([style]) {
  background: radial-gradient(ellipse at top right, rgb(240 26 127 / 35%), transparent 65%), var(--bw-bg-4);
}

.bw-event-badges {
  position: absolute;
  inset: 0.75rem auto auto 0.75rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.bw-event-body {
  padding: 1rem 1.25rem 1.25rem;
}

.bw-event-title {
  font-size: 1.75rem;
  margin: 0 0 0.5rem;
}

.bw-event-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem 0.9rem;
  margin: 0;
  font-size: 0.8125rem;
  color: var(--bw-text-muted);
}

.is-cancelled .bw-event-title {
  text-decoration: line-through;
  opacity: 0.6;
}

.is-cancelled .bw-event-banner {
  filter: grayscale(1);
  opacity: 0.6;
}
</style>
