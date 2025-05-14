<template>
  <div class="modal fade" id="qrCodeModal" tabindex="-1" aria-labelledby="qrCodeModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="qrCodeModalLabel">
            <i class="bi bi-qr-code me-2"></i>
            {{ title || GetLocale('QR Code') }}
          </h5>
          <button type="button" class="btn-close" @click="closeModal" aria-label="Close"></button>
        </div>
        <div class="modal-body text-center">
          <div v-if="qrError" class="alert alert-danger">
            <LocaleText t="Error generating QR Code:"></LocaleText> {{ qrError }}
          </div>
          <canvas ref="qrCanvasRef" v-show="!qrError"></canvas>
          <p v-if="qrContent" class="mt-2 small text-muted">
            <LocaleText t="Scan this QR code with your WireGuard client application."></LocaleText>
          </p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="closeModal">
            <i class="bi bi-x-circle me-1"></i>
            <LocaleText t="Close"></LocaleText>
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
import QRCode from 'qrcode';

const props = defineProps({
  // qrContent: String, // Content to be encoded in QR, passed via show method
  // title: String      // Modal title, passed via show method
});

const emit = defineEmits(['closed']);

let modalInstance = null;
const qrCanvasRef = ref(null);
const qrContent = ref('');
const title = ref('');
const qrError = ref('');

onMounted(() => {
  const modalElement = document.getElementById('qrCodeModal');
  if (modalElement) {
    modalInstance = new BootstrapModal(modalElement);
  }
});

const generateQrCode = async (content) => {
  if (!qrCanvasRef.value || !content) {
    qrError.value = GetLocale("Canvas or content not available.");
    return;
  }
  qrError.value = '';
  try {
    await QRCode.toCanvas(qrCanvasRef.value, content, {
      errorCorrectionLevel: 'M', // Medium
      margin: 2,
      scale: 6, // Adjust scale for size. Default is 4. Larger scale = larger image.
      width: 280 // Explicit width, overrides scale if canvas is smaller
    });
  } catch (err) {
    console.error('Failed to generate QR Code:', err);
    qrError.value = err.message;
  }
};

const closeModal = () => {
  if (modalInstance) {
    modalInstance.hide();
  }
  qrContent.value = ''; // Clear content when closing
  title.value = '';
  qrError.value = '';
  emit('closed');
};

const show = (content, modalTitle = GetLocale('QR Code')) => {
  qrContent.value = content;
  title.value = modalTitle;
  if (modalInstance) {
    modalInstance.show();
    // Delay QR generation until modal is fully visible to ensure canvas is ready
    // Or use a watcher on qrContent if modal visibility is handled correctly
    // setTimeout(() => generateQrCode(content), 150); // Small delay
  }
   // Watch for modal shown event to generate QR
  const modalElement = document.getElementById('qrCodeModal');
  if (modalElement) {
    modalElement.addEventListener('shown.bs.modal', () => {
        if(qrContent.value) generateQrCode(qrContent.value);
    }, { once: true });
  }
};


defineExpose({
  show,
  hide: closeModal
});
</script>

<style scoped>
/* Ensure canvas is visible and centered */
canvas {
  display: block;
  margin-left: auto;
  margin-right: auto;
}
</style>
