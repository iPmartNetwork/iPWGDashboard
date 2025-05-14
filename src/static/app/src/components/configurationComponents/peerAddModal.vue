<template>
  <div class="modal fade" id="addPeerModal" tabindex="-1" aria-labelledby="addPeerModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="addPeerModalLabel">
            <i class="bi bi-person-plus-fill me-2"></i>
            <LocaleText t="Add New Peer(s)"></LocaleText>
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="submitAddPeerForm">
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="peerName" class="form-label"><LocaleText t="Peer Name (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="peerName" v-model="newPeer.name" :placeholder="GetLocale('e.g., My Phone')">
              </div>
              <div class="col-md-6 mb-3">
                <label for="peerPublicKey" class="form-label"><LocaleText t="Public Key"></LocaleText> <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="peerPublicKey" v-model="newPeer.publicKey" required :placeholder="GetLocale('WireGuard Public Key')">
                <!-- Add validation feedback if needed -->
              </div>
            </div>

            <div class="mb-3">
              <label for="peerAllowedIPs" class="form-label"><LocaleText t="Allowed IPs"></LocaleText> <span class="text-danger">*</span></label>
              <input type="text" class="form-control" id="peerAllowedIPs" v-model="newPeer.allowedIPs" required :placeholder="GetLocale('e.g., 10.0.0.2/32, fd00::2/128')">
              <div class="form-text"><LocaleText t="Comma-separated list of IPs."></LocaleText></div>
            </div>

            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="peerPresharedKey" class="form-label"><LocaleText t="Preshared Key (Optional)"></LocaleText></label>
                <div class="input-group">
                  <input :type="showPSK ? 'text' : 'password'" class="form-control" id="peerPresharedKey" v-model="newPeer.presharedKey" :placeholder="GetLocale('Auto-generate if empty')">
                  <button class="btn btn-outline-secondary" type="button" @click="showPSK = !showPSK">
                    <i class="bi" :class="showPSK ? 'bi-eye-slash' : 'bi-eye'"></i>
                  </button>
                </div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="peerPersistentKeepalive" class="form-label"><LocaleText t="Persistent Keepalive (Optional)"></LocaleText></label>
                <input type="number" class="form-control" id="peerPersistentKeepalive" v-model.number="newPeer.persistentKeepalive" placeholder="0" min="0">
                <div class="form-text"><LocaleText t="In seconds. 0 to disable."></LocaleText></div>
              </div>
            </div>
            
            <div class="mb-3">
                <label for="peerDNS" class="form-label"><LocaleText t="DNS Servers (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="peerDNS" v-model="newPeer.dns" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
                <div class="form-text"><LocaleText t="Comma-separated. Applied if client supports it."></LocaleText></div>
            </div>

            <div class="mb-3">
                <label for="peerEndpoint" class="form-label"><LocaleText t="Endpoint (Optional)"></LocaleText></label>
                <input type="text" class="form-control" id="peerEndpoint" v-model="newPeer.endpoint" :placeholder="GetLocale('host:port, leave empty if peer is client')">
            </div>

            <hr class="my-4">

            <div class="form-check mb-3">
              <input class="form-check-input" type="checkbox" id="addMultiplePeers" v-model="addMultiple">
              <label class="form-check-label" for="addMultiplePeers">
                <LocaleText t="Add Multiple Peers (Bulk)"></LocaleText>
              </label>
            </div>

            <div v-if="addMultiple" class="mb-3">
              <label for="bulkPeerConfig" class="form-label"><LocaleText t="Bulk Peer Configuration"></LocaleText></label>
              <textarea class="form-control" id="bulkPeerConfig" rows="5" v-model="bulkConfig" :placeholder="GetLocale('Enter peer configurations, one per line: name,publicKey,allowedIPs,presharedKey (optional fields can be empty)')"></textarea>
              <div class="form-text">
                <LocaleText t="Format:"></LocaleText> <code>name,publicKey,allowedIPs,[presharedKey],[dns_servers],[endpoint],[keepalive]</code><br/>
                <LocaleText t="Use commas as separators. Optional fields can be left empty but commas must be present."></LocaleText>
              </div>
            </div>

          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="bi bi-x-circle me-1"></i><LocaleText t="Cancel"></LocaleText>
          </button>
          <button type="submit" class="btn btn-primary" @click="submitAddPeerForm" :disabled="isSubmitting">
            <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
            <i v-else class="bi bi-check-circle me-1"></i>
            <LocaleText :t="addMultiple ? 'Add Peers' : 'Add Peer'"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { GetLocale } from "@/utilities/locale.js"; // فرض بر اینکه این مسیر صحیح است
import LocaleText from "@/components/text/localeText.vue"; // فرض بر اینکه این مسیر صحیح است

// این بخش اسکریپت فقط برای نمایش است و باید منطق کامل در آن پیاده‌سازی شود
const newPeer = reactive({
  name: '',
  publicKey: '',
  allowedIPs: '',
  presharedKey: '',
  persistentKeepalive: 0,
  dns: '',
  endpoint: ''
});

const addMultiple = ref(false);
const bulkConfig = ref('');
const showPSK = ref(false);
const isSubmitting = ref(false);

const submitAddPeerForm = () => {
  isSubmitting.value = true;
  // TODO: Implement form submission logic
  // Validate inputs
  // If addMultiple is true, parse bulkConfig
  // Else, use newPeer object
  // Send data to backend API
  console.log("Form submitted", addMultiple.value ? bulkConfig.value : newPeer);
  
  // Simulate API call
  setTimeout(() => {
    isSubmitting.value = false;
    // Potentially close modal and refresh peer list on success
    // bootstrap.Modal.getInstance(document.getElementById('addPeerModal')).hide();
  }, 1500);
};

// توابع GetLocale و LocaleText باید در دسترس باشند
// یا از طریق props یا import مستقیم
</script>

<style scoped>
/* Styles specific to this modal can go here */
.form-text {
  font-size: 0.875em;
}
.modal-footer .btn {
    min-width: 100px; /* Example for consistent button width */
}
</style>