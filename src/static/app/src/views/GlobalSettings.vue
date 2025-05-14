<template>
  <div class="container-xl mt-md-4 mt-3 mb-5">
    <div class="page-header mb-4">
      <h2 class="mb-0">
        <i class="bi bi-sliders2 me-2"></i>
        <LocaleText t="Global Settings"></LocaleText>
      </h2>
    </div>

    <div v-if="isLoading" class="text-center my-5 py-5">
      <div class="spinner-border text-primary" style="width: 3.5rem; height: 3.5rem;" role="status">
        <span class="visually-hidden"><LocaleText t="Loading settings..."></LocaleText></span>
      </div>
      <p class="mt-3 fs-5 text-muted"><LocaleText t="Loading settings..."></LocaleText></p>
    </div>

    <div v-if="errorLoading" class="alert alert-danger shadow-sm">
      <h4 class="alert-heading"><i class="bi bi-exclamation-triangle-fill me-2"></i><LocaleText t="Error Loading Settings"></LocaleText></h4>
      <p><LocaleText t="Could not load global settings. Please try again later."></LocaleText></p>
      <hr>
      <p class="mb-0"><small>{{ errorLoadingMessage }}</small></p>
    </div>

    <form @submit.prevent="saveSettings" v-if="!isLoading && !errorLoading && settings" class="d-flex flex-column gap-4">
      <!-- Server Settings -->
      <div class="card shadow-sm rounded-3">
        <div class="card-header bg-light-subtle">
          <h5 class="mb-0 py-1"><i class="bi bi-server me-2"></i><LocaleText t="Server Settings"></LocaleText></h5>
        </div>
        <div class="card-body p-4">
          <div class="row g-3">
            <div class="col-md-6">
              <label for="dashboard_username" class="form-label"><LocaleText t="Dashboard Username"></LocaleText></label>
              <input type="text" class="form-control" id="dashboard_username" v-model="settings.Server.dashboard_username">
            </div>
            <div class="col-md-6">
              <label for="dashboard_password" class="form-label"><LocaleText t="Dashboard Password"></LocaleText></label>
              <input type="password" class="form-control" id="dashboard_password" v-model="settings.Server.dashboard_password_input" :placeholder="GetLocale('Leave empty to keep current password')">
              <div class="form-text"><LocaleText t="Leave empty to keep the current password."></LocaleText></div>
            </div>
            <div class="col-md-6">
              <label for="dashboard_theme" class="form-label"><LocaleText t="Dashboard Theme"></LocaleText></label>
              <select class="form-select" id="dashboard_theme" v-model="settings.Server.dashboard_theme">
                <option value="auto"><LocaleText t="Auto (System Preference)"></LocaleText></option>
                <option value="light"><LocaleText t="Light Mode"></LocaleText></option>
                <option value="dark"><LocaleText t="Dark Mode"></LocaleText></option>
              </select>
            </div>
            <div class="col-md-6">
              <label for="dashboard_language" class="form-label"><LocaleText t="Dashboard Language"></LocaleText></label>
              <select class="form-select" id="dashboard_language" v-model="settings.Server.dashboard_language">
                <option value="en"><LocaleText t="English"></LocaleText></option>
                <option value="fa"><LocaleText t="Persian (فارسی)"></LocaleText></option>
                <!-- Add other supported languages here -->
              </select>
            </div>
            <div class="col-md-6">
              <label for="dashboard_peer_list_display" class="form-label"><LocaleText t="Peer List Display Style"></LocaleText></label>
              <select class="form-select" id="dashboard_peer_list_display" v-model="settings.Server.dashboard_peer_list_display">
                <option value="grid"><LocaleText t="Grid View"></LocaleText></option>
                <option value="list"><LocaleText t="List View"></LocaleText></option>
              </select>
            </div>
            <div class="col-md-6">
              <label for="dashboard_session_timeout" class="form-label"><LocaleText t="Session Timeout (minutes)"></LocaleText></label>
              <input type="number" class="form-control" id="dashboard_session_timeout" v-model.number="settings.Server.dashboard_session_timeout" min="0">
               <div class="form-text"><LocaleText t="0 for no timeout (not recommended)."></LocaleText></div>
            </div>
          </div>
          <div class="form-check form-switch mt-3">
            <input class="form-check-input" type="checkbox" role="switch" id="debug_mode" v-model="settings.Server.debug_mode">
            <label class="form-check-label" for="debug_mode"><LocaleText t="Enable Debug Mode"></LocaleText></label>
          </div>
        </div>
      </div>

      <!-- WireGuard General Settings -->
      <div class="card shadow-sm rounded-3">
        <div class="card-header bg-light-subtle">
          <h5 class="mb-0 py-1"><i class="bi bi-shield-lock me-2"></i><LocaleText t="WireGuard General Settings"></LocaleText></h5>
        </div>
        <div class="card-body p-4">
          <div class="mb-3">
            <label for="wg_config_path" class="form-label"><LocaleText t="Configurations Path"></LocaleText></label>
            <input type="text" class="form-control" id="wg_config_path" v-model="settings.WG.config_path" :placeholder="GetLocale('e.g., /etc/wireguard or C:\\Program Files\\WireGuard\\Data\\Configurations')">
            <div class="form-text"><LocaleText t="Path to WireGuard configuration files directory."></LocaleText></div>
          </div>
          <div class="row g-3">
            <div class="col-md-6">
              <label for="wg_dns_servers" class="form-label"><LocaleText t="Default DNS Servers for Interfaces"></LocaleText></label>
              <input type="text" class="form-control" id="wg_dns_servers" v-model="settings.WG.dns_servers" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
              <div class="form-text"><LocaleText t="Comma-separated. Applied to new interfaces."></LocaleText></div>
            </div>
            <div class="col-md-6">
              <label for="wg_mtu" class="form-label"><LocaleText t="Default MTU for Interfaces"></LocaleText></label>
              <input type="number" class="form-control" id="wg_mtu" v-model.number="settings.WG.mtu" placeholder="1420" min="0">
               <div class="form-text"><LocaleText t="0 to use system default. Applied to new interfaces."></LocaleText></div>
            </div>
            <div class="col-md-6">
                <label for="wg_persistent_keepalive" class="form-label"><LocaleText t="Default Persistent Keepalive for Peers"></LocaleText></label>
                <input type="number" class="form-control" id="wg_persistent_keepalive" v-model.number="settings.WG.persistent_keepalive" placeholder="25" min="0">
                <div class="form-text"><LocaleText t="In seconds. 0 to disable. Applied to new peers."></LocaleText></div>
            </div>
            <div class="col-md-6">
                <label for="preshared_key_generation" class="form-label"><LocaleText t="Preshared Key Generation for New Peers"></LocaleText></label>
                <select class="form-select" id="preshared_key_generation" v-model="settings.WG.preshared_key_generation">
                    <option :value="true"><LocaleText t="Enable Automatically"></LocaleText></option>
                    <option :value="false"><LocaleText t="Disable Automatically"></LocaleText></option>
                </select>
                 <div class="form-text"><LocaleText t="Controls if a PSK is generated by default for new peers."></LocaleText></div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Default Peer Settings -->
      <div class="card shadow-sm rounded-3">
        <div class="card-header bg-light-subtle">
          <h5 class="mb-0 py-1"><i class="bi bi-person-gear me-2"></i><LocaleText t="Default Peer Settings"></LocaleText></h5>
        </div>
        <div class="card-body p-4">
            <div class="mb-3">
                <label for="peer_default_allowed_ips" class="form-label"><LocaleText t="Default Allowed IPs Pattern"></LocaleText></label>
                <input type="text" class="form-control" id="peer_default_allowed_ips" v-model="settings.Peers.default_allowed_ips" :placeholder="GetLocale('e.g., 10.0.{interface_id}.{peer_id}/32')">
                <div class="form-text">
                    <LocaleText t="Use placeholders:"></LocaleText> <code>{interface_id}</code>, <code>{peer_id}</code>. <LocaleText t="Applied to new peers."></LocaleText>
                </div>
            </div>
            <div class="mb-3">
                <label for="peer_default_dns_servers" class="form-label"><LocaleText t="Default DNS Servers for Peers"></LocaleText></label>
                <input type="text" class="form-control" id="peer_default_dns_servers" v-model="settings.Peers.default_peer_dns_servers" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
                <div class="form-text"><LocaleText t="Comma-separated. Applied to new peers. Leave empty to use interface DNS."></LocaleText></div>
            </div>
             <div class="mb-3">
                <label for="peer_default_name_prefix" class="form-label"><LocaleText t="Default Peer Name Prefix"></LocaleText></label>
                <input type="text" class="form-control" id="peer_default_name_prefix" v-model="settings.Peers.default_peer_name_prefix" :placeholder="GetLocale('e.g., Peer-')">
                 <div class="form-text"><LocaleText t="Used when auto-generating peer names."></LocaleText></div>
            </div>
        </div>
      </div>

      <!-- Peer Jobs Settings -->
      <div class="card shadow-sm rounded-3">
        <div class="card-header bg-light-subtle">
          <h5 class="mb-0 py-1"><i class="bi bi-calendar-check me-2"></i><LocaleText t="Peer Jobs Settings"></LocaleText></h5>
        </div>
        <div class="card-body p-4">
          <div class="form-check form-switch mb-3">
            <input class="form-check-input" type="checkbox" role="switch" id="enable_peer_jobs" v-model="settings.Jobs.enable_peer_jobs">
            <label class="form-check-label" for="enable_peer_jobs"><LocaleText t="Enable Peer Jobs Feature"></LocaleText></label>
            <div class="form-text"><LocaleText t="Allows automated actions on peers based on conditions (e.g., data usage)."></LocaleText></div>
          </div>
          <div class="mb-3">
            <label for="job_check_interval" class="form-label"><LocaleText t="Job Check Interval (seconds)"></LocaleText></label>
            <input type="number" class="form-control" id="job_check_interval" v-model.number="settings.Jobs.job_check_interval" min="10" :disabled="!settings.Jobs.enable_peer_jobs">
            <div class="form-text"><LocaleText t="How often to check and execute pending jobs. Minimum 10 seconds."></LocaleText></div>
          </div>
        </div>
      </div>

      <div class="mt-3 mb-4 text-end">
        <button type="submit" class="btn btn-primary btn-lg rounded-pill px-4 py-2 shadow-sm" :disabled="isSaving">
          <span v-if="isSaving" class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
          <i v-else class="bi bi-save-fill me-2"></i>
          <LocaleText t="Save All Settings"></LocaleText>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
// import { useToast } from 'vue-toastification';

// const toast = useToast();

const settings = ref(null);
const isLoading = ref(true);
const isSaving = ref(false);
const errorLoading = ref(false);
const errorLoadingMessage = ref('');

const defaultSettingsStructure = () => ({
  Server: {
    dashboard_username: '',
    dashboard_password_input: '',
    dashboard_theme: 'auto',
    dashboard_language: 'en',
    dashboard_peer_list_display: 'grid',
    dashboard_session_timeout: 30,
    debug_mode: false,
  },
  WG: {
    config_path: '',
    dns_servers: '',
    mtu: 1420,
    persistent_keepalive: 25,
    preshared_key_generation: true,
  },
  Peers: {
    default_allowed_ips: '',
    default_peer_dns_servers: '',
    default_peer_name_prefix: 'Peer-',
  },
  Jobs: {
    enable_peer_jobs: true,
    job_check_interval: 60,
  }
});


const fetchSettings = async () => {
  isLoading.value = true;
  errorLoading.value = false;
  try {
    const response = await fetch('/api/getDashboardConfiguration'); // API endpoint from dashboard.py for all settings
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if (result.status && result.data) {
      const loadedSettings = JSON.parse(JSON.stringify(defaultSettingsStructure()));
      // Merge fetched data into default structure
      for (const sectionKey in result.data) {
        if (loadedSettings[sectionKey]) {
          Object.assign(loadedSettings[sectionKey], result.data[sectionKey]);
        } else {
          // This case should ideally not happen if defaultSettingsStructure is comprehensive
          loadedSettings[sectionKey] = result.data[sectionKey];
        }
      }
      loadedSettings.Server.dashboard_password_input = ''; // Always clear password input field
      settings.value = loadedSettings;

      // Store original language and theme to detect changes for reload
      if(settings.value && settings.value.Server){
          settings.value.Server.dashboard_language_original = settings.value.Server.dashboard_language;
          settings.value.Server.dashboard_theme_original = settings.value.Server.dashboard_theme;
      }

    } else {
      throw new Error(result.message || GetLocale("Failed to load settings. Invalid data format."));
    }
  } catch (error) {
    console.error("Error fetching global settings:", error);
    errorLoading.value = true;
    errorLoadingMessage.value = error.message;
    // toast.error(GetLocale("Error fetching settings: ") + error.message);
    settings.value = JSON.parse(JSON.stringify(defaultSettingsStructure()));
  } finally {
    isLoading.value = false;
  }
};

const saveSettings = async () => {
  isSaving.value = true;
  
  const settingsToSave = JSON.parse(JSON.stringify(settings.value));
  
  // Handle password: only send if new password is provided
  if (settingsToSave.Server && settingsToSave.Server.dashboard_password_input && settingsToSave.Server.dashboard_password_input.length > 0) {
    // The backend expects 'password' field for new password, not 'dashboard_password_input'
    // This needs to align with how /api/updateDashboardConfigurationItem handles 'Account' 'password'
    // For simplicity, we'll assume individual saves for now, or a dedicated global save endpoint.
    // The current backend structure seems to prefer individual SetConfig calls.
    // This saveAllSettings function would ideally call a new backend endpoint `/api/saveAllGlobalSettings`
    // or iterate and call `/api/updateDashboardConfigurationItem` for each changed item.
    // For this example, let's assume a new endpoint `/api/saveGlobalSettings` exists.
  } else if (settingsToSave.Server) {
    delete settingsToSave.Server.dashboard_password_input; // Don't send if empty
    // If dashboard_password_input is empty, the backend should not update the password.
  }
  // Remove helper fields not part of the actual config schema
  if (settingsToSave.Server) {
      delete settingsToSave.Server.dashboard_password_input;
      delete settingsToSave.Server.dashboard_language_original;
      delete settingsToSave.Server.dashboard_theme_original;
  }


  try {
    // This should be a single API call to save all settings if possible.
    // If not, multiple calls to /api/updateDashboardConfigurationItem would be needed.
    // Let's assume a hypothetical endpoint for saving all settings:
    const response = await fetch('/api/saveGlobalSettings', { // Hypothetical endpoint
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(settingsToSave),
    });

    const result = await response.json();
    if (result.status) {
      // toast.success(GetLocale("Settings saved successfully!"));
      alert(GetLocale("Settings saved successfully!")); // Placeholder for toast

      // Check if language or theme changed to prompt reload or handle dynamically
      const newLang = settings.value.Server.dashboard_language;
      const oldLang = settings.value.Server.dashboard_language_original;
      const newTheme = settings.value.Server.dashboard_theme;
      const oldTheme = settings.value.Server.dashboard_theme_original;

      // Update original values after successful save
      settings.value.Server.dashboard_language_original = newLang;
      settings.value.Server.dashboard_theme_original = newTheme;
      
      if (newLang !== oldLang || newTheme !== oldTheme) {
          // Consider a more graceful update, but reload is simplest
          // toast.info(GetLocale("Theme or language changed. Reloading for changes to take full effect..."));
          setTimeout(() => window.location.reload(), 1500);
      } else {
        fetchSettings(); // Re-fetch to ensure UI is in sync with any backend processing
      }

    } else {
      throw new Error(result.message || GetLocale("Failed to save settings."));
    }
  } catch (error) {
    console.error("Error saving global settings:", error);
    // toast.error(GetLocale("Error saving settings: ") + error.message);
    alert(GetLocale("Error saving settings: ") + error.message); // Placeholder
  } finally {
    isSaving.value = false;
  }
};

onMounted(() => {
  settings.value = JSON.parse(JSON.stringify(defaultSettingsStructure()));
  fetchSettings();
});

</script>

<style scoped>
.card-header h5 {
  font-size: 1.1rem;
  font-weight: 500;
}
.form-text {
  font-size: 0.875em;
  color: var(--bs-secondary-color);
}
.form-check-input:checked {
    background-color: var(--bs-primary);
    border-color: var(--bs-primary);
}
.form-check-label {
    cursor: pointer;
}
.card {
    border: 1px solid var(--bs-border-color-translucent);
}
</style>
