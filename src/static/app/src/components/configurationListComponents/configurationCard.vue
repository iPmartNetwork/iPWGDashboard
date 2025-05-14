<script>
import {fetchGet} from "@/utilities/fetch.js";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import LocaleText from "@/components/text/localeText.vue";
import ProtocolBadge from "@/components/protocolBadge.vue";
import {GetLocale} from "@/utilities/locale.js";

export default {
	name: "ConfigurationCard",
	components: {ProtocolBadge, LocaleText},
	props: {
		c: {
			Name: String,
			Status: Boolean,
			PublicKey: String,
			PrivateKey: String
		},
		delay: String,
		display: String
	},
	data(){
		return{
			configurationToggling: false
		}
	},
	setup(){
		const dashboardConfigurationStore = DashboardConfigurationStore();
		return {dashboardConfigurationStore}
	},
	methods: {
		toggle(){
			this.configurationToggling = true;
			fetchGet("/api/toggleWireguardConfiguration", {
				configurationName: this.c.Name
			}, (res) => {
				if (res.status){
					this.dashboardConfigurationStore.newMessage("Server",
						`${this.c.Name} ${res.data ? 'is on':'is off'}`)
				}else{
					this.dashboardConfigurationStore.newMessage("Server",
						res.message, 'danger')
				}
				this.c.Status = res.data
				this.configurationToggling = false;
			})
		},
		GetLocale
	}
}
</script>

<template>
	<div class="col-12" :class="{'col-lg-6 col-xl-4 mb-4': this.display === 'Grid', 'mb-3': this.display === 'List'}">
		<div class="card h-100 shadow-sm configuration-card" :class="{ 'border-success': c.Status, 'border-danger': !c.Status }">
			<div class="card-header d-flex justify-content-between align-items-center bg-light py-2 px-3">
				<h5 class="mb-0 card-title text-truncate" :title="c.Name">
                    <i class="bi me-2" :class="c.Protocol === 'wg' ? 'bi-shield-lock-fill' : 'bi-incognito'"></i>
                    {{ c.Name }}
                </h5>
				<span class="badge fs-09" :class="c.Status ? 'bg-success-subtle text-success-emphasis' : 'bg-danger-subtle text-danger-emphasis'">
					<i class="bi me-1" :class="c.Status ? 'bi-check-circle-fill' : 'bi-x-circle-fill'"></i>
					{{ c.Status ? GetLocale('Running') : GetLocale('Stopped') }}
				</span>
			</div>
			<div class="card-body p-3">
				<div class="row mb-2">
					<div class="col-sm-7">
						<small class="text-muted d-block"><LocaleText t="Address"></LocaleText></small>
						<samp class="small">{{ c.Address || 'N/A' }}</samp>
					</div>
					<div class="col-sm-5">
						<small class="text-muted d-block"><LocaleText t="Listen Port"></LocaleText></small>
						<samp class="small">{{ c.ListenPort || 'N/A' }}</samp>
					</div>
				</div>
                <div class="row mb-3">
                    <div class="col-sm-7">
                        <small class="text-muted d-block"><LocaleText t="Connected / Total Peers"></LocaleText></small>
                        <samp class="small">{{ c.ConnectedPeers }} / {{ c.TotalPeers }}</samp>
                    </div>
                     <div class="col-sm-5">
                        <small class="text-muted d-block"><LocaleText t="Protocol"></LocaleText></small>
                        <span class="badge bg-secondary-subtle text-secondary-emphasis text-uppercase">{{ c.Protocol }}</span>
                    </div>
                </div>

				<div class="mb-2">
					<small class="text-muted d-block"><LocaleText t="Public Key"></LocaleText></small>
					<samp class="d-block text-truncate small" :title="c.PublicKey">{{ c.PublicKey || 'N/A' }}</samp>
				</div>
			</div>
			<div class="card-footer bg-white p-3">
                <div class="row text-center mb-2 g-1">
                    <div class="col-4">
                        <small class="text-muted d-block fs-08"><LocaleText t="Total Usage"></LocaleText></small>
                        <strong class="small">{{ c.DataUsage.Total > 0 ? c.DataUsage.Total.toFixed(2) : '0.00' }} GB</strong>
                    </div>
                    <div class="col-4">
                        <small class="text-muted d-block fs-08"><LocaleText t="Received"></LocaleText></small>
                        <strong class="text-primary small">{{ c.DataUsage.Receive > 0 ? c.DataUsage.Receive.toFixed(2) : '0.00' }} GB</strong>
                    </div>
                    <div class="col-4">
                        <small class="text-muted d-block fs-08"><LocaleText t="Sent"></LocaleText></small>
                        <strong class="text-success small">{{ c.DataUsage.Sent > 0 ? c.DataUsage.Sent.toFixed(2) : '0.00' }} GB</strong>
                    </div>
                </div>
				<RouterLink :to="'/configuration/' + c.Name + '/peers'" class="btn btn-primary btn-sm w-100">
					<LocaleText t="Manage Peers"></LocaleText> <i class="bi bi-arrow-right-short"></i>
				</RouterLink>
			</div>
		</div>
	</div>
</template>

<style scoped>
.configuration-card .card-title {
    max-width: calc(100% - 100px); /* Adjust based on badge width */
}
.configuration-card samp.small {
    font-size: 0.8rem; /* Smaller font for samp */
    word-break: break-all;
}
.fs-08 {
    font-size: 0.8em;
}
.fs-09 {
    font-size: 0.9em;
}
.fade-enter-active{
	transition-delay: v-bind(delay) !important;
}
</style>