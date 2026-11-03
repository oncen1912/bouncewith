<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { EventRow } from '../types'
import { useEventFormat } from '../useEventFormat'

defineProps<{ event: EventRow; repeat: string | null; audience: string }>()
const { t } = useI18n()
const f = useEventFormat()
</script>

<template>
  <dl class="bw-facts card card-body">
    <dt>
      <i class="bi bi-clock-fill" aria-hidden="true"></i
      ><span class="visually-hidden">{{ t('events.when') }}</span>
    </dt>
    <dd>{{ f.date(event.starts_at) }} · {{ f.timeRange(event.starts_at, event.ends_at) }}</dd>
    <template v-if="repeat">
      <dt>
        <i class="bi bi-arrow-repeat" aria-hidden="true"></i
        ><span class="visually-hidden">{{ t('events.repeats') }}</span>
      </dt>
      <dd>{{ repeat }}</dd>
    </template>
    <template v-if="event.location">
      <dt>
        <i class="bi bi-geo-alt-fill" aria-hidden="true"></i
        ><span class="visually-hidden">{{ t('events.location') }}</span>
      </dt>
      <dd>
        <a v-if="event.location_url" :href="event.location_url" target="_blank" rel="noopener noreferrer">{{
          event.location
        }}</a>
        <template v-else>{{ event.location }}</template>
      </dd>
    </template>
    <dt>
      <i class="bi bi-people-fill" aria-hidden="true"></i
      ><span class="visually-hidden">{{ t('events.audience') }}</span>
    </dt>
    <dd>{{ audience }}</dd>
    <template v-if="event.capacity">
      <dt>
        <i class="bi bi-person-check-fill" aria-hidden="true"></i
        ><span class="visually-hidden">{{ t('events.capacity') }}</span>
      </dt>
      <dd>{{ t('events.capacityValue', { n: event.capacity }) }}</dd>
    </template>
    <template v-if="event.rsvp_deadline">
      <dt>
        <i class="bi bi-hourglass-split" aria-hidden="true"></i
        ><span class="visually-hidden">{{ t('events.deadline') }}</span>
      </dt>
      <dd>
        {{
          t('events.answerUntil', {
            date: f.date(event.rsvp_deadline),
            time: f.time(event.rsvp_deadline),
          })
        }}
      </dd>
    </template>
  </dl>
</template>

<style scoped>
.bw-facts {
  display: grid;
  grid-template-columns: 1.5rem 1fr;
  gap: 0.75rem 0.5rem;
  margin: 0;
}

.bw-facts dt {
  color: var(--bw-accent);
}

.bw-facts dd {
  margin: 0;
}
</style>
