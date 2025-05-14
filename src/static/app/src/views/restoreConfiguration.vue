<script setup>
import LocaleText from "@/components/text/localeText.vue";
import {onMounted, ref} from "vue";
import {fetchGet} from "@/utilities/fetch.js";
import BackupGroup from "@/components/restoreConfigurationComponents/backupGroup.vue";
import ConfirmBackup from "@/components/restoreConfigurationComponents/confirmBackup.vue";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";

const backups = ref(undefined);
const store = DashboardConfigurationStore();
// const uploadModal = ref(false); // Commented out in original
// const uploads = { // Commented out in original
// 	conf: undefined,
// 	sql: undefined
// }

const isLoading = ref(true);

onMounted(async () => {
    isLoading.value = true;
	await fetchGet("/api/getAllWireguardConfigurationBackup", {}, (res) => {
		if (res.status && res.data) {
            backups.value = res.data;
        } else {
            backups.value = { NonExistingConfigurations: {} }; // Ensure structure for v-if
            store.newMessage("RestoreConfig", res.message || "Failed to load backups.", "danger");
        }
        isLoading.value = false;
	});
});

const confirm = ref(false);
const selectedConfigurationBackup = ref(undefined);
const selectedConfigurationName = ref(""); // Changed from selectedConfiguration to avoid conflict

// const openFileUpload = () => { // Commented out in original
// 	// uploadModal.value = true;
// 	// document.querySelector("#fileUpload").click();
// }

const handleSelectBackup = (backup, configName) => {
    selectedConfigurationBackup.value = backup;
    selectedConfigurationName.value = configName;
    confirm.value = true;
    // Scroll to step 2 smoothly
    const step2Element = document.getElementById('step2');
    if (step2Element) {
        step2Element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
};

const resetSelection = () => {
    confirm.value = false;
    selectedConfigurationBackup.value = undefined;
    selectedConfigurationName.value = "";
     const step1Element = document.getElementById('step1');
    if (step1Element) {
        step1Element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

</script>

<template>
	<div class="mt-md-4 mt-3 text-body mb-5">
		<div class="container-xl">
			<div class="page-header mb-4 d-flex align-items-center gap-3">
				<RouterLink to="/"
				            class="btn btn-light btn-lg p-2 lh-1 rounded-circle shadow-sm" title="Back to Dashboard">
					<i class="bi bi-arrow-left fs-4"></i>
				</RouterLink>
				<h2 class="mb-0">
					<LocaleText t="Restore Configuration"></LocaleText>
				</h2>
				
				<!-- Upload Backup Button - Commented out in original -->
				<!-- <div class="d-flex gap-2 ms-auto">
					<button class="btn btn-outline-primary rounded-pill"
					        @click="openFileUpload()"
					        type="button">
						<i class="bi bi-upload me-2"></i>
						<LocaleText t="Upload Backup"></LocaleText>
					</button>
				</div>-->
			</div>

            <div v-if="isLoading" class="text-center my-5">
                <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                    <span class="visually-hidden"><LocaleText t="Loading backups..."></LocaleText></span>
                </div>
                <p class="mt-2"><LocaleText t="Loading backups..."></LocaleText></p>
            </div>
			
			<Transition name="fade" appear>
				<div v-if="!isLoading && backups">
					<!-- Step 1 -->
                    <div id="step1" class="mb-5 card shadow-sm">
                        <div class="card-header bg-primary-subtle">
                            <div class="d-flex align-items-center steps"
                                 :class="{active: !confirm, 'opacity-50': confirm}"
                                 @click="resetSelection" role="button">
                                <div class="d-flex text-decoration-none text-body flex-grow-1 align-items-center gap-3 py-2">
                                    <h1 class="mb-0 lh-1 text-primary">
                                        <i class="bi bi-1-circle-fill"></i>
                                    </h1>
                                    <div>
                                        <h4 class="mb-0">
                                            <LocaleText t="Step 1: Select Backup"></LocaleText>
                                        </h4>
                                        <small class="text-muted">
                                            <LocaleText t="Choose a configuration backup to restore" v-if="!confirm"></LocaleText>
                                            <LocaleText t="Click here to change your selection" v-else></LocaleText>
                                        </small>
                                    </div>
                                </div>
                                <Transition name="zoomReversed">
                                    <div class="ms-sm-auto text-end" v-if="confirm && selectedConfigurationBackup">
                                        <small class="text-muted d-block">
                                            <LocaleText t="Selected Backup"></LocaleText>:
                                        </small>
                                        <h6 class="mb-0">
                                            <samp class="bg-body-secondary px-2 py-1 rounded">{{selectedConfigurationBackup.filename}}</samp>
                                        </h6>
                                    </div>
                                </Transition>
                            </div>
                        </div>
                        <div class="card-body p-lg-4" v-if="!confirm">
                            <div v-if="Object.keys(backups.NonExistingConfigurations).length > 0" class="d-flex gap-3 flex-column">
                                <BackupGroup
                                    v-for="configName in Object.keys(backups.NonExistingConfigurations)"
                                    :key="configName"
                                    @select="(backup) => handleSelectBackup(backup, configName)"
                                    :selectedConfigurationBackup="selectedConfigurationBackup"
                                    :open="selectedConfigurationName === configName"
                                    :protocol="[...new Set(backups.NonExistingConfigurations[configName].map(x => x.protocol))]"
                                    :configuration-name="configName"
                                    :backups="backups.NonExistingConfigurations[configName]">
                                </BackupGroup>
                            </div>
                            <div v-else class="alert alert-info mb-0">
                                <i class="bi bi-info-circle-fill me-2"></i>
                                <LocaleText t="You don't have any non-existing configurations with backups to restore."></LocaleText>
                                <LocaleText t=" Backups for existing configurations can be restored from the configuration's own page."></LocaleText>
                            </div>
                        </div>
                    </div>
					
					<!-- Step 2 -->
                    <div id="step2" class="mb-4 card shadow-sm" v-if="selectedConfigurationBackup">
                         <div class="card-header bg-primary-subtle">
                            <div class="d-flex align-items-center steps" :class="{active: confirm}">
                                <div class="d-flex text-decoration-none text-body flex-grow-1 align-items-center gap-3 py-2">
                                    <h1 class="mb-0 lh-1 text-primary">
                                        <i class="bi bi-2-circle-fill"></i>
                                    </h1>
                                    <div>
                                        <h4 class="mb-0">
                                            <LocaleText t="Step 2: Confirm & Restore"></LocaleText>
                                        </h4>
                                        <small class="text-muted">
                                            <LocaleText t="Review the details and confirm the restoration process"></LocaleText>
                                        </small>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="card-body p-lg-4" v-if="confirm">
                            <ConfirmBackup :selectedConfigurationBackup="selectedConfigurationBackup" :key="selectedConfigurationBackup.filename"></ConfirmBackup>
                        </div>
                    </div>
                    <div v-else-if="!isLoading && !confirm" class="alert alert-light text-center border">
                        <LocaleText t="Please select a backup from Step 1 to proceed."></LocaleText>
                    </div>

				</div>
			</Transition>
		</div>
	</div>
</template>

<style scoped>
.steps {
	transition: all 0.3s ease-in-out;
}
.steps.active {
	opacity: 1;
}
.steps:not(.active) {
    cursor: pointer;
}
/* .page-header .btn-light rules removed as they are now global */

/* Transition for selected backup info */
.zoomReversed-enter-active,
.zoomReversed-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}
.zoomReversed-enter-from,
.zoomReversed-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>