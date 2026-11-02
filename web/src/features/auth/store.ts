import { defineStore } from 'pinia'
import { computed, ref, shallowRef } from 'vue'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '@/app/supabase'
import { setLocale } from '@/app/i18n'
import { isSupportedLocale } from '@/app/locale'
import * as api from './api'
import type { Profile, ProfilePatch } from './types'

export const useAuthStore = defineStore('auth', () => {
  const session = shallowRef<Session | null>(null)
  const profile = ref<Profile | null>(null)
  let ready: Promise<void> | null = null

  const user = computed(() => session.value?.user ?? null)
  const isAuthenticated = computed(() => !!session.value)

  async function loadProfile() {
    const id = user.value?.id
    if (!id) return
    profile.value = await api.fetchProfile(id)
    if (isSupportedLocale(profile.value?.locale)) setLocale(profile.value.locale)
  }

  /** Restores the session once; the router awaits this before its first guard check. */
  function init() {
    ready ??= (async () => {
      const { data } = await supabase.auth.getSession()
      session.value = data.session
      if (data.session) await loadProfile().catch(() => undefined)

      supabase.auth.onAuthStateChange((_event, next) => {
        const userChanged = next?.user.id !== session.value?.user.id
        session.value = next
        if (!next) profile.value = null
        // Supabase advises against awaiting other client calls inside this callback
        else if (userChanged || !profile.value) setTimeout(() => void loadProfile().catch(() => undefined))
      })
    })()
    return ready
  }

  async function saveProfile(patch: ProfilePatch) {
    if (!user.value) return
    profile.value = await api.updateProfile(user.value.id, patch)
    if (isSupportedLocale(profile.value.locale)) setLocale(profile.value.locale)
  }

  async function signOut() {
    await api.signOut()
    session.value = null
    profile.value = null
  }

  return { session, profile, user, isAuthenticated, init, loadProfile, saveProfile, signOut }
})
