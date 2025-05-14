<template>
  <div class="modal fade" :id="modalId" tabindex="-1" :aria-labelledby="`${modalId}Label`" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" :id="`${modalId}Label`">
            <i :class="iconClass" class="me-2" v-if="iconClass"></i>
            {{ title }}
          </h5>
          <button type="button" class="btn-close" @click="closeModal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <slot>
            <p><LocaleText t="Are you sure you want to proceed with this action?"></LocaleText></p>
          </slot>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="closeModal">
            <i class="bi bi-x-circle me-1"></i>
            <LocaleText :t="cancelText"></LocaleText>
          </button>
          <button type="button" :class="`btn ${confirmButtonClass}`" @click="confirmAction">
            <i :class="confirmIconClass" class="me-1" v-if="confirmIconClass"></i>
            <LocaleText :t="confirmText"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineProps, defineEmits, onMounted, watch } from 'vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import { Modal as BootstrapModal } from 'bootstrap';

const props = defineProps({
  modalId: {
    type: String,
    required: true
  },
  title: {
    type: String,
    default: () => GetLocale('Confirm Action')
  },
  iconClass: { // e.g., 'bi bi-exclamation-triangle-fill text-warning'
    type: String,
    default: 'bi bi-question-circle-fill text-primary'
  },
  confirmText: {
    type: String,
    default: () => GetLocale('Confirm')
  },
  cancelText: {
    type: String,
    default: () => GetLocale('Cancel')
  },
  confirmButtonClass: {
    type: String,
    default: 'btn-primary' // e.g., btn-danger, btn-success
  },
  confirmIconClass: { // e.g., 'bi bi-check-circle'
      type: String,
      default: 'bi bi-check-circle'
  }
});

const emit = defineEmits(['confirmed', 'closed']);

let modalInstance = null;

onMounted(() => {
  const modalElement = document.getElementById(props.modalId);
  if (modalElement) {
    modalInstance = new BootstrapModal(modalElement);
  }
});

const closeModal = () => {
  if (modalInstance) {
    modalInstance.hide();
  }
  emit('closed');
};

const confirmAction = () => {
  emit('confirmed');
  closeModal(); // Close modal after confirmation by default
};

defineExpose({
  show: () => { if (modalInstance) modalInstance.show(); },
  hide: () => { if (modalInstance) modalInstance.hide(); }
});
</script>

<style scoped>
/* Add any specific styles for the confirm modal here */
</style>
