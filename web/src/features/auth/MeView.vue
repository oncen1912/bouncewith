<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import DeleteAccountCard from './components/DeleteAccountCard.vue'
import MyWorkspacesCard from './components/MyWorkspacesCard.vue'
import LanguageSelect from './components/LanguageSelect.vue'
import { useAuthStore } from './store'
import type { AppLocale } from '@/app/locale'
import PageHeader from '@/components/PageHeader.vue'

const { t } = useI18n()
const router = useRouter()
const auth = useAuthStore()

const fullName = ref('')
const savingName = ref(false)

watch(
  () => auth.profile?.full_name,
  (name) => (fullName.value = name ?? ''),
  { immediate: true },
)

async function save(patch: Parameters<typeof auth.saveProfile>[0], okKey = 'me.saved') {
  try {
    await auth.saveProfile(patch)
    toast.success(t(okKey))
  } catch {
    toast.error(t('errors.generic'))
  }
}

async function saveName() {
  savingName.value = true
  await save({ full_name: fullName.value.trim() })
  savingName.value = false
}

const saveLocale = (locale: AppLocale) => save({ locale })

async function signOut() {
  try {
    await auth.signOut()
    await router.replace({ name: 'login' })
  } catch {
    toast.error(t('errors.generic'))
  }
}
</script>

<template>
  <PageHeader :title="t('me.title')" :eyebrow="t('me.eyebrow')" />

  <section class="card card-body mb-3" aria-labelledby="me-profile">
    <h2 id="me-profile" class="h5">{{ t('me.profile') }}</h2>
    <p class="small text-muted mb-3">{{ auth.user?.email }}</p>
    <form class="d-flex flex-column flex-sm-row gap-2" @submit.prevent="saveName">
      <label for="me-name" class="visually-hidden">{{ t('auth.fullName') }}</label>
      <input
        id="me-name"
        v-model="fullName"
        class="form-control"
        autocomplete="name"
        :placeholder="t('auth.fullName')"
        required
        maxlength="80"
      />
      <button type="submit" class="btn btn-primary flex-none" :disabled="savingName">
        {{ t('common.save') }}
      </button>
    </form>
  </section>

  <section class="card card-body mb-3" aria-labelledby="me-lang">
    <h2 id="me-lang" class="h5">{{ t('me.language') }}</h2>
    <LanguageSelect @change="saveLocale" />
  </section>

  <section v-if="auth.profile" class="card card-body mb-3" aria-labelledby="me-notify">
    <h2 id="me-notify" class="h5">{{ t('me.notifications') }}</h2>
    <div class="form-check form-switch mb-2">
      <input
        id="me-push"
        class="form-check-input"
        type="checkbox"
        role="switch"
        :checked="auth.profile.notify_push"
        @change="save({ notify_push: ($event.target as HTMLInputElement).checked })"
      />
      <label class="form-check-label" for="me-push">{{ t('me.notifyPush') }}</label>
    </div>
    <div class="form-check form-switch">
      <input
        id="me-email"
        class="form-check-input"
        type="checkbox"
        role="switch"
        :checked="auth.profile.notify_email"
        @change="save({ notify_email: ($event.target as HTMLInputElement).checked })"
      />
      <label class="form-check-label" for="me-email">{{ t('me.notifyEmail') }}</label>
    </div>
  </section>

  <MyWorkspacesCard />

  <button type="button" class="btn btn-outline-light w-100 mb-3" @click="signOut">
    <i class="bi bi-box-arrow-right me-2" aria-hidden="true"></i>{{ t('auth.signOut') }}
  </button>

  <DeleteAccountCard />
</template>
