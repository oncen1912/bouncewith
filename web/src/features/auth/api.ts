import { supabase } from '@/app/supabase'
import type { Profile, ProfilePatch } from './types'

// explicit list: calendar_token is not readable through the API (see my_calendar_token())
const PROFILE_COLUMNS = 'id, full_name, avatar_url, locale, notify_email, notify_push, created_at'

/** Absolute URL that auth emails and OAuth send the user back to. */
function callbackUrl(next: string) {
  return `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`
}

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select(PROFILE_COLUMNS)
    .eq('id', userId)
    .maybeSingle()
  if (error) throw error
  return data
}

export async function updateProfile(userId: string, patch: ProfilePatch): Promise<Profile> {
  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', userId)
    .select(PROFILE_COLUMNS)
    .single()
  if (error) throw error
  return data
}

export async function sendMagicLink(email: string, next: string) {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: callbackUrl(next) },
  })
  if (error) throw error
}

export async function signInWithPassword(email: string, password: string) {
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
}

/** Returns true when the user must confirm their e-mail before a session exists. */
export async function signUp(email: string, password: string, fullName: string, next: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName }, emailRedirectTo: callbackUrl(next) },
  })
  if (error) throw error
  return !data.session
}

export async function signInWithGoogle(next: string) {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: callbackUrl(next) },
  })
  if (error) throw error
}

export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}
