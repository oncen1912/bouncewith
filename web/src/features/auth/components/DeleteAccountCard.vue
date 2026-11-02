<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { errorKey } from '@/app/errors'
import { supabase } from '@/app/supabase'
import BaseDialog from '@/components/BaseDialog.vue'
import { useWorkspaceStore } from '@/features/workspace/store'
import { useAuthStore } from '../store'

const { t } = useI18n()
const router = useRouter()
const auth = useAuthStore()
const workspaces = useWorkspaceStore()

const open = ref(false)
const confirmEmail = ref('')
const busy = ref(false)
const blockers = computed(() => workspaces.memberships.filter((m) => m.is_last_owner))
const matches = computed(() => confirmEmail.value.trim().toLowerCase() === auth.user?.email?.toLowerCase())

async function remove() {
  busy.value = true
  try {
    const { error } = await supabase.rpc('delete_my_account', { p_confirm_email: confirmEmail.value })
    if (error) throw error
    // the session belongs to a user that no longer exists: drop it locally only
    await supabase.auth.signOut({ scope: 'local' })
    toast.success(t('me.deleted'))
    await router.replace({ name: 'login' })
  } catch (e) {
    toast.error(t(errorKey(e)))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="card card-body mb-3 border-danger-subtle" aria-labelledby="me-delete">
    <h2 id="me-delete" class="h5">{{ t('me.deleteTitle') }}</h2>
    <p class="small text-muted">{{ t('me.deleteText') }}</p>
    <div v-if="blockers.length" class="alert alert-warning small mb-0" role="note">
      {{ t('me.deleteBlocked', { names: blockers.map((b) => b.name).join(', ') }) }}
    </div>
    <div v-else>
      <button type="button" class="btn btn-outline-danger" @click="open = true">
        {{ t('me.deleteTitle') }}
      </button>
    </div>

    <BaseDialog v-model:open="open" :title="t('me.deleteTitle')">
      <form id="delete-form" @submit.prevent="remove">
        <p>{{ t('me.deleteConfirm') }}</p>
        <label for="delete-email" class="form-label">{{
          t('me.deleteType', { email: auth.user?.email ?? '' })
        }}</label>
        <input
          id="delete-email"
          v-model="confirmEmail"
          type="email"
          class="form-control"
          autocomplete="off"
          required
        />
      </form>
      <template #footer>
        <button type="button" class="btn btn-outline-secondary" @click="open = false">
          {{ t('common.cancel') }}
        </button>
        <button type="submit" form="delete-form" class="btn btn-danger" :disabled="busy || !matches">
          {{ t('me.deleteForever') }}
        </button>
      </template>
    </BaseDialog>
  </section>
</template>
