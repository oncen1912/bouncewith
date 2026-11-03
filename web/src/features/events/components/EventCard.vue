<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import RsvpButtons from '@/features/attendance/components/RsvpButtons.vue'
import SpotsBar from '@/features/attendance/components/SpotsBar.vue'
import { useAttendanceStore } from '@/features/attendance/store'
import { categoryTone, type EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

// The bouncewith.me event card: banner with glass badges, colour-coded by category, spots bar and RSVP.
// The title link is stretched over the whole card; the RSVP buttons sit above it (no buttons inside a link).
const props = withDefaults(defineProps<{ event: EventRow; slug: string; rsvp?: boolean }>(), { rsvp: true })
const { t } = useI18n()
const f = useEventFormat()
const attendance = useAttendanceStore()
const counts = computed(() => attendance.counts[props.event.id])

const tone = computed(() => categoryTone(props.event.category))
const cancelled = computed(() => props.event.status === 'cancelled')
</script>

<template>
  <article class="bw-card bw-event" :class="[`tone-${tone}`, { 'is-cancelled': cancelled }]">
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
      <h3 class="bw-event-title" :class="`text-${tone}`">
        <RouterLink :to="{ name: 'event', params: { slug, id: event.id } }" class="bw-event-link">{{
          event.title
        }}</RouterLink>
      </h3>
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
        <span v-if="counts && !event.capacity"
          ><i class="bi bi-people-fill me-1" aria-hidden="true"></i
          >{{ t('rsvp.goingCount', { n: counts.going }) }}</span
        >
      </p>
      <SpotsBar
        v-if="event.capacity && counts && !cancelled"
        :capacity="event.capacity"
        :going="counts.going"
        :tone="tone"
        class="mt-3"
      />
      <RsvpButtons v-if="rsvp" :event="event" class="bw-event-actions mt-3" />
    </div>
  </article>
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

.bw-event {
  position: relative;
}

.bw-event:hover {
  transform: translateY(-4px);
  border-color: color-mix(in srgb, var(--bw-accent) 30%, transparent);
  box-shadow: 0 20px 60px rgb(0 0 0 / 40%);
}

.bw-event-body {
  padding: 1rem 1.25rem 1.25rem;
}

.bw-event-link {
  color: inherit;
  text-decoration: none;
}

/* stretched link: the whole card opens the event */
.bw-event-link::after {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 1;
}

.bw-event-link:focus-visible {
  outline: none;
}

.bw-event:has(.bw-event-link:focus-visible) {
  outline: 2px solid var(--bw-accent);
  outline-offset: 3px;
}

.bw-event-actions {
  position: relative;
  z-index: 2;
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
