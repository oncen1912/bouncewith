<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { Group } from '@/features/members/types'
import type { EventFormValues } from '../types'

const v = defineModel<EventFormValues>({ required: true })
defineProps<{ groups: Group[] }>()
const { t } = useI18n()

const toggle = (id: string) =>
  (v.value.groupIds = v.value.groupIds.includes(id)
    ? v.value.groupIds.filter((g) => g !== id)
    : [...v.value.groupIds, id])
</script>

<template>
  <div class="d-grid gap-3">
    <fieldset>
      <legend class="form-label fs-6">{{ t('events.audience') }}</legend>
      <div class="d-flex flex-wrap gap-2">
        <button
          type="button"
          class="bw-pill"
          :aria-pressed="v.groupIds.length === 0"
          @click="v.groupIds = []"
        >
          {{ t('events.wholeWorkspace') }}
        </button>
        <button
          v-for="g in groups"
          :key="g.id"
          type="button"
          class="bw-pill"
          :aria-pressed="v.groupIds.includes(g.id)"
          @click="toggle(g.id)"
        >
          {{ g.name }}
        </button>
      </div>
      <p class="form-text mb-0 mt-2">{{ t('events.audienceHelp') }}</p>
    </fieldset>
    <fieldset>
      <legend class="form-label fs-6">{{ t('events.visibility') }}</legend>
      <div class="form-check">
        <input
          id="vis-members"
          v-model="v.visibility"
          class="form-check-input"
          type="radio"
          value="members"
        />
        <label class="form-check-label" for="vis-members">{{ t('events.visibilityMembers') }}</label>
      </div>
      <div class="form-check">
        <input id="vis-public" v-model="v.visibility" class="form-check-input" type="radio" value="public" />
        <label class="form-check-label" for="vis-public">{{ t('events.visibilityPublic') }}</label>
      </div>
    </fieldset>
  </div>
</template>
