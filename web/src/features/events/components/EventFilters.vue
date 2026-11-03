<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { Group } from '@/features/members/types'

export type EventsQuery = {
  view: 'list' | 'week' | 'month'
  past: boolean
  group: string | null
  category: string | null
}

const query = defineModel<EventsQuery>({ required: true })
defineProps<{ groups: Group[]; categories: string[] }>()
const { t } = useI18n()

const set = (patch: Partial<EventsQuery>) => (query.value = { ...query.value, ...patch })
</script>

<template>
  <div class="d-grid gap-2 mb-4">
    <div class="d-flex flex-wrap align-items-center gap-2">
      <div class="btn-group" role="group" :aria-label="t('events.view')">
        <template v-for="v in ['list', 'week', 'month'] as const" :key="v">
          <input
            :id="`view-${v}`"
            type="radio"
            class="btn-check"
            :checked="query.view === v"
            @change="set({ view: v })"
          />
          <label class="btn btn-outline-secondary btn-sm" :for="`view-${v}`">{{
            t(`events.views.${v}`)
          }}</label>
        </template>
      </div>
      <button
        v-if="query.view === 'list'"
        type="button"
        class="bw-pill ms-auto"
        :aria-pressed="query.past"
        @click="set({ past: !query.past })"
      >
        <i class="bi bi-clock-history me-1" aria-hidden="true"></i>{{ t('events.past') }}
      </button>
    </div>

    <div v-if="groups.length || categories.length" class="bw-filters">
      <div v-if="groups.length" class="d-flex flex-wrap align-items-center gap-2">
        <span class="bw-filter-label"
          ><i class="bi bi-people me-1" aria-hidden="true"></i>{{ t('events.group') }}</span
        >
        <button type="button" class="bw-pill" :aria-pressed="!query.group" @click="set({ group: null })">
          {{ t('events.all') }}
        </button>
        <button
          v-for="g in groups"
          :key="g.id"
          type="button"
          class="bw-pill"
          :aria-pressed="query.group === g.id"
          @click="set({ group: query.group === g.id ? null : g.id })"
        >
          {{ g.name }}
        </button>
      </div>
      <div v-if="categories.length" class="d-flex flex-wrap align-items-center gap-2">
        <span class="bw-filter-label"
          ><i class="bi bi-tag me-1" aria-hidden="true"></i>{{ t('events.category') }}</span
        >
        <button
          type="button"
          class="bw-pill"
          :aria-pressed="!query.category"
          @click="set({ category: null })"
        >
          {{ t('events.all') }}
        </button>
        <button
          v-for="c in categories"
          :key="c"
          type="button"
          class="bw-pill text-capitalize"
          :aria-pressed="query.category === c"
          @click="set({ category: query.category === c ? null : c })"
        >
          {{ c }}
        </button>
      </div>
    </div>
  </div>
</template>
