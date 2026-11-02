<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import * as api from '../api'
import { authErrorKey } from '../errors'

const props = defineProps<{ next: string }>()
const { t } = useI18n()
const router = useRouter()
const mode = ref<'signin' | 'signup'>('signin')
const fullName = ref('')
const email = ref('')
const password = ref('')
const busy = ref(false)

async function submit() {
  busy.value = true
  try {
    if (mode.value === 'signin') {
      await api.signInWithPassword(email.value.trim(), password.value)
      await router.replace(props.next)
      return
    }
    const mustConfirm = await api.signUp(
      email.value.trim(),
      password.value,
      fullName.value.trim(),
      props.next,
    )
    if (mustConfirm) toast.success(t('auth.confirmEmail', { email: email.value.trim() }))
    else await router.replace(props.next)
  } catch (e) {
    toast.error(t(authErrorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <form @submit.prevent="submit">
    <template v-if="mode === 'signup'">
      <label for="pw-name" class="form-label">{{ t('auth.fullName') }}</label>
      <input id="pw-name" v-model="fullName" class="form-control mb-3" autocomplete="name" required />
    </template>

    <label for="pw-email" class="form-label">{{ t('auth.email') }}</label>
    <input
      id="pw-email"
      v-model="email"
      type="email"
      class="form-control mb-3"
      autocomplete="email"
      required
    />

    <label for="pw-password" class="form-label">{{ t('auth.password') }}</label>
    <input
      id="pw-password"
      v-model="password"
      type="password"
      class="form-control mb-3"
      :autocomplete="mode === 'signin' ? 'current-password' : 'new-password'"
      minlength="8"
      required
    />

    <button type="submit" class="btn btn-primary w-100" :disabled="busy">
      <span v-if="busy" class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
      {{ mode === 'signin' ? t('auth.signIn') : t('auth.signUp') }}
    </button>

    <button
      type="button"
      class="btn btn-link w-100 mt-2"
      @click="mode = mode === 'signin' ? 'signup' : 'signin'"
    >
      {{ mode === 'signin' ? t('auth.noAccount') : t('auth.haveAccount') }}
    </button>
  </form>
</template>
