import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { DEFAULT_TIMEZONE, formatDate, formatTime, formatTimeRange, localDateKey } from '@bouncewith/shared'
import { useWorkspaceStore } from '@/features/workspace/store'
import { relativeDay } from './format'

/** Formatting in the workspace timezone and the UI language (CLAUDE.md rule 7). */
export function useEventFormat() {
  const { locale } = useI18n()
  const workspaces = useWorkspaceStore()
  const timeZone = computed(() => workspaces.current?.timezone ?? DEFAULT_TIMEZONE)

  return {
    timeZone,
    date: (iso: string) => formatDate(iso, locale.value, timeZone.value),
    time: (iso: string) => formatTime(iso, locale.value, timeZone.value),
    timeRange: (start: string, end: string) => formatTimeRange(start, end, locale.value, timeZone.value),
    relative: (iso: string) => relativeDay(iso, locale.value, timeZone.value),
    dayKey: (iso: string) => localDateKey(iso, timeZone.value),
  }
}
