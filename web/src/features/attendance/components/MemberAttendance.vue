<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useEventFormat } from '@/features/events/useEventFormat'
import * as api from '../api'
import type { HistoryRow } from '../types'

// Last 90 days of one member, shown in the member dialog.
const props = defineProps<{ workspaceId: string; userId: string }>()
const { t } = useI18n()
const f = useEventFormat()
const rows = ref<HistoryRow[] | null>(null)

watch(
  () => props.userId,
  async (id) => (rows.value = await api.memberHistory(props.workspaceId, id).catch(() => [])),
  { immediate: true },
)
const present = computed(() => rows.value?.filter((r) => r.present === true).length ?? 0)
const recorded = computed(() => rows.value?.filter((r) => r.present !== null).length ?? 0)
const status = (r: HistoryRow) =>
  r.present === true ? 'present' : r.present === false ? 'absent' : 'unmarked'
</script>

<template>
  <section aria-labelledby="hist-title">
    <h3 id="hist-title" class="form-label fs-6">{{ t('attendance.history') }}</h3>
    <p v-if="rows === null" class="small text-muted">{{ t('common.loading') }}</p>
    <p v-else-if="!rows.length" class="small text-muted mb-0">{{ t('attendance.noHistory') }}</p>
    <template v-else>
      <p class="small mb-2">{{ t('attendance.rate', { present, recorded }) }}</p>
      <ul class="list-unstyled m-0 bw-history">
        <li v-for="r in rows" :key="r.event_id" class="d-flex gap-2 py-1">
          <span class="text-muted small flex-none" style="width: 5.5rem">{{ f.date(r.starts_at) }}</span>
          <span class="flex-grow-1 text-truncate small">{{ r.title }}</span>
          <span
            class="small"
            :class="{
              'text-teal': r.present === true,
              'text-pink': r.present === false,
              'text-muted': r.present === null,
            }"
          >
            {{ t(`attendance.${status(r)}`) }}
          </span>
        </li>
      </ul>
    </template>
  </section>
</template>

<style scoped>
.bw-history {
  max-height: 30dvh;
  overflow-y: auto;
}
</style>
