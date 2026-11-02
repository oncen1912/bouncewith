import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useAuthStore } from '@/features/auth/store'
import * as api from './api'
import { hasRole, type MyMembership, type Role } from './types'

export const useWorkspaceStore = defineStore('workspace', () => {
  const auth = useAuthStore()
  const memberships = ref<MyMembership[]>([])
  const loaded = ref(false)
  const currentSlug = ref<string | null>(null)
  let loading: Promise<void> | null = null

  const mine = computed(() => memberships.value.filter((m) => m.status === 'active'))
  const pending = computed(() => memberships.value.filter((m) => m.status === 'pending'))
  const current = computed(() => mine.value.find((w) => w.slug === currentSlug.value) ?? null)
  const currentPending = computed(() => pending.value.find((w) => w.slug === currentSlug.value) ?? null)
  const role = computed<Role | null>(() => current.value?.role ?? null)
  const isTrainer = computed(() => hasRole(role.value, 'trainer'))
  const isOwner = computed(() => hasRole(role.value, 'owner'))

  function load(force = false) {
    if (loading && !force) return loading
    loading = (async () => {
      memberships.value = auth.user ? await api.listMyMemberships() : []
      loaded.value = true
    })()
    loading.catch(() => (loading = null))
    return loading
  }

  async function selectBySlug(slug: string | null) {
    currentSlug.value = slug
    if (slug) await load()
  }

  /** Patch the cached copy after saving settings, so the shell (name, accent) updates at once. */
  function patchCurrent(patch: Partial<MyMembership>) {
    const ws = current.value
    if (ws) Object.assign(ws, patch)
  }

  // a different user signed in: forget the previous user's workspaces
  watch(
    () => auth.user?.id,
    () => {
      memberships.value = []
      loaded.value = false
      loading = null
    },
  )

  return {
    memberships,
    mine,
    pending,
    loaded,
    current,
    currentPending,
    currentSlug,
    role,
    isTrainer,
    isOwner,
    load,
    selectBySlug,
    patchCurrent,
  }
})
