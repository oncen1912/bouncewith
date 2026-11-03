<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { supabase } from '@/app/supabase'
import BaseDialog from '@/components/BaseDialog.vue'

// Personal iCal feed (SPEC M2): a secret URL that calendar apps subscribe to.
const { t } = useI18n()
const token = ref<string | null>(null)
const confirmReset = ref(false)

const url = computed(() =>
  token.value ? `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/calendar/${token.value}.ics` : '',
)
const webcal = computed(() => url.value.replace(/^https?:/, 'webcal:'))
const google = computed(
  () => `https://calendar.google.com/calendar/r?cid=${encodeURIComponent(webcal.value)}`,
)

onMounted(async () => {
  const { data, error } = await supabase.rpc('my_calendar_token')
  if (!error) token.value = data
})

async function copy() {
  try {
    await navigator.clipboard.writeText(url.value)
    toast.success(t('settings.copied'))
  } catch {
    toast.error(t('errors.generic'))
  }
}

async function reset() {
  const { data, error } = await supabase.rpc('reset_calendar_token')
  if (error) return toast.error(t('errors.generic'))
  token.value = data
  confirmReset.value = false
  toast.success(t('me.calendarReset'))
}
</script>

<template>
  <section class="card card-body mb-3" aria-labelledby="me-cal">
    <h2 id="me-cal" class="h5">{{ t('me.calendarTitle') }}</h2>
    <p class="small text-muted">{{ t('me.calendarText') }}</p>
    <div v-if="token" class="d-flex flex-wrap gap-2">
      <a :href="webcal" class="btn btn-primary"
        ><i class="bi bi-calendar-plus me-1" aria-hidden="true"></i>{{ t('me.calendarSubscribe') }}</a
      >
      <a :href="google" target="_blank" rel="noopener noreferrer" class="btn btn-outline-light">
        <i class="bi bi-google me-1" aria-hidden="true"></i>{{ t('me.calendarGoogle') }}
      </a>
      <button type="button" class="btn btn-outline-light" @click="copy">
        <i class="bi bi-link-45deg me-1" aria-hidden="true"></i>{{ t('settings.copyLink') }}
      </button>
      <button type="button" class="btn btn-link text-danger" @click="confirmReset = true">
        {{ t('me.calendarResetButton') }}
      </button>
    </div>

    <BaseDialog v-model:open="confirmReset" :title="t('me.calendarResetButton')">
      <p class="mb-0">{{ t('me.calendarResetText') }}</p>
      <template #footer>
        <button type="button" class="btn btn-outline-secondary" @click="confirmReset = false">
          {{ t('common.cancel') }}
        </button>
        <button type="button" class="btn btn-danger" @click="reset">{{ t('me.calendarResetButton') }}</button>
      </template>
    </BaseDialog>
  </section>
</template>
