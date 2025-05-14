<template>
  <div class="modal fade" id="editPeerSettingsModal" tabindex="-1" aria-labelledby="editPeerSettingsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="editPeerSettingsModalLabel">
            <i class="bi bi-gear-fill me-2"></i>
            <LocaleText t="Edit Peer Settings"></LocaleText>: <span class="fw-bold">{{ peerToEdit ? peerToEdit.name || peerToEdit.id : '' }}</span>
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body" v-if="editablePeer">
          <form @submit.prevent="submitPeerSettingsForm">
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="editPeerName" class="form-label"><LocaleText t="Peer Name (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="editPeerName" v-model="editablePeer.name" :placeholder="GetLocale('e.g., My Phone')">
              </div>
              <div class="col-md-6 mb-3">
                <label for="editPeerPublicKey" class="form-label"><LocaleText t="Public Key"></LocaleText></label>
                <input type="text" class="form-control" id="editPeerPublicKey" v-model="editablePeer.id" disabled readonly>
                <div class="form-text"><LocaleText t="Public key cannot be changed."></LocaleText></div>
              </div>
            </div>

            <div class="mb-3">
              <label for="editPeerAllowedIPs" class="form-label"><LocaleText t="Allowed IPs"></LocaleText> <span class="text-danger">*</span></label>
              <input type="text" class="form-control" id="editPeerAllowedIPs" v-model="editablePeer.allowed_ip" required :placeholder="GetLocale('e.g., 10.0.0.2/32, fd00::2/128')">
              <div class="form-text"><LocaleText t="Comma-separated list of IPs."></LocaleText></div>
            </div>

            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="editPeerPresharedKey" class="form-label"><LocaleText t="Preshared Key (Optional)"></LocaleText></label>
                <div class="input-group">
                  <input :type="showPSK ? 'text' : 'password'" class="form-control" id="editPeerPresharedKey" v-model="editablePeer.preshared_key" :placeholder="GetLocale('Leave empty to keep existing or auto-generate if none')">
                  <button class="btn btn-outline-secondary" type="button" @click="showPSK = !showPSK">
                    <i class="bi" :class="showPSK ? 'bi-eye-slash' : 'bi-eye'"></i>
                  </button>
                </div>
                 <div class="form-text"><LocaleText t="Leave empty to keep the current key. Enter a new key to update."></LocaleText></div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="editPeerPersistentKeepalive" class="form-label"><LocaleText t="Persistent Keepalive (Optional)"></LocaleText></label>
                <input type="number" class="form-control" id="editPeerPersistentKeepalive" v-model.number="editablePeer.persistent_keepalive" placeholder="0" min="0">
                <div class="form-text"><LocaleText t="In seconds. 0 to disable."></LocaleText></div>
              </div>
            </div>
            
            <div class="mb-3">
                <label for="editPeerDNS" class="form-label"><LocaleText t="DNS Servers (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="editPeerDNS" v-model="editablePeer.dns_servers" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
                <div class="form-text"><LocaleText t="Comma-separated. Applied if client supports it."></LocaleText></div>
            </div>

            <div class="mb-3">
                <label for="editPeerEndpoint" class="form-label"><LocaleText t="Endpoint (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="editPeerEndpoint" v-model="editablePeer.endpoint_allowed_ip" :placeholder="GetLocale('host:port, leave empty if peer is client')">
            </div>
            
            <!-- Additional settings specific to editing can be added here -->
            <!-- For example, a section for traffic limits if applicable -->
            <div v-if="editablePeer.hasOwnProperty('cumu_receive')"> <!-- Example condition -->
              <hr class="my-4">
              <h6 class="mb-3"><LocaleText t="Traffic Data (Read-only)"></LocaleText></h6>
              <div class="row">
                <div class="col-sm-4 mb-2">
                    <small class="text-muted d-block"><LocaleText t="Received"></LocaleText></small>
                    <strong>{{ (editablePeer.cumu_receive + editablePeer.total_receive).toFixed(2) }} GB</strong>
                </div>
                <div class="col-sm-4 mb-2">
                    <small class="text-muted d-block"><LocaleText t="Sent"></LocaleText></small>
                    <strong>{{ (editablePeer.cumu_sent + editablePeer.total_sent).toFixed(2) }} GB</strong>
                </div>
                 <div class="col-sm-4 mb-2">
                    <small class="text-muted d-block"><LocaleText t="Total"></LocaleText></small>
                    <strong>{{ (editablePeer.cumu_data + editablePeer.total_data).toFixed(2) }} GB</strong>
                </div>
              </div>
            </div>

          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="bi bi-x-circle me-1"></i><LocaleText t="Cancel"></LocaleText>
          </button>
          <button type="submit" class="btn btn-primary" @click="submitPeerSettingsForm" :disabled="isSubmitting">
            <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
            <i v-else class="bi bi-save me-1"></i>
            <LocaleText t="Save Changes"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, defineProps, toRefs } from 'vue';
import { GetLocale } from "@/utilities/locale.js"; // مسیر فرضی
import LocaleText from "@/components/text/localeText.vue"; // مسیر فرضی

const props = defineProps({
  peerToEdit: Object // همتایی که برای ویرایش پاس داده می‌شود
});

const { peerToEdit } = toRefs(props);
const editablePeer = reactive({}); // یک کپی از همتا برای ویرایش، تا از تغییر مستقیم prop جلوگیری شود

watch(peerToEdit, (newVal) => {
  if (newVal) {
    // ایجاد یک کپی عمیق یا سطحی بسته به نیاز
    // برای جلوگیری از جهش مستقیم prop
    Object.assign(editablePeer, JSON.parse(JSON.stringify(newVal)));
    // ممکن است نیاز به تبدیل برخی فیلدها باشد، مثلاً persistent_keepalive به عدد
    if (editablePeer.persistent_keepalive === undefined || editablePeer.persistent_keepalive === null || editablePeer.persistent_keepalive === "Disabled") {
        editablePeer.persistent_keepalive = 0;
    } else if (typeof editablePeer.persistent_keepalive === 'string') {
        editablePeer.persistent_keepalive = parseInt(editablePeer.persistent_keepalive) || 0;
    }
  } else {
    // پاک کردن فرم اگر همتایی برای ویرایش وجود ندارد
    Object.keys(editablePeer).forEach(key => delete editablePeer[key]);
  }
}, { immediate: true, deep: true });


const showPSK = ref(false);
const isSubmitting = ref(false);

const submitPeerSettingsForm = () => {
  isSubmitting.value = true;
  // TODO: Implement form submission logic
  // Validate inputs
  // Send updated editablePeer data to backend API
  console.log("Saving peer settings:", editablePeer);
  
  // Simulate API call
  setTimeout(() => {
    isSubmitting.value = false;
    // Potentially close modal and refresh peer list on success
    // bootstrap.Modal.getInstance(document.getElementById('editPeerSettingsModal')).hide();
    // Emit an event to parent component
    // emit('settingsSaved', editablePeer);
  }, 1500);
};

// توابع GetLocale و LocaleText باید در دسترس باشند
</script>

<style scoped>
/* Styles specific to this modal can go here */
.form-text {
  font-size: 0.875em;
}
.modal-footer .btn {
    min-width: 120px; /* Example for consistent button width */
}
input[readonly] {
  background-color: #e9ecef; /* Bootstrap's default disabled style */
  cursor: not-allowed;
}
</style>