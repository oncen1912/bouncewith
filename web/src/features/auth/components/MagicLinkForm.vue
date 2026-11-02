<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import * as api from '../api'
import { authErrorKey } from '../errors'

const props = defineProps<{ next: string }>()
const { t } = useI18n()
const email = ref('')
const busy = ref(false)
const sentTo = ref<string | null>(null)

async function submit() {
  busy.value = true
  try {
    await api.sendMagicLink(email.value.trim(), props.next)
    sentTo.value = email.value.trim()
  } catch (e) {
    toast.error(t(authErrorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div v-if="sentTo" class="text-center" role="status">
    <i class="bi bi-envelope-check fs-1 text-success" aria-hidden="true"></i>
    <p class="mt-2 mb-3">{{ t('auth.magicSent', { email: sentTo }) }}</p>
    <button type="button" class="btn btn-link" @click="sentTo = null">{{ t('auth.useOtherEmail') }}</button>
  </div>

  <form v-else @submit.prevent="submit">
    <label for="magic-email" class="form-label">{{ t('auth.email') }}</label>
    <input
      id="magic-email"
      v-model="email"
      type="email"
      class="form-control mb-3"
      autocomplete="email"
      required
    />
    <button type="submit" class="btn btn-primary w-100" :disabled="busy">
      <span v-if="busy" class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
      {{ t('auth.sendMagicLink') }}
    </button>
  </form>
</template>
