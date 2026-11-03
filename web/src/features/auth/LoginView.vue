<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { safeRedirect } from '@/app/redirect'
import BrandMark from '@/components/BrandMark.vue'
import MagicLinkForm from './components/MagicLinkForm.vue'
import PasswordForm from './components/PasswordForm.vue'
import LanguageSelect from './components/LanguageSelect.vue'
import * as api from './api'
import { authErrorKey } from './errors'

const { t } = useI18n()
const route = useRoute()
const next = computed(() => safeRedirect(route.query.redirect))
const method = ref<'magic' | 'password'>('magic')
const googleBusy = ref(false)

async function google() {
  googleBusy.value = true
  try {
    await api.signInWithGoogle(next.value)
  } catch (e) {
    toast.error(t(authErrorKey(e)))
    googleBusy.value = false
  }
}
</script>

<template>
  <main class="bw-login container py-5">
    <div class="text-center mb-4">
      <BrandMark :size="64" />
      <h1 class="section-title mt-3 mb-1">{{ t('auth.title') }}</h1>
      <p class="text-muted">{{ t('auth.subtitle') }}</p>
    </div>

    <div class="card card-body p-4">
      <button type="button" class="btn btn-outline-light w-100" :disabled="googleBusy" @click="google">
        <i class="bi bi-google me-2" aria-hidden="true"></i>{{ t('auth.google') }}
      </button>

      <div class="bw-or my-3 text-muted small" role="separator">{{ t('auth.or') }}</div>

      <div class="btn-group w-100 mb-3" role="group" :aria-label="t('auth.method')">
        <input id="m-magic" v-model="method" type="radio" class="btn-check" value="magic" />
        <label class="btn btn-outline-secondary" for="m-magic">{{ t('auth.magicLink') }}</label>
        <input id="m-password" v-model="method" type="radio" class="btn-check" value="password" />
        <label class="btn btn-outline-secondary" for="m-password">{{ t('auth.password') }}</label>
      </div>

      <MagicLinkForm v-if="method === 'magic'" :next="next" />
      <PasswordForm v-else :next="next" />
    </div>

    <div class="mt-4 mx-auto" style="max-width: 200px">
      <LanguageSelect />
    </div>
  </main>
</template>

<style scoped>
.bw-login {
  max-width: 440px;
}

.bw-or {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.bw-or::before,
.bw-or::after {
  content: '';
  flex: 1;
  border-top: 1px solid var(--bw-border);
}
</style>
