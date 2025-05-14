<template>
  <div class="container-fluid mt-md-4 mt-3 mb-5">
    <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 page-header">
      <h2 class="mb-2 mb-md-0 d-flex align-items-center">
        <router-link :to="{ name: 'ConfigurationsDashboard' }" class="btn btn-light btn-lg p-2 lh-1 rounded-circle shadow-sm me-3" :title="GetLocale('Back to Configurations')">
          <i class="bi bi-arrow-left fs-4"></i>
        </router-link>
        <span>
          <i class="bi bi-people-fill me-2"></i>
          <LocaleText t="Manage Peers for"></LocaleText>: <span class="text-primary fw-semibold">{{ configName }}</span>
          <span v-if="configuration && configuration.Protocol === 'awg'" class="badge bg-info-subtle text-info-emphasis rounded-pill ms-2 align-middle"><LocaleText t="AmneziaWG"></LocaleText></span>
        </span>
      </h2>
      <button class="btn btn-primary rounded-pill px-3 py-2" @click="openPeerEditor()">
        <i class="bi bi-person-plus-fill me-1"></i>
        <LocaleText t="Add New Peer"></LocaleText>
      </button>
    </div>

    <div v-if="isLoading" class="text-center my-5 py-5">
      <div class="spinner-border text-primary" style="width: 3.5rem; height: 3.5rem;" role="status">
        <span class="visually-hidden"><LocaleText t="Loading peers..."></LocaleText></span>
      </div>
      <p class="mt-3 fs-5 text-muted"><LocaleText t="Loading peers..."></LocaleText></p>
    </div>

    <div v-if="errorLoading" class="alert alert-danger shadow-sm">
      <h4 class="alert-heading"><i class="bi bi-exclamation-triangle-fill me-2"></i><LocaleText t="Error Loading Data"></LocaleText></h4>
      <p><LocaleText t="Could not load peer data for this configuration."></LocaleText></p>
      <hr>
      <p class="mb-0"><small>{{ errorLoadingMessage }}</small></p>
    </div>

    <div v-if="!isLoading && !errorLoading && configuration">
      <ul class="nav nav-tabs nav-fill mb-3">
        <li class="nav-item">
          <a class="nav-link py-3" :class="{ active: activeTab === 'active' }" @click="activeTab = 'active'" href="#" role="button">
            <i class="bi bi-person-check-fill me-2"></i> <LocaleText t="Active Peers"></LocaleText>
            <span class="badge rounded-pill bg-success-subtle text-success-emphasis ms-2">{{ activePeers.length }}</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link py-3" :class="{ active: activeTab === 'restricted' }" @click="activeTab = 'restricted'" href="#" role="button">
            <i class="bi bi-person-x-fill me-2"></i> <LocaleText t="Restricted Peers"></LocaleText>
            <span class="badge rounded-pill bg-warning-subtle text-warning-emphasis ms-2">{{ restrictedPeers.length }}</span>
          </a>
        </li>
      </ul>

      <div class="tab-content mt-4">
        <div class="tab-pane fade" :class="{ 'show active': activeTab === 'active' }">
          <PeerTable
            :peers="activePeers"
            :configName="configName"
            :protocol="configuration.Protocol"
            :isRestrictedList="false"
            @editPeer="openPeerEditor"
            @deletePeer="confirmDeletePeer"
            @togglePeerStatus="confirmTogglePeerStatus"
            @downloadPeerConfig="downloadPeerConfig"
            @showQrCode="showPeerQrCode"
            @refreshPeers="fetchPeerData"
          />
          <div v-if="activePeers.length === 0" class="alert alert-info mt-3 text-center">
            <i class="bi bi-info-circle me-2"></i>
            <LocaleText t="No active peers found for this configuration."></LocaleText>
          </div>
        </div>
        <div class="tab-pane fade" :class="{ 'show active': activeTab === 'restricted' }">
          <PeerTable
            :peers="restrictedPeers"
            :configName="configName"
            :protocol="configuration.Protocol"
            :isRestrictedList="true"
            @editPeer="openPeerEditor"
            @deletePeer="confirmDeletePeer"
            @togglePeerStatus="confirmTogglePeerStatus"
            @downloadPeerConfig="downloadPeerConfig"
            @showQrCode="showPeerQrCode"
            @refreshPeers="fetchPeerData"
          />
          <div v-if="restrictedPeers.length === 0" class="alert alert-info mt-3 text-center">
            <i class="bi bi-info-circle me-2"></i>
            <LocaleText t="No restricted peers found for this configuration."></LocaleText>
          </div>
        </div>
      </div>
    </div>
    <div v-else-if="!isLoading && !errorLoading && !configuration" class="alert alert-warning shadow-sm text-center">
        <i class="bi bi-exclamation-circle-fill me-2"></i>
        <LocaleText t="Configuration data could not be loaded or does not exist."></LocaleText>
    </div>


    <PeerEditorModal
      ref="peerEditorModalRef"
      :configurationName="configName"
      :peerToEdit="selectedPeerForEdit"
      :protocol="configuration ? configuration.Protocol : 'wg'"
      @peerSaved="handlePeerSaved"
      @modalClosed="selectedPeerForEdit = null"
    />

    <ConfirmModal ref="deleteConfirmModalRef" modalId="deletePeerConfirmModal" :title="GetLocale('Confirm Deletion')" @confirmed="executeDeletePeer" confirmButtonClass="btn-danger">
        <p><LocaleText t="Are you sure you want to delete peer:"></LocaleText> <strong v-if="peerToAction" class="text-danger">{{ peerToAction.name || peerToAction.id }}</strong>?</p>
        <p class="text-danger"><i class="bi bi-exclamation-triangle me-1"></i> <LocaleText t="This action is irreversible."></LocaleText></p>
    </ConfirmModal>

    <ConfirmModal ref="toggleStatusConfirmModalRef" modalId="togglePeerStatusConfirmModal" :title="GetLocale('Confirm Action')" @confirmed="executeTogglePeerStatus" :confirmButtonClass="peerToAction && peerToAction.isRestricted ? 'btn-success' : 'btn-warning'">
        <p v-if="peerToAction">
            <LocaleText :t="`Are you sure you want to ${peerToAction.isRestricted ? 'allow access for' : 'restrict'} peer:`"></LocaleText>
            <strong :class="peerToAction.isRestricted ? 'text-success' : 'text-warning'">{{ peerToAction.name || peerToAction.id }}</strong>?
        </p>
    </ConfirmModal>
    
    <QrCodeModal ref="qrCodeModalRef" />

  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import PeerEditorModal from '@/components/peerManagementComponents/PeerEditorModal.vue';
import PeerTable from '@/components/peerManagementComponents/PeerTable.vue';
import ConfirmModal from '@/components/shared/ConfirmModal.vue';
import QrCodeModal from '@/components/shared/QrCodeModal.vue';
// import { useToast } from 'vue-toastification'; // Assuming this is set up globally or via provide/inject

// const toast = useToast();
const route = useRoute();

const configName = ref(route.params.configName);
const configuration = ref(null);
const activePeers = ref([]);
const restrictedPeers = ref([]);
const isLoading = ref(true);
const errorLoading = ref(false);
const errorLoadingMessage = ref('');
const activeTab = ref('active');

const peerEditorModalRef = ref(null);
const selectedPeerForEdit = ref(null);

const deleteConfirmModalRef = ref(null);
const toggleStatusConfirmModalRef = ref(null);
const qrCodeModalRef = ref(null);
const peerToAction = ref(null);


const fetchPeerData = async () => {
  isLoading.value = true;
  errorLoading.value = false;
  try {
    // Using the actual API endpoint from dashboard.py
    const response = await fetch(`/api/getWireguardConfigurationInfo?configurationName=${configName.value}`);
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if (result.status && result.data) {
      configuration.value = result.data.configurationInfo;
      activePeers.value = result.data.configurationPeers || [];
      restrictedPeers.value = result.data.configurationRestrictedPeers || [];
    } else {
      throw new Error(result.message || GetLocale("Invalid data format received for peer data."));
    }
  } catch (error) {
    console.error("Error fetching peer data:", error);
    errorLoading.value = true;
    errorLoadingMessage.value = error.message;
    // toast.error(GetLocale("Error fetching peer data: ") + error.message);
    configuration.value = null;
    activePeers.value = [];
    restrictedPeers.value = [];
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchPeerData();
});

watch(() => route.params.configName, (newConfigName) => {
  if (newConfigName && newConfigName !== configName.value) {
    configName.value = newConfigName;
    fetchPeerData();
    activeTab.value = 'active';
  }
});

const openPeerEditor = (peer = null) => {
  selectedPeerForEdit.value = peer ? { ...peer } : null;
  if (peerEditorModalRef.value) {
    peerEditorModalRef.value.show();
  }
};

const handlePeerSaved = () => {
  fetchPeerData();
  // toast.success(GetLocale("Peer information saved successfully."));
};

const confirmDeletePeer = (peer) => {
    peerToAction.value = peer;
    if (deleteConfirmModalRef.value) deleteConfirmModalRef.value.show();
};

const executeDeletePeer = async () => {
    if (!peerToAction.value) return;
    // API call to delete peer
    // Example: await fetch(`/api/deletePeers/${configName.value}`, { method: 'POST', body: JSON.stringify({ peers: [peerToAction.value.id] }) });
    // toast.success(GetLocale("Peer deleted: ") + (peerToAction.value.name || peerToAction.value.id));
    fetchPeerData(); // Refresh
};

const confirmTogglePeerStatus = (peer, isRestrictedCurrently) => {
    peerToAction.value = { ...peer, isRestricted: isRestrictedCurrently };
    if (toggleStatusConfirmModalRef.value) toggleStatusConfirmModalRef.value.show();
};

const executeTogglePeerStatus = async () => {
    if (!peerToAction.value) return;
    const action = peerToAction.value.isRestricted ? 'allowAccessPeers' : 'restrictPeers';
    // Example: await fetch(`/api/${action}/${configName.value}`, { method: 'POST', body: JSON.stringify({ peers: [peerToAction.value.id] }) });
    // toast.success(GetLocale(`Peer status updated for: `) + (peerToAction.value.name || peerToAction.value.id));
    fetchPeerData(); // Refresh
};

const downloadPeerConfig = async (peer) => {
    // Example: const response = await fetch(`/api/downloadPeer/${configName.value}?id=${peer.id}`);
    // ... handle file download
    // toast.info(GetLocale("Downloading config for: ") + (peer.name || peer.id));
};

const showPeerQrCode = (peer) => {
    if (qrCodeModalRef.value) {
        // Assuming QrCodeModal can generate QR from peer config string or fetch it
        // Example: qrCodeModalRef.value.showWithConfig(peer.configString);
        // toast.info(GetLocale("Showing QR code for: ") + (peer.name || peer.id));
    }
};

</script>
<style scoped>
/* .page-header .btn-light rules removed as they are now global */

.nav-tabs .nav-link {
    color: var(--bs-emphasis-color);
    border: none;
    border-bottom: 3px solid transparent;
    border-radius: 0;
}
.nav-tabs .nav-link.active, .nav-tabs .nav-item.show .nav-link {
    color: var(--bs-primary);
    background-color: transparent;
    border-color: var(--bs-primary);
    font-weight: 600;
}
.nav-tabs .nav-link:hover:not(.active) {
    border-color: var(--bs-secondary-border-subtle);
}
</style>
