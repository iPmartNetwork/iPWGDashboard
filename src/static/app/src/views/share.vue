<script>
import {useRoute} from "vue-router";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import {fetchGet} from "@/utilities/fetch.js";
import {ref, onMounted} from "vue";
import QRCode from "qrcode";
import LocaleText from "@/components/text/localeText.vue";

export default {
	name: "share",
	components: {LocaleText},
	async setup(){
		const route = useRoute();
		const loaded = ref(false)
		const store = DashboardConfigurationStore();
		const theme = ref("");
		const peerConfiguration = ref(undefined);
		const blob = ref(new Blob())
		const qrcodeCanvas = ref(null);

		await fetchGet("/api/getDashboardTheme", {}, (res) => {
			theme.value = res.data
		});
		
		const id = route.query.ShareID
		if(id === undefined || id.length === 0){
			peerConfiguration.value = undefined
			loaded.value = true;
		}else{
			await fetchGet("/api/sharePeer/get", {
				ShareID: id
			}, (res) => {
				if (res.status){
					peerConfiguration.value = res.data;
					blob.value = new Blob([peerConfiguration.value.file], { type: "text/plain" });
				}else{
					peerConfiguration.value = undefined
				}
				loaded.value = true;
			})
		}

		onMounted(() => {
			if(peerConfiguration.value && qrcodeCanvas.value){
				QRCode.toCanvas(qrcodeCanvas.value, peerConfiguration.value.file, { width: 256, margin: 2 }, (error) => {
					if (error) console.error(error)
				})
			}
		});

		return {store, theme, peerConfiguration, blob, loaded, qrcodeCanvas}
	},
	computed:{
		getBlobUrl(){
			if (this.peerConfiguration && this.peerConfiguration.file) {
				const newBlob = new Blob([this.peerConfiguration.file], { type: "text/plain" });
				return URL.createObjectURL(newBlob);
			}
			return '#';
		},
		getFilename(){
			if (this.peerConfiguration && this.peerConfiguration.fileName) {
				return `${this.peerConfiguration.fileName}.conf`;
			}
			return 'config.conf';
		}
	}
}
</script>

<template>
	<div class="container-fluid login-container-fluid d-flex main pt-5 overflow-scroll vh-100"
	     :data-bs-theme="theme">
		<div class="m-auto text-body" style="max-width: 500px; width: 100%;">
			<div v-if="!loaded" class="text-center">
				<div class="spinner-border text-primary" role="status">
					<span class="visually-hidden"><LocaleText t="Loading..."></LocaleText></span>
				</div>
			</div>
			<div v-else>
				<div class="text-center position-relative" v-if="!peerConfiguration">
					<div class="animate__animated animate__fadeInUp">
						<h1 style="font-size: 15rem; filter: blur(0.8rem); animation-duration: 5s; opacity: 0.3;"
						    class="animate__animated animate__flash animate__infinite text-warning">
							<i class="bi bi-exclamation-triangle-fill"></i>
						</h1>
					</div>
					<div class="position-absolute w-100 h-100 top-0 start-0 d-flex animate__animated animate__fadeInUp"
						style="animation-delay: 0.1s;"
					>
						<div class="m-auto p-3 bg-body-tertiary rounded-3 shadow-sm">
							<h3 class="mb-0">
								<LocaleText t="Oh no... This link is either expired or invalid."></LocaleText>
							</h3>
						</div>
					</div>
				</div>
				<div v-else class="d-flex align-items-center flex-column gap-3 card shadow-sm p-4">
					<div class="h4 dashboardLogo text-center animate__animated animate__fadeInUp">
						<img src="/logo.png" alt="WGDashboard Logo" style="height: 40px; margin-bottom: 0.5rem;">
						<h6>WGDashboard</h6>
						<p class="text-muted small">
							<LocaleText t="Scan QR Code with the WireGuard App to add peer"></LocaleText>
						</p>
					</div>
					<canvas id="qrcode" class="rounded-3 shadow-sm animate__animated animate__fadeInUp mb-3" ref="qrcodeCanvas"></canvas>
					<p class="text-muted text-center animate__animated animate__fadeInUp mb-1"
					   style="animation-delay: 0.2s;">
						<LocaleText t="or click the button below to download the "></LocaleText>
						<samp>.conf</samp>
						<LocaleText t=" file"></LocaleText>
					</p>
					<a
						:download="getFilename"
						:href="getBlobUrl"
						class="btn btn-lg btn-primary animate__animated animate__fadeInUp shadow-sm w-100"
					    style="animation-delay: 0.25s;"
					>
						<i class="bi bi-download me-2"></i> <LocaleText t="Download Configuration"></LocaleText>
					</a>
				</div>
			</div>
		</div>
	</div>
</template>

<style scoped>
	.animate__fadeInUp{
		animation-timing-function: cubic-bezier(0.42, 0, 0.22, 1.0)
	}
	.login-container-fluid {
		background: var(--bs-body-bg); /* Fallback for older browsers */
        background: linear-gradient(135deg, var(--bs-primary-bg-subtle) 0%, var(--bs-body-bg) 100%);
	}
    .dashboardLogo img {
        filter: drop-shadow(0 2px 2px rgba(0,0,0,0.1));
    }
    #qrcode {
        border: 1px solid var(--bs-border-color-translucent);
    }
</style>