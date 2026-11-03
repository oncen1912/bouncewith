<script setup lang="ts">
import { useI18n } from 'vue-i18n'

// One big tap target per person: unmarked → present → absent → present …
defineProps<{ name: string; note?: string | null; present: boolean | null; busy?: boolean }>()
defineEmits<{ toggle: [] }>()
const { t } = useI18n()
</script>

<template>
  <button
    type="button"
    class="bw-checkin-row"
    :class="present === true ? 'is-present' : present === false ? 'is-absent' : ''"
    :aria-pressed="present === true"
    :disabled="busy"
    @click="$emit('toggle')"
  >
    <span class="bw-checkin-state" aria-hidden="true">
      <i v-if="present === true" class="bi bi-check-lg"></i>
      <i v-else-if="present === false" class="bi bi-x-lg"></i>
    </span>
    <span class="flex-grow-1 min-w-0 text-start">
      <span class="d-block fw-semibold text-truncate">{{ name }}</span>
      <span v-if="note" class="d-block small text-muted text-truncate">{{ note }}</span>
    </span>
    <span class="small" :class="present === true ? 'text-teal' : 'text-muted'">
      {{
        present === true
          ? t('attendance.present')
          : present === false
            ? t('attendance.absent')
            : t('attendance.unmarked')
      }}
    </span>
  </button>
</template>

<style scoped>
.bw-checkin-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  min-height: 60px;
  padding: 0.5rem 1rem;
  border: 1px solid var(--bw-border);
  border-radius: var(--bw-radius);
  background: var(--bw-bg-3);
  color: var(--bw-text);
  transition:
    background-color 0.12s,
    border-color 0.12s;
}

.bw-checkin-row:focus-visible {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}

.bw-checkin-state {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 2px solid rgb(255 255 255 / 25%);
  font-size: 1.1rem;
}

.is-present {
  border-color: color-mix(in srgb, var(--bw-teal) 50%, transparent);
  background: color-mix(in srgb, var(--bw-teal) 12%, var(--bw-bg-3));
}

.is-present .bw-checkin-state {
  border-color: var(--bw-teal);
  background: var(--bw-teal);
  color: #000;
}

.is-absent {
  opacity: 0.7;
}

.is-absent .bw-checkin-state {
  border-color: var(--bw-pink);
  color: var(--bw-pink);
}
</style>
