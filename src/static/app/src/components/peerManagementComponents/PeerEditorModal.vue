<template>
  <div class="modal fade" id="peerEditorModal" tabindex="-1" aria-labelledby="peerEditorModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="peerEditorModalLabel">
            <i class="bi bi-person-plus me-2" v-if="!isEditing"></i>
            <i class="bi bi-person-gear me-2" v-if="isEditing"></i>
            <LocaleText :t="isEditing ? 'Edit Peer' : 'Add New Peer'"></LocaleText>
            <span v-if="configurationName" class="text-muted small ms-2">- <LocaleText t="for"></LocaleText> {{ configurationName }}</span>
          </h5>
          <button type="button" class="btn-close" @click="closeModal" aria-label="Close"></button>
        </div>
        <div class="modal-body" v-if="editablePeer">
          <form @submit.prevent="savePeerDetails">
            <!-- Peer Name -->
            <div class="mb-3">
              <label for="peerName" class="form-label"><LocaleText t="Peer Name (Optional)"></LocaleText></label>
              <input type="text" class="form-control" id="peerName" v-model="editablePeer.name" :placeholder="GetLocale('e.g., MyPhone or JohnDoeLaptop')">
              <div class="form-text"><LocaleText t="A descriptive name for this peer."></LocaleText></div>
            </div>

            <!-- Keys: PublicKey, PrivateKey, PresharedKey -->
            <div class="row">
              <div class="col-md-12 mb-3">
                <label for="peerPublicKey" class="form-label"><LocaleText t="Public Key"></LocaleText> <span class="text-danger">*</span></label>
                <div class="input-group">
                  <input type="text" class="form-control" id="peerPublicKey" v-model="editablePeer.id" required :readonly="isEditing && originalPeerPublicKey" :placeholder="GetLocale('Leave empty to auto-generate if Private Key is also empty/generated')">
                   <button v-if="!isEditing || !originalPeerPublicKey" class="btn btn-outline-secondary" type="button" @click="generatePeerKeyPair" :title="GetLocale('Generate New Key Pair')">
                    <i class="bi bi-arrow-repeat"></i> <LocaleText t="Generate"></LocaleText>
                  </button>
                </div>
                 <div class="form-text" v-if="isEditing && originalPeerPublicKey"><LocaleText t="Public Key cannot be changed after creation."></LocaleText></div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="peerPrivateKey" class="form-label"><LocaleText t="Private Key (Optional)"></LocaleText></label>
                <div class="input-group">
                    <input :type="showPrivateKey ? 'text' : 'password'" class="form-control" id="peerPrivateKey" v-model="editablePeer.private_key" :placeholder="GetLocale('Leave empty to auto-generate')">
                    <button class="btn btn-outline-secondary" type="button" @click="showPrivateKey = !showPrivateKey">
                        <i class="bi" :class="showPrivateKey ? 'bi-eye-slash' : 'bi-eye'"></i>
                    </button>
                </div>
                <div class="form-text"><LocaleText t="Client's private key. If provided with empty Public Key, Public Key will be derived. If both empty, new pair generated."></LocaleText></div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="peerPresharedKey" class="form-label"><LocaleText t="Preshared Key (Optional)"></LocaleText></label>
                 <div class="input-group">
                    <input :type="showPresharedKey ? 'text' : 'password'" class="form-control" id="peerPresharedKey" v-model="editablePeer.preshared_key" :placeholder="GetLocale('Leave empty or click Generate')">
                    <button class="btn btn-outline-secondary" type="button" @click="showPresharedKey = !showPresharedKey">
                        <i class="bi" :class="showPresharedKey ? 'bi-eye-slash' : 'bi-eye'"></i>
                    </button>
                    <button class="btn btn-outline-secondary" type="button" @click="generatePresharedKey" :title="GetLocale('Generate Preshared Key')">
                        <i class="bi bi-shield-lock"></i> <LocaleText t="Generate"></LocaleText>
                    </button>
                </div>
                <div class="form-text"><LocaleText t="Extra layer of security. Recommended."></LocaleText></div>
              </div>
            </div>

            <!-- Network Settings -->
            <h6 class="mt-3 mb-3 text-primary"><LocaleText t="Network Settings"></LocaleText></h6>
            <div class="mb-3">
              <label for="peerAllowedIPs" class="form-label"><LocaleText t="Allowed IPs"></LocaleText> <span class="text-danger">*</span></label>
              <input type="text" class="form-control" id="peerAllowedIPs" v-model="editablePeer.allowed_ip" required :placeholder="GetLocale('e.g., 10.0.0.2/32 or auto-assign')">
              <div class="form-text">
                <LocaleText t="IP addresses assigned to this peer within the VPN. Comma-separated."></LocaleText>
                <span v-if="!isEditing"> <LocaleText t="Can be auto-assigned by server if left empty (not implemented in this modal yet)."></LocaleText></span>
              </div>
            </div>
             <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="peerDNS" class="form-label"><LocaleText t="DNS Servers (Optional)"></LocaleText></label>
                    <input type="text" class="form-control" id="peerDNS" v-model="editablePeer.DNS" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
                    <div class="form-text"><LocaleText t="Overrides interface DNS for this peer. Comma-separated."></LocaleText></div>
                </div>
                <div class="col-md-6 mb-3">
                    <label for="peerEndpointAllowedIPs" class="form-label"><LocaleText t="Endpoint Allowed IPs (Optional)"></LocaleText></label>
                    <input type="text" class="form-control" id="peerEndpointAllowedIPs" v-model="editablePeer.endpoint_allowed_ip" :placeholder="GetLocale('Default: 0.0.0.0/0, ::/0')">
                    <div class="form-text"><LocaleText t="Usually for client config. Defines what traffic is routed through the VPN from client side."></LocaleText></div>
                </div>
            </div>
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="peerMTU" class="form-label"><LocaleText t="MTU (Optional)"></LocaleText></label>
                <input type="number" class="form-control" id="peerMTU" v-model.number="editablePeer.mtu" :placeholder="GetLocale('e.g., 1420, inherits server default if empty')">
              </div>
              <div class="col-md-6 mb-3">
                <label for="peerKeepalive" class="form-label"><LocaleText t="Persistent Keepalive (Optional)"></LocaleText></label>
                <input type="number" class="form-control" id="peerKeepalive" v-model.number="editablePeer.keepalive" :placeholder="GetLocale('e.g., 25, inherits server default if empty')">
                <div class="form-text"><LocaleText t="In seconds. 0 to disable."></LocaleText></div>
              </div>
            </div>
            <!-- TODO: Add fields for AmneziaWG specific settings if protocol is awg -->
            <div v-if="editablePeer.protocol === 'awg'" class="mt-3 border-top pt-3">
                 <h6 class="mb-3 text-info"><LocaleText t="AmneziaWG Advanced Security"></LocaleText></h6>
                 <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" role="switch" id="peerAdvancedSecurity" 
                           v-model="editablePeer.advanced_security_bool">
                    <label class="form-check-label" for="peerAdvancedSecurity"><LocaleText t="Enable Advanced Security Features"></LocaleText></label>
                </div>
            </div>

          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="closeModal">
            <i class="bi bi-x-circle me-1"></i><LocaleText t="Cancel"></LocaleText>
          </button>
          <button type="submit" class="btn btn-primary" @click="savePeerDetails" :disabled="isSaving">
            <span v-if="isSaving" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
            <i v-else class="bi bi-check-circle me-1"></i>
            <LocaleText :t="isEditing ? 'Save Changes' : 'Add Peer'"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, defineProps, defineEmits, onMounted } from 'vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import { Modal as BootstrapModal } from 'bootstrap';
// import { useToast } from 'vue-toastification';

// const toast = useToast();
let modalInstance = null;

const props = defineProps({
  configurationName: {
    type: String,
    required: true
  },
  peerToEdit: Object, // Peer object for editing
  protocol: String, // 'wg' or 'awg'
});

const emit = defineEmits(['peerSaved', 'modalClosed']);

const defaultPeerStructure = () => ({
  id: '', // PublicKey
  private_key: '',
  preshared_key: '',
  name: '',
  allowed_ip: '', // Server-side allowed IPs for this peer
  DNS: '',
  endpoint_allowed_ip: '0.0.0.0/0, ::/0', // Default for client's routing
  mtu: null, // Inherits if null
  keepalive: null, // Inherits if null
  // Amnezia specific
  protocol: props.protocol || 'wg',
  advanced_security: 'off', // Default for AmneziaWG
  advanced_security_bool: false, 
});

const editablePeer = ref(JSON.parse(JSON.stringify(defaultPeerStructure())));
const isEditing = ref(false);
const isSaving = ref(false);
const showPrivateKey = ref(false);
const showPresharedKey = ref(false);
const originalPeerPublicKey = ref(''); // To track if PublicKey was initially set (for readonly logic)

watch(() => props.peerToEdit, (newVal) => {
  editablePeer.value.protocol = props.protocol || 'wg'; // Ensure protocol is set
  if (newVal && newVal.id) {
    isEditing.value = true;
    originalPeerPublicKey.value = newVal.id; // Store original public key
    // Merge with default structure to ensure all fields are present
    const base = JSON.parse(JSON.stringify(defaultPeerStructure()));
    editablePeer.value = { 
        ...base, 
        ...JSON.parse(JSON.stringify(newVal)),
        protocol: props.protocol || newVal.protocol || 'wg' // Prioritize props.protocol
    };
    if (editablePeer.value.protocol === 'awg') {
        editablePeer.value.advanced_security_bool = editablePeer.value.advanced_security === 'on';
    }
  } else {
    isEditing.value = false;
    originalPeerPublicKey.value = '';
    editablePeer.value = JSON.parse(JSON.stringify(defaultPeerStructure()));
    editablePeer.value.protocol = props.protocol || 'wg';
  }
  // Reset visibility toggles
  showPrivateKey.value = false;
  showPresharedKey.value = false;
}, { immediate: true, deep: true });


const generatePeerKeyPair = async () => {
  try {
    const response = await fetch('/api/generateKeyPair'); // Reuse existing API
    if (!response.ok) throw new Error(GetLocale('Failed to generate key pair from server.'));
    const keys = await response.json();
    if (keys.status && keys.data) {
      editablePeer.value.private_key = keys.data.privateKey;
      editablePeer.value.id = keys.data.publicKey; // id is PublicKey for peers
      // toast.success(GetLocale("New peer key pair generated."));
    } else {
      throw new Error(keys.message || GetLocale("Failed to parse key pair from server."));
    }
  } catch (error) {
    console.error("Error generating peer key pair:", error);
    // toast.error(error.message);
    alert(error.message);
  }
};

const generatePresharedKey = async () => {
  try {
    const response = await fetch('/api/generatePresharedKey'); // API endpoint from dashboard.py
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }
    const pskData = await response.json();
    if (pskData.status && pskData.data && pskData.data.presharedKey) {
      editablePeer.value.preshared_key = pskData.data.presharedKey;
      // toast.success(GetLocale("New preshared key generated."));
      console.log(GetLocale("New preshared key generated."));
    } else {
      throw new Error(pskData.message || GetLocale("Failed to parse preshared key from server."));
    }
  } catch (error) {
    console.error("Error generating preshared key:", error);
    // toast.error(GetLocale("Error generating preshared key: ") + error.message);
    alert(GetLocale("Error generating preshared key: ") + error.message);
  }
};


const savePeerDetails = async () => {
  isSaving.value = true;
  if (!editablePeer.value.id && !editablePeer.value.private_key) {
    // toast.error(GetLocale("Either Public Key or Private Key must be provided or generated."));
    alert(GetLocale("Either Public Key or Private Key must be provided or generated."));
    isSaving.value = false;
    return;
  }
  if (!editablePeer.value.allowed_ip) {
    // toast.error(GetLocale("Allowed IPs cannot be empty."));
     alert(GetLocale("Allowed IPs cannot be empty."));
    isSaving.value = false;
    return;
  }

  const payload = JSON.parse(JSON.stringify(editablePeer.value));
  
  // Handle AmneziaWG advanced_security boolean to string
  if (payload.protocol === 'awg') {
    payload.advanced_security = payload.advanced_security_bool ? 'on' : 'off';
    delete payload.advanced_security_bool;
  }


  let apiUrl;
  let method = 'POST';
  let body;

  if (isEditing.value) {
    apiUrl = `/api/updatePeerSettings/${props.configurationName}`;
    // API_updatePeerSettings expects a flat structure of the peer object
    // Ensure allowed_ip is a string as expected by updatePeer in backend Peer class
    if (Array.isArray(payload.allowed_ip)) {
        payload.allowed_ip = payload.allowed_ip.join(',');
    }
    body = JSON.stringify(payload);
  } else {
    apiUrl = `/api/addPeers/${props.configurationName}`;
    // API_addPeers for single add expects specific fields, and 'allowed_ips' as a list.
    const addPayload = {
        public_key: payload.id,
        private_key: payload.private_key,
        preshared_key: payload.preshared_key,
        name: payload.name,
        // Convert comma-separated string from form to list of strings for API
        allowed_ips: payload.allowed_ip ? payload.allowed_ip.split(',').map(ip => ip.trim()).filter(ip => ip) : [],
        DNS: payload.DNS,
        endpoint_allowed_ip: payload.endpoint_allowed_ip,
        mtu: payload.mtu === null || payload.mtu === '' ? undefined : Number(payload.mtu),
        keepalive: payload.keepalive === null || payload.keepalive === '' ? undefined : Number(payload.keepalive),
    };
    if (payload.protocol === 'awg') {
        addPayload.advanced_security = payload.advanced_security;
    }
    body = JSON.stringify(addPayload);
  }

  try {
    const response = await fetch(apiUrl, {
      method: method,
      headers: { 'Content-Type': 'application/json' },
      body: body
    });
    const result = await response.json();

    if (result.status) {
      // toast.success(GetLocale(isEditing.value ? "Peer updated successfully!" : "Peer added successfully!"));
      alert(GetLocale(isEditing.value ? "Peer updated successfully!" : "Peer added successfully!"));
      // For 'addPeers', result.data might be a list. If so, take the first element.
      // For 'updatePeerSettings', result.data is not explicitly returned by current backend, but status is true.
      emit('peerSaved', isEditing.value ? payload : (result.data && Array.isArray(result.data) ? result.data[0] : (result.data || payload) ));
      closeModal();
    } else {
      throw new Error(result.message || GetLocale("Failed to save peer details."));
    }
  } catch (error) {
    console.error("Error saving peer:", error);
    // toast.error(error.message);
    alert(error.message);
  } finally {
    isSaving.value = false;
  }
};

const closeModal = () => {
    if (modalInstance) {
        modalInstance.hide();
    }
    emit('modalClosed');
};

onMounted(() => {
    const modalElement = document.getElementById('peerEditorModal');
    if (modalElement) {
        modalInstance = new BootstrapModal(modalElement);
    }
});

defineExpose({
    show: () => { if(modalInstance) modalInstance.show(); },
    hide: () => { if(modalInstance) modalInstance.hide(); }
});

</script>

<style scoped>
.modal-body {
  max-height: 75vh;
}
</style>
