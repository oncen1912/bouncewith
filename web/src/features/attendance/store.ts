import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from '@/features/auth/store'
import * as api from './api'
import type { Answer, Counts, MyAnswer } from './types'

/** My answers and the public counts for the events currently on screen. */
export const useAttendanceStore = defineStore('attendance', () => {
  const auth = useAuthStore()
  const mine = ref<Record<string, MyAnswer>>({})
  const counts = ref<Record<string, Counts>>({})

  async function load(eventIds: string[]) {
    const ids = [...new Set(eventIds)]
    if (!ids.length || !auth.user) return
    const [answers, rows] = await Promise.all([api.myAnswers(auth.user.id, ids), api.countsMany(ids)])
    for (const id of ids) {
      const a = answers.get(id)
      if (a) mine.value[id] = a
      else delete mine.value[id]
    }
    for (const c of rows) counts.value[c.event_id] = c
  }

  async function answer(eventId: string, value: Answer, reason?: string) {
    await api.rsvp(eventId, value, reason)
    mine.value[eventId] = { answer: value, reason: value === 'not_going' ? reason?.trim() || null : null }
    const [c] = await api.countsMany([eventId])
    if (c) counts.value[eventId] = c
  }

  return { mine, counts, load, answer }
})
