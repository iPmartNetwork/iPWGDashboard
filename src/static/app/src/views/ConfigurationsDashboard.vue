<template>
  <div class="container-fluid mt-md-4 mt-3 mb-5">
    <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 page-header">
      <h2 class="mb-2 mb-md-0">
        <i class="bi bi-hdd-network-fill me-2"></i>
        <LocaleText t="WireGuard Configurations"></LocaleText>
      </h2>
      <div class="d-flex align-items-center gap-2">
         <div class="btn-group shadow-sm rounded-pill">
            <button class="btn btn-outline-secondary" :class="{'active': currentDisplayMode === 'Grid'}" @click="setDisplayMode('Grid')" :title="GetLocale('Grid View')">
                <i class="bi bi-grid-3x2-gap-fill"></i>
            </button>
            <button class="btn btn-outline-secondary" :class="{'active': currentDisplayMode === 'List'}" @click="setDisplayMode('List')" :title="GetLocale('List View')">
                <i class="bi bi-list-task"></i>
            </button>
        </div>
        <button class="btn btn-primary rounded-pill px-3 py-2 shadow-sm" @click="openConfigurationEditor()">
          <i class="bi bi-plus-circle-fill me-1"></i>
          <LocaleText t="Add New Configuration"></LocaleText>
        </button>
      </div>
    </div>

    <div v-if="isLoading" class="text-center my-5 py-5">
      <div class="spinner-border text-primary" style="width: 3.5rem; height: 3.5rem;" role="status">
        <span class="visually-hidden"><LocaleText t="Loading configurations..."></LocaleText></span>
      </div>
      <p class="mt-3 fs-5 text-muted"><LocaleText t="Loading configurations..."></LocaleText></p>
    </div>

    <div v-if="errorLoading" class="alert alert-danger shadow-sm">
      <h4 class="alert-heading"><i class="bi bi-exclamation-triangle-fill me-2"></i><LocaleText t="Error Loading Configurations"></LocaleText></h4>
      <p><LocaleText t="Could not load WireGuard configurations. Please check server logs or try again later."></LocaleText></p>
      <hr>
      <p class="mb-0"><small>{{ errorLoadingMessage }}</small></p>
    </div>

    <div v-if="!isLoading && !errorLoading && configurations.length === 0" class="alert alert-info text-center shadow-sm py-4">
      <i class="bi bi-info-circle-fill fs-1 d-block mb-2 text-info-emphasis"></i>
      <h4 class="alert-heading"><LocaleText t="No Configurations Found"></LocaleText></h4>
      <p class="mb-0"><LocaleText t="Click 'Add New Configuration' to get started."></LocaleText></p>
    </div>

    <div :class="currentDisplayMode === 'Grid' ? 'row row-cols-1 row-cols-md-2 row-cols-xl-3 g-4' : 'list-view-container'" v-if="!isLoading && !errorLoading && configurations.length > 0">
      <ConfigurationCard
        v-for="config in sortedConfigurations"
        :key="config.Name"
        :c="config"
        :display="currentDisplayMode"
        @edit="openConfigurationEditor"
        @delete="confirmDeleteConfiguration"
        @toggle="handleToggleConfigurationStatus"
        @refreshSingle="fetchSingleConfiguration"
        :class="currentDisplayMode === 'Grid' ? 'col' : 'mb-3'"
      />
    </div>

    <ConfigurationEditor
      ref="configEditorModalRef"
      :configuration-to-edit="selectedConfigurationForEdit"
      @configurationSaved="handleConfigurationSaved"
      @modalClosed="selectedConfigurationForEdit = null"
    />

    <ConfirmModal 
        ref="deleteConfirmModalRef" 
        modalId="deleteConfigConfirmationModal" 
        :title="GetLocale('Confirm Deletion')" 
        @confirmed="deleteConfiguration"
        confirmButtonClass="btn-danger"
        confirmButtonText="Delete"
        icon="bi-trash3-fill text-danger">
        <p><LocaleText t="Are you sure you want to delete the configuration:"></LocaleText> <strong v-if="configToDelete" class="text-danger">{{ configToDelete.Name }}</strong>?</p>
        <p class="text-danger"><i class="bi bi-exclamation-triangle me-1"></i> <LocaleText t="This action is irreversible and will remove the configuration file and all associated peers."></LocaleText></p>
    </ConfirmModal>

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import ConfigurationCard from '@/components/configurationListComponents/configurationCard.vue';
import ConfigurationEditor from '@/components/configurationListComponents/ConfigurationEditor.vue';
import ConfirmModal from '@/components/shared/ConfirmModal.vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import { Modal as BootstrapModal } from 'bootstrap'; // Keep for direct modal instance if needed, though ConfirmModal handles its own
// import { useToast } from 'vue-toastification';

// const toast = useToast();

const configurations = ref([]);
const isLoading = ref(true);
const errorLoading = ref(false);
const errorLoadingMessage = ref('');
const selectedConfigurationForEdit = ref(null);
const configToDelete = ref(null);
const configEditorModalRef = ref(null);
const deleteConfirmModalRef = ref(null); // Ref for ConfirmModal component
const currentDisplayMode = ref(localStorage.getItem('configurationDisplayMode') || 'Grid');


const fetchConfigurations = async () => {
  isLoading.value = true;
  errorLoading.value = false;
  try {
    const response = await fetch('/api/getWireguardConfigurations'); // Endpoint from dashboard.py
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    if (data.status && Array.isArray(data.data)) {
      configurations.value = data.data;
    } else {
      // If data.data is not an array but contains the configurations (older API version?)
      if (data.status && typeof data.data === 'object' && data.data !== null) {
         configurations.value = Object.values(data.data); // Convert object to array
      } else {
        throw new Error(data.message || GetLocale("Invalid data format received for configurations. Expected an array or object of configurations."));
      }
    }
  } catch (error) {
    console.error("Error fetching configurations:", error);
    errorLoading.value = true;
    errorLoadingMessage.value = error.message;
    // toast.error(GetLocale("Error fetching configurations: ") + error.message);
  } finally {
    isLoading.value = false;
  }
};

const fetchSingleConfiguration = async (configName) => {
    try {
        const response = await fetch(`/api/getWireguardConfigurationInfo?configurationName=${configName}`); // Use the detailed info endpoint
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || `Failed to fetch single configuration ${configName}`);
        }
        const result = await response.json();
        if (result.status && result.data && result.data.configurationInfo) {
            const index = configurations.value.findIndex(c => c.Name === configName);
            if (index !== -1) {
                // Merge or replace. Ensure all relevant fields from configurationInfo are updated.
                // The structure from getWireguardConfigurations and getWireguardConfigurationInfo might differ.
                // For simplicity, we replace. A merge might be better if structures are compatible.
                configurations.value[index] = result.data.configurationInfo;
            } else {
                configurations.value.push(result.data.configurationInfo);
            }
        } else {
            throw new Error(result.message || `Invalid data for ${configName}`);
        }
    } catch (error) {
        console.error(`Error fetching configuration ${configName}:`, error);
        // toast.error(GetLocale(`Error refreshing configuration ${configName}: `) + error.message);
    }
};


onMounted(() => {
  fetchConfigurations();
});

const sortedConfigurations = computed(() => {
  return [...configurations.value].sort((a, b) => (a.Name || '').localeCompare(b.Name || ''));
});

const openConfigurationEditor = (config = null) => {
  selectedConfigurationForEdit.value = config ? { ...config } : null;
  if (configEditorModalRef.value) {
    configEditorModalRef.value.show();
  }
};

const handleConfigurationSaved = (savedConfig) => {
  // toast.success(GetLocale("Configuration saved successfully: ") + savedConfig.Name);
  fetchConfigurations(); 
  selectedConfigurationForEdit.value = null;
};

const confirmDeleteConfiguration = (config) => {
  configToDelete.value = config;
  if (deleteConfirmModalRef.value) {
    deleteConfirmModalRef.value.show();
  }
};

const deleteConfiguration = async () => {
  if (!configToDelete.value) return;
  try {
    const response = await fetch('/api/deleteWireguardConfiguration', { // Endpoint from dashboard.py
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ConfigurationName: configToDelete.value.Name })
    });
    const result = await response.json();
    if (result.status) {
      // toast.success(GetLocale("Configuration deleted successfully: ") + configToDelete.value.Name);
      fetchConfigurations();
    } else {
      throw new Error(result.message || GetLocale("Failed to delete configuration."));
    }
  } catch (error) {
    console.error("Error deleting configuration:", error);
    // toast.error(GetLocale("Error deleting configuration: ") + error.message);
    alert(GetLocale("Error deleting configuration: ") + error.message); // Placeholder
  } finally {
    // ConfirmModal handles its own hiding
    configToDelete.value = null;
  }
};

const handleToggleConfigurationStatus = async (config, action) => {
  // The 'action' here is determined by the card (e.g., 'start', 'stop')
  // The backend API is /api/toggleWireguardConfiguration which handles both start/stop
  try {
    const response = await fetch(`/api/toggleWireguardConfiguration?configurationName=${config.Name}`); // Endpoint from dashboard.py
    const result = await response.json();
    if (result.status) {
      // toast.success(GetLocale(`Configuration status updated for: `) + config.Name);
      fetchSingleConfiguration(config.Name); // Refresh only this configuration
    } else {
      throw new Error(result.message || GetLocale(`Failed to toggle configuration status.`));
    }
  } catch (error) {
    console.error(`Error toggling configuration ${config.Name}:`, error);
    // toast.error(GetLocale(`Error toggling status for ${config.Name}: `) + error.message);
    alert(GetLocale(`Error toggling status for ${config.Name}: `) + error.message); // Placeholder
  }
};

const setDisplayMode = (mode) => {
    currentDisplayMode.value = mode;
    localStorage.setItem('configurationDisplayMode', mode);
};

</script>

<style scoped>
.page-header .btn-group .btn {
    padding-top: 0.4rem;
    padding-bottom: 0.4rem;
}
.list-view-container .col { /* Ensure cards in list view take full width if needed */
    width: 100%;
}
.btn-outline-secondary.active {
    background-color: var(--bs-secondary);
    color: var(--bs-white);
}
</style>
