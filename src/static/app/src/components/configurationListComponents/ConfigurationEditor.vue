<template>
  <div class="modal fade" id="configurationEditorModal" tabindex="-1" aria-labelledby="configurationEditorModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="configurationEditorModalLabel">
            <i class="bi bi-file-earmark-medical me-2" v-if="!isEditing"></i>
            <i class="bi bi-pencil-square me-2" v-if="isEditing"></i>
            <LocaleText :t="isEditing ? 'Edit Configuration' : 'Create New Configuration'"></LocaleText>
            <span v-if="isEditing && editableConfiguration" class="text-muted small ms-2">- {{ editableConfiguration.Name }}</span>
          </h5>
          <button type="button" class="btn-close" @click="closeModal" aria-label="Close"></button>
        </div>
        <div class="modal-body" v-if="editableConfiguration">
          <form @submit.prevent="saveConfigurationDetails">
            <div class="alert alert-warning small" role="alert" v-if="isEditing && hasPeers">
              <i class="bi bi-exclamation-triangle-fill me-2"></i>
              <LocaleText t="Warning: Modifying core settings (like Address or ListenPort) of a running configuration with active peers might cause disruptions. Consider stopping the configuration first."></LocaleText>
            </div>

            <!-- Basic Configuration Details -->
            <h6 class="mb-3 text-primary"><LocaleText t="Basic Details"></LocaleText></h6>
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="configName" class="form-label"><LocaleText t="Configuration Name"></LocaleText> <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="configName" v-model="editableConfiguration.Name" required :disabled="isEditing" :placeholder="GetLocale('e.g., wg0 or MyVPN')">
                <div class="form-text" v-if="isEditing"><LocaleText t="Name cannot be changed after creation."></LocaleText></div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="configProtocol" class="form-label"><LocaleText t="Protocol"></LocaleText></label>
                <select class="form-select" id="configProtocol" v-model="editableConfiguration.Protocol" :disabled="isEditing">
                    <option value="wg">WireGuard</option>
                    <!-- <option value="hysteria2">Hysteria2 (Coming Soon)</option> -->
                </select>
                 <div class="form-text" v-if="isEditing"><LocaleText t="Protocol cannot be changed after creation."></LocaleText></div>
              </div>
            </div>

            <!-- Interface Settings -->
            <h6 class="mt-4 mb-3 text-primary"><LocaleText t="Interface Settings"></LocaleText></h6>
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="configAddress" class="form-label"><LocaleText t="Server Address(es)"></LocaleText> <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="configAddress" v-model="editableConfiguration.Interface.Address" required :placeholder="GetLocale('e.g., 10.0.0.1/24, fd00::1/64')">
                <div class="form-text"><LocaleText t="Comma-separated IPv4/IPv6 CIDR addresses for the server interface."></LocaleText></div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="configListenPort" class="form-label"><LocaleText t="Listen Port"></LocaleText></label>
                <input type="number" class="form-control" id="configListenPort" v-model.number="editableConfiguration.Interface.ListenPort" placeholder="51820" min="1" max="65535">
                <div class="form-text"><LocaleText t="Leave empty for a random port (not recommended for servers)."></LocaleText></div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="configPrivateKey" class="form-label"><LocaleText t="Server Private Key"></LocaleText> <span class="text-danger">*</span></label>
                <div class="input-group">
                  <input :type="showPrivateKey ? 'text' : 'password'" class="form-control" id="configPrivateKey" v-model="editableConfiguration.Interface.PrivateKey" required>
                  <button class="btn btn-outline-secondary" type="button" @click="showPrivateKey = !showPrivateKey">
                    <i class="bi" :class="showPrivateKey ? 'bi-eye-slash' : 'bi-eye'"></i>
                  </button>
                  <button class="btn btn-outline-secondary" type="button" @click="generateKeyPair" :title="GetLocale('Generate New Key Pair')">
                    <i class="bi bi-arrow-repeat"></i>
                  </button>
                </div>
                <div class="form-text"><LocaleText t="Keep this key secret. Click generate or paste your own."></LocaleText></div>
              </div>
              <div class="col-md-6 mb-3">
                <label for="configPublicKey" class="form-label"><LocaleText t="Server Public Key"></LocaleText></label>
                <input type="text" class="form-control" id="configPublicKey" v-model="editableConfiguration.Interface.PublicKey" readonly :placeholder="GetLocale('Auto-generated from Private Key')">
              </div>
            </div>
             <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="configDNS" class="form-label"><LocaleText t="DNS Servers for Clients"></LocaleText></label>
                    <input type="text" class="form-control" id="configDNS" v-model="editableConfiguration.Interface.DNS" :placeholder="GetLocale('e.g., 1.1.1.1, 8.8.8.8')">
                    <div class="form-text"><LocaleText t="Comma-separated. Pushed to clients if they support it."></LocaleText></div>
                </div>
                <div class="col-md-6 mb-3">
                    <label for="configMTU" class="form-label"><LocaleText t="MTU"></LocaleText></label>
                    <input type="number" class="form-control" id="configMTU" v-model.number="editableConfiguration.Interface.MTU" :placeholder="GetLocale('e.g., 1420, 0 for default')">
                    <div class="form-text"><LocaleText t="0 to use system default."></LocaleText></div>
                </div>
            </div>

            <!-- Advanced Settings: Scripts -->
            <h6 class="mt-4 mb-3 text-primary"><LocaleText t="Advanced Settings"></LocaleText></h6>
            <div class="mb-3">
              <label for="configPostUp" class="form-label"><LocaleText t="PostUp Script"></LocaleText></label>
              <textarea class="form-control font-monospace small" id="configPostUp" v-model="editableConfiguration.Interface.PostUp" rows="3" :placeholder="GetLocale('Commands to run after interface is up. e.g., iptables rules.')"></textarea>
            </div>
            <div class="mb-3">
              <label for="configPostDown" class="form-label"><LocaleText t="PostDown Script"></LocaleText></label>
              <textarea class="form-control font-monospace small" id="configPostDown" v-model="editableConfiguration.Interface.PostDown" rows="3" :placeholder="GetLocale('Commands to run after interface is down.')"></textarea>
            </div>
            <div class="form-check form-switch mb-3">
                <input class="form-check-input" type="checkbox" role="switch" id="configSaveConfig" v-model="editableConfiguration.Interface.SaveConfig">
                <label class="form-check-label" for="configSaveConfig"><LocaleText t="Save Configuration on Shutdown (SaveConfig)"></LocaleText></label>
                <div class="form-text"><LocaleText t="If enabled, current state (including dynamic peers) is saved to the config file when the interface is stopped."></LocaleText></div>
            </div>

          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="closeModal">
            <i class="bi bi-x-circle me-1"></i><LocaleText t="Cancel"></LocaleText>
          </button>
          <button type="submit" class="btn btn-primary" @click="saveConfigurationDetails" :disabled="isSaving">
            <span v-if="isSaving" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
            <i v-else class="bi bi-check-circle me-1"></i>
            <LocaleText :t="isEditing ? 'Save Changes' : 'Create Configuration'"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, defineProps, defineEmits, toRefs, onMounted, computed } from 'vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import { Modal as BootstrapModal } from 'bootstrap';
// import { useToast } from 'vue-toastification'; // یا هر سیستم نوتیفیکیشن دیگری

// const toast = useToast();
let modalInstance = null;

const props = defineProps({
  configurationToEdit: Object, // پیکربندی که برای ویرایش پاس داده می‌شود
  // configurationName: String // اگر فقط نام برای ویرایش ارسال شود
});

const emit = defineEmits(['configurationSaved', 'modalClosed']);

const { configurationToEdit } = toRefs(props);

const defaultInterfaceStructure = () => ({
  Address: '',
  ListenPort: null, // یا یک پورت پیش‌فرض مانند 51820
  PrivateKey: '',
  PublicKey: '', // به طور خودکار از PrivateKey تولید می‌شود
  DNS: '',
  MTU: null, // یا 0 یا 1420
  PostUp: '',
  PostDown: '',
  SaveConfig: true, // مقدار پیش‌فرض در WireGuard
});

const defaultConfigurationStructure = () => ({
  Name: '',
  Protocol: 'wg',
  Interface: defaultInterfaceStructure(),
  Peers: [], // لیست همتاها در اینجا مدیریت نمی‌شود، فقط ساختار کلی
  Status: false, // وضعیت اولیه
  // فیلدهای دیگر مانند DataUsage و غیره توسط سرور مدیریت می‌شوند
});

const editableConfiguration = ref(JSON.parse(JSON.stringify(defaultConfigurationStructure())));
const isEditing = ref(false);
const isSaving = ref(false);
const showPrivateKey = ref(false);
const hasPeers = ref(false); // برای نمایش هشدار در صورت ویرایش و داشتن همتا

watch(configurationToEdit, (newVal) => {
  if (newVal && newVal.Name) { // اگر آبجکت معتبر برای ویرایش وجود دارد
    isEditing.value = true;
    // ایجاد یک کپی عمیق و ادغام با ساختار پیش‌فرض برای اطمینان از وجود همه کلیدها
    const base = JSON.parse(JSON.stringify(defaultConfigurationStructure()));
    
    // اطمینان از اینکه Interface همیشه یک آبجکت است و از base می‌آید
    // سپس با مقادیر newVal.Interface (اگر وجود داشته باشد) ادغام می‌شود.
    const newInterface = { ...defaultInterfaceStructure(), ...(newVal.Interface || {}) };
    
    editableConfiguration.value = {
        ...base, // شروع با ساختار پایه
        ...JSON.parse(JSON.stringify(newVal)), // اعمال مقادیر newVal
        Interface: newInterface // اطمینان از اینکه Interface ساختار کامل را دارد
    };

    if (editableConfiguration.value.Interface && editableConfiguration.value.Interface.ListenPort === 0) {
        editableConfiguration.value.Interface.ListenPort = null;
    }
    hasPeers.value = newVal.Peers && newVal.Peers.length > 0;
  } else {
    isEditing.value = false;
    editableConfiguration.value = JSON.parse(JSON.stringify(defaultConfigurationStructure()));
    hasPeers.value = false;
  }
}, { immediate: true, deep: true });


const generateKeyPair = async () => {
  try {
    const response = await fetch('/api/generateKeyPair'); // API endpoint from dashboard.py
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }
    const keys = await response.json();
    if (keys.status && keys.data) {
      editableConfiguration.value.Interface.PrivateKey = keys.data.privateKey;
      editableConfiguration.value.Interface.PublicKey = keys.data.publicKey;
      // toast.success(GetLocale("New key pair generated."));
      console.log(GetLocale("New key pair generated."));
    } else {
      throw new Error(keys.message || "Failed to generate keys");
    }
  } catch (error) {
    console.error("Error generating key pair:", error);
    // toast.error(GetLocale("Error generating key pair: ") + error.message);
    alert(GetLocale("Error generating key pair: ") + error.message); // Keep alert for now or replace with better notification
  }
};

// محاسبه خودکار کلید عمومی از کلید خصوصی (باید در بک‌اند انجام شود یا با کتابخانه معتبر)
// این بخش در اینجا فقط نمایشی است و برای تولید واقعی کلید عمومی مناسب نیست.
watch(() => editableConfiguration.value.Interface.PrivateKey, (newVal, oldVal) => {
  // Only attempt to generate public key if private key seems valid and has changed
  // This is a very basic check. Robust validation should be on the server.
  // The public key field is readonly, so this is primarily for display if not using the generate button.
  // However, the generateKeyPair function is the primary way to set both.
  // If a user pastes a private key, the public key will be derived by the backend upon saving.
  // For immediate UI feedback if pasting, a client-side library would be needed, or an API call.
  // For now, we rely on the backend or the generateKeyPair button.
  if (newVal && newVal !== oldVal && newVal.length > 20 && !editableConfiguration.value.Interface.PublicKey) {
     // editableConfiguration.value.Interface.PublicKey = GetLocale("Will be derived on save or use 'Generate'");
  } else if (!newVal) {
    // editableConfiguration.value.Interface.PublicKey = "";
  }
});


const saveConfigurationDetails = async () => {
  isSaving.value = true;
  // اعتبارسنجی اولیه
  if (!editableConfiguration.value.Name || !editableConfiguration.value.Interface.Address || !editableConfiguration.value.Interface.PrivateKey) {
    // toast.error(GetLocale("Please fill all required fields: Name, Address, and Private Key."));
    alert(GetLocale("Please fill all required fields: Name, Address, and Private Key."));
    isSaving.value = false;
    return;
  }

  const payload = JSON.parse(JSON.stringify(editableConfiguration.value));
  // اگر ListenPort خالی است، آن را به 0 تبدیل کن (یا هر مقدار دیگری که بک‌اند انتظار دارد)
  if (payload.Interface.ListenPort === null || payload.Interface.ListenPort === '') {
    payload.Interface.ListenPort = 0; // 0 معمولاً به معنی پورت تصادفی یا عدم تنظیم است
  }
  if (payload.Interface.MTU === null || payload.Interface.MTU === '') {
    payload.Interface.MTU = 0; // 0 معمولاً به معنی پیش‌فرض سیستم است
  }

  // Ensure Protocol is included
  if (!payload.Protocol) {
    payload.Protocol = 'wg'; // Default to 'wg' if not set
  }


  try {
    const response = await fetch('/api/saveConfiguration', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ configuration: payload, is_new: !isEditing.value })
    });
    const result = await response.json();
    if (result.status) {
      // toast.success(GetLocale(isEditing.value ? "Configuration updated successfully!" : "Configuration created successfully!"));
      alert(GetLocale(isEditing.value ? "Configuration updated successfully!" : "Configuration created successfully!"));
      emit('configurationSaved', result.data || payload); // ارسال پیکربندی ذخیره شده
      closeModal();
    } else {
      throw new Error(result.message || GetLocale("Failed to save configuration."));
    }
  } catch (error) {
    console.error("Error saving configuration:", error);
    // toast.error(GetLocale("Error saving configuration: ") + error.message);
    alert(GetLocale("Error saving configuration: ") + error.message);
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
    const modalElement = document.getElementById('configurationEditorModal');
    if (modalElement) {
        modalInstance = new BootstrapModal(modalElement);
        // برای جلوگیری از بسته شدن مدال با کلیک روی پس‌زمینه یا Esc (اگر نیاز باشد)
        // modalInstance = new BootstrapModal(modalElement, {
        //  backdrop: 'static',
        //  keyboard: false
        // });
    }
    // اگر configurationToEdit از ابتدا مقدار داشته باشد، watcher آن را مدیریت می‌کند
    // در غیر این صورت، editableConfiguration با مقادیر پیش‌فرض مقداردهی شده است.
});

// برای باز کردن مدال از کامپوننت والد:
// 1. یک ref به این کامپوننت در والد ایجاد کنید.
// 2. یک متد در این کامپوننت (مثلاً open()) ایجاد کنید که modalInstance.show() را فراخوانی کند.
// 3. از والد، ref.value.open() را صدا بزنید.
// یا اینکه مدال با data attributes از والد کنترل شود.

defineExpose({ // برای اینکه والد بتواند مدال را باز و بسته کند
    show: () => { if(modalInstance) modalInstance.show(); },
    hide: () => { if(modalInstance) modalInstance.hide(); }
});

</script>

<style scoped>
.modal-body {
  max-height: 70vh; /* یا مقدار مناسب دیگر */
}
.font-monospace {
  font-family: var(--bs-font-monospace);
}
/* Add any additional specific styles here */
</style>
