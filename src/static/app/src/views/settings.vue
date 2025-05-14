<script>
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import PeersDefaultSettingsInput from "@/components/settingsComponent/peersDefaultSettingsInput.vue";
// import {ipV46RegexCheck} from "@/utilities/ipCheck.js"; // Not used in template, can be removed if not used by children
import AccountSettingsInputUsername from "@/components/settingsComponent/accountSettingsInputUsername.vue";
import AccountSettingsInputPassword from "@/components/settingsComponent/accountSettingsInputPassword.vue";
import DashboardSettingsInputWireguardConfigurationPath
	from "@/components/settingsComponent/dashboardSettingsInputWireguardConfigurationPath.vue";
import DashboardTheme from "@/components/settingsComponent/dashboardTheme.vue";
// import DashboardSettingsInputIPAddressAndPort from "@/components/settingsComponent/dashboardSettingsInputIPAddressAndPort.vue"; // Replaced by DashboardIPPortInput
import DashboardAPIKeys from "@/components/settingsComponent/dashboardAPIKeys.vue";
import AccountSettingsMFA from "@/components/settingsComponent/accountSettingsMFA.vue";
import LocaleText from "@/components/text/localeText.vue";
import DashboardLanguage from "@/components/settingsComponent/dashboardLanguage.vue";
import DashboardIPPortInput from "@/components/settingsComponent/dashboardIPPortInput.vue";
import DashboardSettingsWireguardConfigurationAutostart
	from "@/components/settingsComponent/dashboardSettingsWireguardConfigurationAutostart.vue";
import DashboardEmailSettings from "@/components/settingsComponent/dashboardEmailSettings.vue";

export default {
	name: "settings",
	// methods: {ipV46RegexCheck}, // Not used directly in this component's template
	components: {
		DashboardEmailSettings,
		DashboardSettingsWireguardConfigurationAutostart,
		DashboardIPPortInput,
		DashboardLanguage,
		LocaleText,
		AccountSettingsMFA,
		DashboardAPIKeys,
		// DashboardSettingsInputIPAddressAndPort, // Replaced
		DashboardTheme,
		DashboardSettingsInputWireguardConfigurationPath,
		AccountSettingsInputPassword, AccountSettingsInputUsername, PeersDefaultSettingsInput},
	setup(){
		const dashboardConfigurationStore = DashboardConfigurationStore()
		return {dashboardConfigurationStore}
	},
	data(){
		return{
			activeTab: "WGDashboard",
			tabs: [
				{
					id: "WGDashboard",
					title: "WGDashboard Settings",
					icon: "bi-gear-wide-connected"
				},
				{
					id: "Peers",
					title: "Peers Settings",
					icon: "bi-people-fill"
				},
				{
					id: "WireGuardConfiguration",
					title: "WireGuard Configuration Settings",
					icon: "bi-hdd-stack-fill"
				}
			]
		}
	}
}
</script>

<template>
	<div class="mt-md-4 mt-3 text-body mb-5">
		<div class="container-xl d-flex flex-column gap-4">
			<div class="page-header mb-2">
				<h2 class="mb-0"><i class="bi bi-sliders me-2"></i> <LocaleText t="Settings"></LocaleText></h2>
			</div>
			<div>
				<ul class="nav nav-pills nav-justified nav-fill align-items-center gap-2 mb-4 border-bottom pb-3">
					<li class="nav-item" v-for="t in tabs" :key="t.id">
						<a class="nav-link rounded-pill d-flex align-items-center justify-content-center gap-2 p-3"
						   @click="activeTab = t.id"
						   :class="{active: activeTab === t.id, 'bg-body-secondary text-body': activeTab !== t.id }"
						   role="button">
							<i :class="t.icon" style="font-size: 1.2rem;"></i>
							<span class="fw-medium">
								<LocaleText :t="t.title"></LocaleText>
							</span>
						</a>
					</li>
				</ul>

				<div>
					<Transition name="fade2" mode="out-in">
						<div class="d-flex gap-3 flex-column" v-if="activeTab === 'WireGuardConfiguration'">
							<DashboardSettingsInputWireguardConfigurationPath
								targetData="wg_conf_path"
								title="Configurations Directory"
								:warning="true"
								warning-text="Remember to remove / at the end of your path. e.g /etc/wireguard"
							>
							</DashboardSettingsInputWireguardConfigurationPath>
							<DashboardSettingsWireguardConfigurationAutostart></DashboardSettingsWireguardConfigurationAutostart>
						</div>
						<div class="d-flex gap-3 flex-column" v-else-if="activeTab === 'Peers'">
							<div class="card rounded-3 shadow-sm">
								<div class="card-header bg-light-subtle">
									<h5 class="my-2">
										<LocaleText t="Peer Default Settings"></LocaleText>
									</h5>
								</div>
								<div class="card-body p-4">
									<div class="d-flex flex-column gap-3">
										<PeersDefaultSettingsInput
											targetData="peer_global_dns" title="DNS"></PeersDefaultSettingsInput>
										<PeersDefaultSettingsInput
											targetData="peer_endpoint_allowed_ip" title="Endpoint Allowed IPs"></PeersDefaultSettingsInput>
										<PeersDefaultSettingsInput
											targetData="peer_mtu" title="MTU"></PeersDefaultSettingsInput>
										<PeersDefaultSettingsInput
											targetData="peer_keep_alive" title="Persistent Keepalive"></PeersDefaultSettingsInput>
										<PeersDefaultSettingsInput
											targetData="remote_endpoint" title="Peer Remote Endpoint"
											:warning="true" warningText="This will be changed globally, and will be apply to all peer's QR code and configuration file."
										></PeersDefaultSettingsInput>
									</div>
								</div>
							</div>
						</div>
						<div class="d-flex gap-4 flex-column" v-else-if="activeTab === 'WGDashboard'">
							<div class="card rounded-3 shadow-sm">
								<div class="card-header bg-light-subtle">
									<h5 class="my-2">
										<LocaleText t="Appearance"></LocaleText>
									</h5>
								</div>
								<div class="card-body p-4">
									<div class="row g-3">
										<div class="col-md-6">
											<DashboardTheme></DashboardTheme>
										</div>
										<div class="col-md-6">
											<DashboardLanguage></DashboardLanguage>
										</div>
									</div>
								</div>
							</div>
							<div class="card rounded-3 shadow-sm">
								<div class="card-header bg-light-subtle">
									<h5 class="my-2">
										<LocaleText t="Dashboard IP Address & Listen Port"></LocaleText>
									</h5>
								</div>
								<div class="card-body p-4">
									<DashboardIPPortInput></DashboardIPPortInput>
								</div>
							</div>
							<div class="card rounded-3 shadow-sm">
								<div class="card-header bg-light-subtle">
									<h5 class="my-2">
										<LocaleText t="Account Settings"></LocaleText>
									</h5>
								</div>
								<div class="card-body p-4 d-flex flex-column gap-4">
									<div>
										<AccountSettingsInputUsername targetData="username"
										                              title="Username"
										></AccountSettingsInputUsername>
									</div>
									<hr class="my-0">
									<div>
										<AccountSettingsInputPassword
											targetData="password">
										</AccountSettingsInputPassword>
									</div>
								</div>
							</div>
							<div class="card rounded-3 shadow-sm">
								<div class="card-header bg-light-subtle">
									<h5 class="my-2">
										<LocaleText t="Multi-Factor Authentication (MFA)"></LocaleText>
									</h5>
								</div>
								<div class="card-body p-4">
									<AccountSettingsMFA v-if="!this.dashboardConfigurationStore.getActiveCrossServer()"></AccountSettingsMFA>
									<div v-else class="alert alert-info">
										<LocaleText t="MFA settings are managed by the main server in a cross-server setup."></LocaleText>
									</div>
								</div>
							</div>
							<DashboardAPIKeys></DashboardAPIKeys>
							<DashboardEmailSettings></DashboardEmailSettings>
						</div>
					</Transition>
				</div>
			</div>
		</div>
	</div>
</template>

<style scoped>
.nav-pills .nav-link.active, .nav-pills .show > .nav-link {
    background-color: var(--bs-primary);
    color: var(--bs-white);
}
.nav-pills .nav-link:not(.active):hover {
    background-color: var(--bs-secondary-bg);
}
.card-header {
    border-bottom: 1px solid var(--bs-border-color-translucent);
}
</style>