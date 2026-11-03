<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { Member } from '../types'

defineProps<{ member: Member }>()
const { t } = useI18n()
</script>

<template>
  <span class="d-block min-w-0">
    <span class="d-block fw-semibold text-truncate">{{ member.full_name || t('members.noName') }}</span>
    <span class="d-block small text-muted text-truncate">{{ member.email }}</span>
  </span>
</template>
