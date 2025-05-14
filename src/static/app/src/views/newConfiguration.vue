<script>
import {parse} from "cidr-tools";
import '@/utilities/wireguard.js' // Make sure this is correctly imported and used if needed globally
import {WireguardConfigurationsStore} from "@/stores/WireguardConfigurationsStore.js";
import {fetchGet, fetchPost} from "@/utilities/fetch.js";
import LocaleText from "@/components/text/localeText.vue";
import {parseInterface, parsePeers} from "@/utilities/parseConfigurationFile.js";
import {ref, onMounted, watch, computed} from "vue";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import { useRouter } from "vue-router";

export default {
	name: "newConfiguration",
	components: {LocaleText},
	setup(){
		const store = WireguardConfigurationsStore();
		const protocols = ref([]);
		const dashboardStore = DashboardConfigurationStore();
        const router = useRouter();

		const newConfiguration = ref({
            ConfigurationName: "",
            Address: "",
            ListenPort: "",
            PrivateKey: "",
            PublicKey: "",
            PresharedKey: "", // This seems to be a server-side key, not peer PSK
            PreUp: "",
            PreDown: "",
            PostUp: "",
            PostDown: "",
            Table: "",
            Protocol: "wg", // Default to 'wg'
            // AmneziaWG specific fields
            Jc: 5, Jmin: 49, Jmax: 998, S1: 17, S2: 110, H1: 0, H2: 0, H3: 0, H4: 0
        });

		const numberOfAvailableIPs = ref("0");
		const error = ref(false);
		const errorMessage = ref("");
		const success = ref(false);
		const loading = ref(false);
		// const parseInterfaceResult = ref(undefined); // Not directly used in template, consider removing if not needed
		// const parsePeersResult = ref(undefined); // Not directly used in template

        const configurationNameInput = ref(null);
        const addressInput = ref(null);
        const listenPortInput = ref(null);
        const privateKeyInput = ref(null); // Though disabled, might be useful for future validation logic

		const fetchInitialData = async () => {
			await fetchGet("/api/protocolsEnabled", {}, (res) => {
				if (res.status && res.data && res.data.length > 0) {
                    protocols.value = res.data;
                    if (!res.data.includes(newConfiguration.value.Protocol)) {
                        newConfiguration.value.Protocol = res.data[0]; // Default to first available if current is not
                    }
                } else {
                    protocols.value = ['wg']; // Fallback if API fails or returns empty
                    dashboardStore.newMessage("NewConfig", "Could not fetch available protocols, defaulting to WireGuard.", "warning");
                }
			});
			wireguardGenerateKeypair();
            generateAmneziaWGHashValues();
		};

        const rand = (min, max) => Math.floor(Math.random() * (max - min) + min);

        const generateAmneziaWGHashValues = () => {
            let hValue = [];
            while ([...new Set(hValue)].length !== 4){
                hValue = [rand(1, (2**31) - 1), rand(1, (2**31) - 1), rand(1, (2**31) - 1), rand(1, (2**31) - 1)];
            }
            newConfiguration.value.H1 = hValue[0];
            newConfiguration.value.H2 = hValue[1];
            newConfiguration.value.H3 = hValue[2];
            newConfiguration.value.H4 = hValue[3];
        };

		const wireguardGenerateKeypair = () => {
			if (window.wireguard && typeof window.wireguard.generateKeypair === 'function') {
				const wg = window.wireguard.generateKeypair();
				newConfiguration.value.PrivateKey = wg.privateKey;
				newConfiguration.value.PublicKey = wg.publicKey;
				// newConfiguration.value.PresharedKey = wg.presharedKey; // This is likely for peer, not interface
			} else {
                dashboardStore.newMessage("NewConfig", "WireGuard utility not available to generate keys.", "danger");
            }
		};

		const saveNewConfiguration = async () => {
			if (goodToSubmit.value){
				loading.value = true;
                error.value = false;
                errorMessage.value = "";
				await fetchPost("/api/addWireguardConfiguration", newConfiguration.value, async (res) => {
					if (res.status){
						success.value = true;
						await store.getConfigurations(); // Refresh store
                        dashboardStore.newMessage("NewConfig", `Configuration '${newConfiguration.value.ConfigurationName}' created successfully.`, "success");
						router.push(`/configuration/${newConfiguration.value.ConfigurationName}/peers`);
					}else{
						error.value = true;
						errorMessage.value = res.message || "An unknown error occurred.";
                        if (res.data && typeof res.data === 'string') { // Assuming res.data is the ID of the invalid field
                            const invalidInput = document.querySelector(`#${res.data}`);
                            if (invalidInput) {
                                invalidInput.classList.remove("is-valid");
                                invalidInput.classList.add("is-invalid");
                                invalidInput.focus();
                            }
                        }
						loading.value = false;
					}
				});
			}
		};

		const openFileUpload = () => {
			document.querySelector("#fileUpload").click();
		};

		const readFile = (e) => {
			const file = e.target.files[0];
			if (!file) return false;
			const reader = new FileReader();
			reader.onload = (evt) => {
				const parsedInterface = parseInterface(evt.target.result);
				// const parsedPeers = parsePeers(evt.target.result); // Not used
				let appliedFields = 0;
				if (parsedInterface){
					newConfiguration.value.ConfigurationName = file.name.replace(/\.conf$/i, ''); // More robust extension removal
					for (let key in parsedInterface){
						if (Object.prototype.hasOwnProperty.call(newConfiguration.value, key)){
							newConfiguration.value[key] = parsedInterface[key];
							appliedFields += 1;
						}
					}
				}
				if (appliedFields > 0){
					dashboardStore.newMessage("WGDashboard", `Parse successful! Updated ${appliedFields} field(s). Please review and save.`, "success");
				} else {
					dashboardStore.newMessage("WGDashboard", `Could not parse relevant fields from the file.`, "warning");
				}
                // Reset file input to allow re-upload of the same file
                e.target.value = null;
			};
			reader.readAsText(file);
		};

        const goodToSubmit = computed(() => {
            const requiredFields = ["ConfigurationName", "Address", "ListenPort", "PrivateKey"];
            for (const field of requiredFields) {
                if (!newConfiguration.value[field] || String(newConfiguration.value[field]).trim().length === 0) return false;
            }
            // Check for any inputs that are explicitly marked as invalid by watchers
            const formElements = [configurationNameInput.value, addressInput.value, listenPortInput.value, privateKeyInput.value];
            for (const el of formElements) {
                if (el && el.classList.contains("is-invalid")) return false;
            }
            return true;
        });

        watch(() => newConfiguration.value.Address, (newVal) => {
            const ele = addressInput.value;
            if (!ele) return;
            ele.classList.remove("is-invalid", "is-valid");
            error.value = false; errorMessage.value = ""; // Clear general error on field change
            try {
                if (!newVal || newVal.trim().split("/").filter(x => x.length > 0).length !== 2) {
                    throw new Error("Invalid CIDR format. Expected format: IP/Prefix (e.g., 10.0.0.1/24)");
                }
                const p = parse(newVal);
                const i = p.end - p.start;
                numberOfAvailableIPs.value = i.toLocaleString();
                if (i < 1) throw new Error("CIDR range results in zero available host IPs.");
                ele.classList.add("is-valid");
            } catch (e) {
                numberOfAvailableIPs.value = "0";
                ele.classList.add("is-invalid");
                // Optionally set a specific error message for this field if needed
            }
        });

        watch(() => newConfiguration.value.ListenPort, (newValStr) => {
            const ele = listenPortInput.value;
            if (!ele) return;
            const newVal = parseInt(newValStr, 10);
            ele.classList.remove("is-invalid", "is-valid");
            error.value = false; errorMessage.value = "";
            if (isNaN(newVal) || newVal < 1 || newVal > 65535 || !Number.isInteger(newVal)){
                ele.classList.add("is-invalid");
            } else {
                ele.classList.add("is-valid");
            }
        });

        watch(() => newConfiguration.value.ConfigurationName, (newVal) => {
            const ele = configurationNameInput.value;
            if (!ele) return;
            ele.classList.remove("is-invalid", "is-valid");
            error.value = false; errorMessage.value = "";
            if (!/^[a-zA-Z0-9_=+.-]{1,15}$/.test(newVal) || newVal.length === 0 || (store.Configurations && store.Configurations.find(x => x.Name === newVal))){
                ele.classList.add("is-invalid");
            } else {
                ele.classList.add("is-valid");
            }
        });

        watch(() => newConfiguration.value.PrivateKey, (newVal) => {
            const ele = privateKeyInput.value; // This input is disabled, but validation logic is kept
            if (!ele) return;
            ele.classList.remove("is-invalid", "is-valid");
            error.value = false; errorMessage.value = "";
            try {
                if (window.wireguard && typeof window.wireguard.generatePublicKey === 'function') {
                    newConfiguration.value.PublicKey = window.wireguard.generatePublicKey(newVal);
                    ele.classList.add("is-valid");
                } else {
                     ele.classList.add("is-invalid"); // Cannot verify
                }
            } catch (e) {
                newConfiguration.value.PublicKey = "";
                ele.classList.add("is-invalid");
            }
        });

		onMounted(() => {
			fetchInitialData();
            const fileUploadElement = document.querySelector("#fileUpload");
            if (fileUploadElement) {
                fileUploadElement.addEventListener("change", readFile, false);
            }
		});
		
		return {
            store, protocols, dashboardStore, router,
            newConfiguration, numberOfAvailableIPs, error, errorMessage, success, loading,
            wireguardGenerateKeypair, saveNewConfiguration, openFileUpload,
            goodToSubmit,
            configurationNameInput, addressInput, listenPortInput, privateKeyInput
        };
	}
}
</script>

<template>
	<div class="mt-md-4 mt-3 text-body mb-5">
		<div class="container-xl">
			<div class="page-header mb-4 d-flex flex-wrap align-items-center gap-3">
				<RouterLink to="/"
				            class="btn btn-light btn-lg p-2 lh-1 rounded-circle shadow-sm" title="Back to Dashboard">
					<i class="bi bi-arrow-left fs-4"></i>
				</RouterLink>
				<h2 class="mb-0 flex-grow-1">
					<LocaleText t="New WireGuard Configuration"></LocaleText>
				</h2>
				<div class="d-flex gap-2 ms-auto ms-md-0">
					<button class="btn btn-outline-secondary rounded-pill"
					        @click="openFileUpload()"
					        type="button">
						<i class="bi bi-upload me-2"></i>
						<LocaleText t="Import from File"></LocaleText>
					</button>
					<input type="file" id="fileUpload" class="d-none" accept=".conf,text/plain" />
				</div>
			</div>
			
            <div v-if="error" class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> {{errorMessage}}
                <button type="button" class="btn-close" @click="error = false; errorMessage=''" aria-label="Close"></button>
            </div>

			<form class="text-body d-flex flex-column gap-3" @submit.prevent="saveNewConfiguration">
				<div class="card rounded-3 shadow-sm">
					<div class="card-header bg-light-subtle">
						<h5 class="my-1"><LocaleText t="Protocol Selection"></LocaleText></h5>
					</div>
					<div class="card-body d-flex gap-2 p-3 protocolBtnGroup">
						<a role="button"
							v-if="protocols.includes('wg')"
							@click="newConfiguration.Protocol = 'wg'"
							:class="{'active': newConfiguration.Protocol === 'wg'}"
							class="btn flex-grow-1 btn-lg wireguardBg">
							<i :class="newConfiguration.Protocol === 'wg' ? 'bi-check-circle-fill' : 'bi-circle'" class="me-2"></i>
							<strong>WireGuard</strong>
						</a>
						<a role="button"
							@click="newConfiguration.Protocol = 'awg'"
							v-if="protocols.includes('awg')"
							:class="{'active': newConfiguration.Protocol === 'awg'}"
							class="btn flex-grow-1 btn-lg amneziawgBg">
							<i :class="newConfiguration.Protocol === 'awg' ? 'bi-check-circle-fill' : 'bi-circle'" class="me-2"></i>
							<strong>AmneziaWG</strong>
						</a>
                        <div v-if="protocols.length === 0" class="alert alert-warning w-100 mb-0">
                            <LocaleText t="No protocols reported as enabled by the server. Defaulting to WireGuard."></LocaleText>
                        </div>
					</div>
				</div>
				
				<div class="card rounded-3 shadow-sm">
					<div class="card-header bg-light-subtle">
                        <h5 class="my-1"><LocaleText t="Basic Configuration"></LocaleText></h5>
                    </div>
					<div class="card-body p-4 d-flex flex-column gap-3">
                        <div>
                            <label for="ConfigurationName" class="form-label"><LocaleText t="Configuration Name"></LocaleText> <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-lg" placeholder="e.g., wg0-server" id="ConfigurationName"
                                   ref="configurationNameInput"
                                   v-model.trim="newConfiguration.ConfigurationName"
                                   :disabled="loading"
                                   required>
                            <div class="invalid-feedback">
                                <div v-if="store.Configurations && store.Configurations.find(x => x.Name === newConfiguration.ConfigurationName)">
                                    <LocaleText t="Configuration name already exists."></LocaleText>
                                </div>
                                <div v-else>
                                    <LocaleText t="Max 15 chars: letters, numbers, _ = + . -"></LocaleText>
                                </div>
                            </div>
                             <div class="form-text"><LocaleText t="A unique name for this WireGuard interface."></LocaleText></div>
                        </div>

                        <div>
                            <label class="form-label"><LocaleText t="Server Keys"></LocaleText> <span class="text-danger">*</span></label>
                            <div class="input-group mb-2">
                                <span class="input-group-text" style="min-width: 120px;"><LocaleText t="Private Key"></LocaleText></span>
                                <input type="text" class="form-control form-control-lg font-monospace" id="PrivateKey"
                                       ref="privateKeyInput"
                                       v-model="newConfiguration.PrivateKey"
                                       :disabled="loading || true" 
                                       required readonly>
                                <button class="btn btn-outline-secondary" type="button"
                                        title="Regenerate Keypair"
                                        @click="wireguardGenerateKeypair()" :disabled="loading">
                                    <i class="bi bi-arrow-repeat"></i>
                                </button>
                            </div>
                             <div class="input-group">
                                <span class="input-group-text" style="min-width: 120px;"><LocaleText t="Public Key"></LocaleText></span>
                                <input type="text" class="form-control form-control-lg font-monospace" id="PublicKey"
                                       v-model="newConfiguration.PublicKey"
                                       disabled readonly>
                            </div>
                            <div class="invalid-feedback" v-if="privateKeyInput && privateKeyInput.classList.contains('is-invalid')">
                                <LocaleText t="Invalid Private Key. Ensure it's a valid WireGuard key."></LocaleText>
                            </div>
                        </div>

                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="ListenPort" class="form-label"><LocaleText t="Listen Port"></LocaleText> <span class="text-danger">*</span></label>
                                <input type="number" class="form-control form-control-lg" placeholder="1-65535" id="ListenPort"
                                       ref="listenPortInput"
                                       min="1" max="65535"
                                       v-model.number="newConfiguration.ListenPort"
                                       :disabled="loading"
                                       required>
                                <div class="invalid-feedback">
                                    <LocaleText t="Invalid port number (must be between 1 and 65535)."></LocaleText>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label for="Address" class="form-label"><LocaleText t="Interface IP Address/CIDR"></LocaleText> <span class="text-danger">*</span></label>
                                <input type="text" class="form-control form-control-lg"
                                       placeholder="e.g., 10.0.0.1/24" id="Address"
                                       ref="addressInput"
                                       v-model.trim="newConfiguration.Address"
                                       :disabled="loading"
                                       required>
                                <div class="invalid-feedback">
                                    <LocaleText t="Invalid IP Address/CIDR format or range."></LocaleText>
                                </div>
                                <div class="form-text">
                                    <LocaleText :t="`${numberOfAvailableIPs} Available IP Addresses`"></LocaleText>
                                </div>
                            </div>
                        </div>
					</div>
				</div>
				
				<div class="accordion shadow-sm rounded-3" id="newConfigurationOptionalAccordion">
					<div class="accordion-item rounded-3">
						<h2 class="accordion-header">
							<button class="accordion-button collapsed fw-medium py-3 px-4" type="button" data-bs-toggle="collapse" data-bs-target="#newConfigurationOptionalAccordionCollapse" aria-expanded="false" aria-controls="newConfigurationOptionalAccordionCollapse">
								<i class="bi bi-sliders2 me-2"></i> <LocaleText t="Advanced & Optional Settings"></LocaleText>
							</button>
						</h2>
						<div id="newConfigurationOptionalAccordionCollapse" 
						     class="accordion-collapse collapse" data-bs-parent="#newConfigurationOptionalAccordion">
							<div class="accordion-body p-4 d-flex flex-column gap-3">
								<div v-for="key in ['Table', 'PreUp', 'PreDown', 'PostUp', 'PostDown']" :key="key" class="row align-items-center">
                                    <label :for="key" class="col-sm-3 col-form-label fw-medium">{{ key }}</label>
                                    <div class="col-sm-9">
                                        <input type="text" class="form-control font-monospace" :id="key" v-model="newConfiguration[key]" :placeholder="GetLocale('Optional')">
                                    </div>
								</div>

								<div v-if="newConfiguration.Protocol === 'awg'">
                                    <hr class="my-3">
                                    <h6 class="mb-3 text-info"><LocaleText t="AmneziaWG Specific Parameters"></LocaleText></h6>
                                    <div class="row g-3">
                                        <div v-for="key in ['Jc', 'Jmin', 'Jmax', 'S1', 'S2', 'H1', 'H2', 'H3', 'H4']" :key="key" class="col-md-4 col-sm-6">
                                            <label :for="`awg-${key}`" class="form-label fw-medium">{{ key }}</label>
                                            <input type="number" class="form-control font-monospace" :id="`awg-${key}`" v-model.number="newConfiguration[key]">
                                        </div>
                                    </div>
                                </div>
							</div>
						</div>
					</div>
				</div>

				<div class="mt-3 d-flex justify-content-end">
                    <button type="submit" class="btn btn-primary btn-lg rounded-pill px-4 py-2 shadow-sm"
                            :disabled="!goodToSubmit || loading || success">
                        <span v-if="success" class="d-flex align-items-center">
                            <i class="bi bi-check-circle-fill me-2"></i>
                            <LocaleText t="Configuration Created"></LocaleText>!
                        </span>
                        <span v-else-if="loading" class="d-flex align-items-center">
                            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                            <LocaleText t="Saving..."></LocaleText>
                        </span>
                        <span v-else class="d-flex align-items-center">
                            <i class="bi bi-save-fill me-2"></i>
                            <LocaleText t="Create Configuration"></LocaleText>
                        </span>
                    </button>
                </div>
			</form>
		</div>
	</div>
</template>

<style scoped>
/* .page-header .btn-light rules removed as they are now global */

.protocolBtnGroup .btn {
	transition: all 0.2s ease-in-out, opacity 0.2s ease-in-out;
    border: 2px solid transparent;
}
.protocolBtnGroup .btn:not(.active) {
    opacity: 0.65;
    background-color: var(--bs-body-tertiary);
    color: var(--bs-emphasis-color);
}
.protocolBtnGroup .btn:not(.active):hover {
    opacity: 1;
    background-color: var(--bs-secondary-bg);
}
.protocolBtnGroup .btn.active {
    opacity: 1;
    box-shadow: 0 0 0 0.25rem var(--bs-primary-border-subtle);
}

.wireguardBg { background-color: #e66a00; color: white; border-color: #e66a00 !important; }
.wireguardBg.active { background-color: #c65a00 !important; border-color: #a64a00 !important; }
.wireguardBg:not(.active):hover { background-color: #f08a24 !important; color: white; }


.amneziawgBg { background-color: #007bff; color: white; border-color: #007bff !important; }
.amneziawgBg.active { background-color: #0056b3 !important; border-color: #004085 !important; }
.amneziawgBg:not(.active):hover { background-color: #2997ff !important; color: white; }

.accordion-button:not(.collapsed) {
    color: var(--bs-primary);
    background-color: var(--bs-primary-bg-subtle);
}
.accordion-button:focus {
    box-shadow: none;
}
.form-control-lg {
    padding: 0.75rem 1rem; /* Slightly larger padding for lg inputs */
    font-size: 1rem; /* Ensure font size is not too large */
}
.input-group-text {
    font-size: 0.9rem; /* Adjust if needed */
}
</style>