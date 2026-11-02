<script setup lang="ts">
import { onBeforeUnmount, ref, useId, watch } from 'vue'
import { useI18n } from 'vue-i18n'

// Native <dialog>: focus trap, Escape and inert background for free.
const open = defineModel<boolean>('open', { required: true })
defineProps<{ title: string }>()
const { t } = useI18n()
const el = ref<HTMLDialogElement>()
const titleId = useId()

watch(
  [open, el],
  ([isOpen, dialog]) => {
    if (!dialog) return
    if (isOpen && !dialog.open) dialog.showModal()
    if (!isOpen && dialog.open) dialog.close()
  },
  { immediate: true },
)

onBeforeUnmount(() => el.value?.open && el.value.close())
</script>

<template>
  <dialog ref="el" class="bw-dialog" :aria-labelledby="titleId" @close="open = false">
    <div class="d-flex align-items-center mb-3">
      <h2 :id="titleId" class="h5 m-0 flex-grow-1">{{ title }}</h2>
      <button
        type="button"
        class="btn btn-link text-body p-0 bw-close"
        :aria-label="t('common.close')"
        @click="open = false"
      >
        <i class="bi bi-x-lg" aria-hidden="true"></i>
      </button>
    </div>
    <slot />
    <div v-if="$slots.footer" class="d-flex gap-2 justify-content-end mt-4">
      <slot name="footer" />
    </div>
  </dialog>
</template>

<style scoped>
.bw-dialog {
  width: min(520px, calc(100vw - 2rem));
  max-height: calc(100dvh - 2rem);
  padding: 1.25rem;
  color: var(--bw-text);
  background: var(--bw-bg-3);
  border: 1px solid var(--bw-border);
  border-radius: var(--bw-radius-lg);
}

.bw-dialog::backdrop {
  background: rgb(0 0 0 / 65%);
}

.bw-close {
  min-width: 44px;
}
</style>
