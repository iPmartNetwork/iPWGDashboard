<template>
	<div class="card shadow-sm rounded-3 peer-card mb-3"
		:class="{
            'border-warning text-warning-emphasis': Peer.restricted, 
            'border-success': !Peer.restricted && Peer.status === 'running', 
            'border-secondary': !Peer.restricted && Peer.status !== 'running'
        }">
		<div class="card-header bg-transparent py-2 px-3">
			<div class="d-flex align-items-center">
                <div v-if="!Peer.restricted" class="d-flex align-items-center flex-grow-1 overflow-hidden">
                    <span class="dot me-2 flex-shrink-0" :class="{ 'bg-success': Peer.status === 'running', 'bg-danger': Peer.status !== 'running' }"></span>
                    <h6 class="mb-0 text-truncate" :title="Peer.name || GetLocale('Untitled Peer')">
                        {{ Peer.name || GetLocale('Untitled Peer') }}
                    </h6>
                </div>
                <div v-else class="d-flex align-items-center flex-grow-1">
                    <i class="bi bi-lock-fill me-2"></i>
                    <h6 class="mb-0">
                        <LocaleText t="Access Restricted"></LocaleText>
                    </h6>
                </div>

				<div class="ms-auto flex-shrink-0">
					<PeerSettingsDropdown
						@qrcode="$emit('qrcode', Peer)"
						@configurationFile="$emit('configurationFile', Peer)"
						@setting="$emit('setting', Peer)"
						@jobs="$emit('jobs', Peer)"
						@refresh="$emit('refresh')"
						@share="$emit('share', Peer)"
						:Peer="Peer"
                        @deletePeerConfirmation="$emit('deletePeerConfirmation', Peer)"
                        @toggleRestrictPeer="$emit('toggleRestrictPeer', Peer)"
					/>
				</div>
			</div>
		</div>

		<div class="card-body py-2 px-3 small" v-if="!Peer.restricted">
			<div class="row g-2">
				<div :class="dashboardStore.Configuration.Server.dashboard_peer_list_display === 'grid' ? 'col-12' : 'col-lg-6'">
					<small class="text-muted d-block"><LocaleText t="Public Key"></LocaleText></small>
					<samp class="d-block text-truncate" :title="Peer.id">{{ Peer.id }}</samp>
				</div>
				<div :class="dashboardStore.Configuration.Server.dashboard_peer_list_display === 'grid' ? 'col-12' : 'col-lg-6'">
					<small class="text-muted d-block"><LocaleText t="Allowed IPs"></LocaleText></small>
					<samp class="d-block text-truncate" :title="Peer.allowed_ip">{{ Peer.allowed_ip }}</samp>
				</div>
                <div v-if="Peer.status === 'running' && Peer.endpoint !== 'N/A'" 
                     :class="dashboardStore.Configuration.Server.dashboard_peer_list_display === 'grid' ? 'col-12' : 'col-lg-6'">
                    <small class="text-muted d-block"><LocaleText t="Endpoint"></LocaleText></small>
                    <samp class="d-block text-truncate" :title="Peer.endpoint">
                        <i class="bi bi-box-arrow-in-right me-1 text-success-emphasis"></i>{{ Peer.endpoint }}
                    </samp>
                </div>
                 <div :class="dashboardStore.Configuration.Server.dashboard_peer_list_display === 'grid' ? 'col-12' : 'col-lg-6'">
                    <small class="text-muted d-block"><LocaleText t="Latest Handshake"></LocaleText></small>
                    <samp class="d-block">
                        <i class="bi bi-clock-history me-1"></i>
                        {{ Peer.latest_handshake !== 'No Handshake' ? getLatestHandshake + ' ' + GetLocale('ago') : GetLocale('No Handshake') }}
                    </samp>
                </div>
			</div>
		</div>
        <div class="card-footer bg-transparent py-2 px-3" v-if="!Peer.restricted">
            <div class="row text-center g-1 small">
                <div class="col">
                    <small class="text-muted d-block fs-08"><LocaleText t="Received"></LocaleText></small>
                    <strong class="text-primary-emphasis">{{ (Peer.cumu_receive + Peer.total_receive).toFixed(2) }} GB</strong>
                </div>
                <div class="col">
                    <small class="text-muted d-block fs-08"><LocaleText t="Sent"></LocaleText></small>
                    <strong class="text-success-emphasis">{{ (Peer.cumu_sent + Peer.total_sent).toFixed(2) }} GB</strong>
                </div>
                 <div class="col">
                    <small class="text-muted d-block fs-08"><LocaleText t="Total"></LocaleText></small>
                    <strong>{{ (Peer.cumu_data + Peer.total_data).toFixed(2) }} GB</strong>
                </div>
            </div>
        </div>
	</div>
</template>

<script>
import PeerSettingsDropdown from "@/components/configurationComponents/peerSettingsDropdown.vue";
import LocaleText from "@/components/text/localeText.vue";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import {GetLocale} from "../../utilities/locale.js";

export default {
	name: "peer",
	methods: {GetLocale},
	components: {LocaleText, PeerSettingsDropdown},
	props: {
		Peer: Object
	},
	setup(){
		const dashboardStore = DashboardConfigurationStore();
		return { dashboardStore }
	},
	computed: {
		getLatestHandshake(){
			if (this.Peer.latest_handshake && this.Peer.latest_handshake.includes(",")){
				return this.Peer.latest_handshake.split(",")[0];
			}
			return this.Peer.latest_handshake;
		}
	}
}
</script>

<style scoped>
.peer-card {
    transition: all 0.2s ease-in-out;
}
.peer-card:hover {
    transform: translateY(-2px);
    box-shadow: var(--bs-box-shadow-lg) !important;
}
.peer-card samp {
    font-size: 0.9em; /* Adjusted for overall smaller card text */
    word-break: break-all;
}
.peer-card .card-header h6 {
    /* Ensure text truncation works well */
}
.dot {
  height: 10px;
  width: 10px;
  border-radius: 50%;
  display: inline-block;
}
.fs-08 {
    font-size: 0.8em;
}
/* ... any other existing styles ... */
</style>