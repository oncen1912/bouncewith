<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { weekdayNames } from '@bouncewith/shared'
import { errorKey } from '@/app/errors'
import EmptyState from '@/components/EmptyState.vue'
import LoadingBlock from '@/components/LoadingBlock.vue'
import { listGroups } from '@/features/members/api'
import type { Group } from '@/features/members/types'
import { useWorkspaceStore } from '@/features/workspace/store'
import * as api from './api'
import CancelEventDialog from './components/CancelEventDialog.vue'
import { sanitizeHtml } from './description'
import { describeWeekly } from './format'
import { categoryTone, type EventRow, type Series } from './types'
import { useEventFormat } from './useEventFormat'

const { t, locale } = useI18n()
const route = useRoute()
const workspaces = useWorkspaceStore()
const f = useEventFormat()

const event = ref<EventRow | null>(null)
const series = ref<Series | null>(null)
const groups = ref<Group[]>([])
const loading = ref(true)
const cancelOpen = ref(false)

async function load() {
  loading.value = true
  try {
    event.value = await api.getEvent(String(route.params.id))
    series.value = event.value?.series_id ? await api.getSeries(event.value.series_id) : null
    if (event.value) groups.value = await listGroups(event.value.workspace_id)
  } catch {
    toast.error(t('errors.generic'))
  } finally {
    loading.value = false
  }
}
watch(() => route.params.id, load, { immediate: true })

const tone = computed(() => categoryTone(event.value?.category))
const html = computed(() => sanitizeHtml(event.value?.description ?? ''))
const audience = computed(() => {
  const ids = event.value?.group_ids ?? []
  if (!ids.length) return t('events.wholeWorkspace')
  return groups.value
    .filter((g) => ids.includes(g.id))
    .map((g) => g.name)
    .join(', ')
})
const repeat = computed(() =>
  series.value
    ? describeWeekly(series.value.weekdays, series.value.interval_weeks, weekdayNames(locale.value), t)
    : null,
)

async function restore() {
  if (!event.value) return
  try {
    await api.updateEvent(event.value.id, { status: 'scheduled' })
    toast.success(t('events.restored'))
    await load()
  } catch (e) {
    toast.error(t(errorKey(e)))
  }
}
</script>

<template>
  <LoadingBlock v-if="loading" />
  <EmptyState v-else-if="!event || !workspaces.current" icon="bi-calendar-x" :title="t('events.notFound')" />

  <article v-else :class="`tone-${tone}`">
    <RouterLink
      :to="{ name: 'events', params: { slug: workspaces.current.slug } }"
      class="btn btn-link px-0 mb-2"
    >
      <i class="bi bi-arrow-left me-1" aria-hidden="true"></i>{{ t('nav.events') }}
    </RouterLink>

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

    <div class="row g-4 mt-1">
      <div class="col-lg-7 order-2 order-lg-1">
        <!-- eslint-disable-next-line vue/no-v-html -- sanitised with DOMPurify (CLAUDE.md rule 10) -->
        <div v-if="html" class="bw-description" v-html="html"></div>
        <p v-else class="text-muted">{{ t('events.noDescription') }}</p>
      </div>

      <aside class="col-lg-5 order-1 order-lg-2">
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
              <a
                v-if="event.location_url"
                :href="event.location_url"
                target="_blank"
                rel="noopener noreferrer"
                >{{ event.location }}</a
              >
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

        <div v-if="workspaces.isTrainer" class="d-flex flex-wrap gap-2 mt-3">
          <RouterLink
            :to="{ name: 'event-edit', params: { slug: workspaces.current.slug, id: event.id } }"
            class="btn btn-primary"
          >
            <i class="bi bi-pencil me-1" aria-hidden="true"></i>{{ t('events.edit') }}
          </RouterLink>
          <button
            v-if="event.status === 'scheduled'"
            type="button"
            class="btn btn-outline-danger"
            @click="cancelOpen = true"
          >
            {{ t('events.cancelEvent') }}
          </button>
          <button v-else type="button" class="btn btn-outline-light" @click="restore">
            {{ t('events.restore') }}
          </button>
        </div>
      </aside>
    </div>

    <CancelEventDialog v-if="cancelOpen" v-model:open="cancelOpen" :event="event" @cancelled="load" />
  </article>
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

.bw-description :deep(p) {
  line-height: 1.65;
}
</style>
