<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { weekdayNames } from '@bouncewith/shared'
import type { EventFormValues } from '../types'

const v = defineModel<EventFormValues>({ required: true })
defineProps<{ minUntil: string }>()
const { t, locale } = useI18n()

function toggle(day: number) {
  const has = v.value.weekdays.includes(day)
  if (has && v.value.weekdays.length === 1) return // at least one weekday
  v.value.weekdays = has ? v.value.weekdays.filter((d) => d !== day) : [...v.value.weekdays, day]
}
</script>

<template>
  <div class="d-grid gap-3">
    <fieldset>
      <legend class="form-label fs-6">{{ t('events.onDays') }}</legend>
      <div class="d-flex flex-wrap gap-2">
        <button
          v-for="(name, i) in weekdayNames(locale)"
          :key="i"
          type="button"
          class="bw-pill"
          :aria-pressed="v.weekdays.includes(i + 1)"
          @click="toggle(i + 1)"
        >
          {{ name }}
        </button>
      </div>
    </fieldset>
    <div class="row g-3">
      <div class="col-sm-6">
        <label for="ev-interval" class="form-label">{{ t('events.repeatEvery') }}</label>
        <select id="ev-interval" v-model.number="v.intervalWeeks" class="form-select">
          <option v-for="n in 4" :key="n" :value="n">
            {{ n === 1 ? t('events.everyWeekOption') : t('events.everyNWeeksOption', { n }) }}
          </option>
        </select>
      </div>
      <div class="col-sm-6">
        <label for="ev-until" class="form-label">{{ t('events.until') }}</label>
        <input
          id="ev-until"
          v-model="v.until"
          type="date"
          class="form-control"
          :min="minUntil"
          aria-describedby="ev-until-help"
        />
      </div>
    </div>
    <p id="ev-until-help" class="form-text m-0">{{ t('events.untilHelp') }}</p>
  </div>
</template>
