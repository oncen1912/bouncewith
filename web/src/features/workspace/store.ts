import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useAuthStore } from '@/features/auth/store'
import * as api from './api'
import type { MyWorkspace } from './types'

export const useWorkspaceStore = defineStore('workspace', () => {
  const auth = useAuthStore()
  const mine = ref<MyWorkspace[]>([])
  const loaded = ref(false)
  const currentSlug = ref<string | null>(null)
  let loading: Promise<void> | null = null

  const current = computed(() => mine.value.find((w) => w.slug === currentSlug.value) ?? null)

  function load(force = false) {
    if (loading && !force) return loading
    loading = (async () => {
      const id = auth.user?.id
      mine.value = id ? await api.listMyWorkspaces(id) : []
      loaded.value = true
    })()
    return loading
  }

  async function selectBySlug(slug: string | null) {
    currentSlug.value = slug
    if (slug) await load()
  }

  // a different user signed in: forget the previous user's workspaces
  watch(
    () => auth.user?.id,
    () => {
      mine.value = []
      loaded.value = false
      loading = null
    },
  )

  return { mine, loaded, current, currentSlug, load, selectBySlug }
})
