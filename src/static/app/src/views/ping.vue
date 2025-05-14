<script>
import {fetchGet} from "@/utilities/fetch.js";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import LocaleText from "@/components/text/localeText.vue";
import OSMap from "@/components/map/osmap.vue";

export default {
	name: "ping",
	components: {OSMap, LocaleText},
	data(){
		return {
			loading: false,
			cips: {},
			selectedConfiguration: undefined,
			selectedPeer: undefined,
			selectedIp: undefined,
			count: 4,
			pingResult: undefined,
			pinging: false
		}
	},
	setup(){
		const store = DashboardConfigurationStore();
		return {store}
	},
	mounted() {
		fetchGet("/api/ping/getAllPeersIpAddress", {}, (res)=> {
			if (res.status){
				this.loading = true;
				this.cips = res.data;
				console.log(this.cips)
			}
		});
	},
	methods: {
		execute(){
			if (this.selectedIp){
				this.pinging = true;
				this.pingResult = undefined
				fetchGet("/api/ping/execute", {
					ipAddress: this.selectedIp,
					count: this.count
				}, (res) => {
					if (res.status){
						this.pingResult = res.data
					}else{
						this.store.newMessage("Server", res.message, "danger")
					}
					this.pinging = false
				})
				
			}
{}		}	
	},
	watch: {
		selectedConfiguration(){
			this.selectedPeer = undefined;
			this.selectedIp = undefined;
		},
		selectedPeer(){
			this.selectedIp = undefined;
		}
	}
}
</script>

<template>
	<div class="mt-md-4 mt-3 text-body mb-5">
		<div class="container-xl">
            <div class="page-header mb-4">
                <h2 class="mb-0"><i class="bi bi-activity me-2"></i> <LocaleText t="Network Ping Tool"></LocaleText></h2>
            </div>

			<div class="row justify-content-center">
				<div class="col-lg-6 col-md-8">
                    <div class="card shadow-sm">
                        <div class="card-body p-4">
                            <div class="d-flex flex-column gap-3">
                                <div>
                                    <label class="form-label" for="configuration">
                                        <LocaleText t="Select Configuration (Optional)"></LocaleText>
                                    </label>
                                    <select class="form-select" id="configuration" v-model="this.selectedConfiguration" :disabled="this.pinging">
                                        <option :value="undefined" selected><LocaleText t="-- Select Configuration --"></LocaleText></option>
                                        <option :value="key" v-for="(val, key) in this.cips" :key="key">
                                            {{key}}
                                        </option>
                                    </select>
                                </div>
                                <div>
                                    <label class="form-label" for="peer">
                                        <LocaleText t="Select Peer (Optional)"></LocaleText>
                                    </label>
                                    <select id="peer" class="form-select" v-model="this.selectedPeer" :disabled="!this.selectedConfiguration || this.pinging">
                                        <option :value="undefined" selected><LocaleText t="-- Select Peer --"></LocaleText></option>
                                        <option v-if="this.selectedConfiguration !== undefined && this.cips[this.selectedConfiguration]" :value="key" v-for="(peer, key) in this.cips[this.selectedConfiguration]" :key="key">
                                            {{key}} ({{ peer.allowed_ips.join(', ') }})
                                        </option>
                                    </select>
                                </div>
                                <div>
                                    <label class="form-label" for="ip">
                                        <LocaleText t="Select IP Address (from Peer)"></LocaleText>
                                    </label>
                                    <select id="ip" class="form-select" v-model="this.selectedIp" :disabled="!this.selectedPeer || this.pinging">
                                        <option :value="undefined" selected><LocaleText t="-- Select IP from Peer --"></LocaleText></option>
                                        <option
                                            v-if="this.selectedPeer !== undefined && this.cips[this.selectedConfiguration] && this.cips[this.selectedConfiguration][this.selectedPeer]"
                                            v-for="ip in this.cips[this.selectedConfiguration][this.selectedPeer].allowed_ips" :key="ip">
                                            {{ip}}
                                        </option>
                                    </select>
                                </div>

                                <div class="d-flex align-items-center gap-2 my-2">
                                    <div class="flex-grow-1 border-top"></div>
                                    <small class="text-muted">
                                        <LocaleText t="OR"></LocaleText>
                                    </small>
                                    <div class="flex-grow-1 border-top"></div>
                                </div>

                                <div>
                                    <label class="form-label" for="ipAddress">
                                        <LocaleText t="Enter IP Address / Hostname"></LocaleText>
                                    </label>
                                    <input class="form-control" type="text"
                                           id="ipAddress"
                                           :disabled="this.pinging"
                                           v-model="this.selectedIp"
                                           :placeholder="GetLocale('e.g., 1.1.1.1 or example.com')">
                                </div>

                                <div class="mt-3">
                                    <button class="btn btn-primary w-100 btn-lg" @click="executePing" :disabled="this.pinging || !this.selectedIp">
                                        <span v-if="this.pinging" class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                                        <i v-else class="bi bi-send me-2"></i>
                                        <LocaleText t="Ping"></LocaleText>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div v-if="pingResult" class="card shadow-sm mt-4">
                        <div class="card-header">
                            <h5 class="mb-0"><LocaleText t="Ping Results for"></LocaleText> <span class="text-primary">{{ pingResult.address }}</span></h5>
                        </div>
                        <div class="card-body">
                            <ul class="list-group list-group-flush">
                                <li class="list-group-item d-flex justify-content-between align-items-center">
                                    <LocaleText t="Status"></LocaleText>
                                    <span :class="pingResult.is_alive ? 'badge bg-success' : 'badge bg-danger'">
                                        <LocaleText :t="pingResult.is_alive ? 'Alive' : 'Not Reachable'"></LocaleText>
                                    </span>
                                </li>
                                <li class="list-group-item d-flex justify-content-between align-items-center" v-if="pingResult.is_alive">
                                    <LocaleText t="Packets Sent/Received"></LocaleText>
                                    <span>{{ pingResult.package_sent }} / {{ pingResult.package_received }}</span>
                                </li>
                                <li class="list-group-item d-flex justify-content-between align-items-center" v-if="pingResult.is_alive">
                                    <LocaleText t="Packet Loss"></LocaleText>
                                    <span>{{ pingResult.package_loss }}%</span>
                                </li>
                                <li class="list-group-item d-flex justify-content-between align-items-center" v-if="pingResult.is_alive">
                                    <LocaleText t="Min/Avg/Max RTT"></LocaleText>
                                    <span>{{ pingResult.min_rtt }} / {{ pingResult.avg_rtt }} / {{ pingResult.max_rtt }} ms</span>
                                </li>
                                <li class="list-group-item d-flex justify-content-between align-items-center" v-if="pingResult.geo && pingResult.geo.city">
                                    <LocaleText t="Approx. Location"></LocaleText>
                                    <span>{{ pingResult.geo.city }}</span>
                                </li>
                            </ul>
                            <pre v-if="pingError" class="mt-3 alert alert-danger">{{ pingError }}</pre>
                        </div>
                    </div>
				</div>
			</div>
		</div>
	</div>
</template>

<style scoped>
	.pingPlaceholder{
		width: 100%;
		height: 79.98px;
	}
	.ping-move,
	.ping-enter-active,
	.ping-leave-active {
		transition: all 0.4s cubic-bezier(0.82, 0.58, 0.17, 0.9);
	}

	.ping-leave-active{
		position: absolute;
		width: 100%;
	}
	.ping-enter-from,
	.ping-leave-to {
		opacity: 0;
		filter: blur(3px);
	}
</style>