<script>
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import {fetchPost} from "@/utilities/fetch.js";
import LocaleText from "@/components/text/localeText.vue";
export default {
	name: "setup",
	components: {LocaleText},
	setup(){
		const store = DashboardConfigurationStore();
		return {store}
	},
	data(){
		return {
			setup: {
				username: "",
				newPassword: "",
				repeatNewPassword: "",
				enable_totp: true // Defaulting to true, UI for this is commented out
			},
			loading: false,
			errorMessage: "",
			done: false
		}
	},
	computed: {
		goodToSubmit(){
			return this.setup.username.trim()
				&& this.setup.newPassword.length >= 8
				&& this.setup.repeatNewPassword.length >= 8
				&& this.setup.newPassword === this.setup.repeatNewPassword
		}
	},
	methods: {
		submit(){
			this.loading = true
			this.errorMessage = ""; // Clear previous error
			fetchPost("/api/Welcome_Finish", this.setup, (res) => {
				if (res.status){
					this.done = true;
					// Assuming 2FASetup is the next step if TOTP is enabled by default
					this.$router.push('/2FASetup');
				}else{
					document.querySelectorAll("#createAccount input").forEach(x => x.classList.add("is-invalid"))
					this.errorMessage = res.message || "An unknown error occurred.";
					// Scroll to top to make error message visible
					const container = document.querySelector(".login-container-fluid");
					if (container) {
						container.scrollTo({
							top: 0,
							left: 0,
							behavior: "smooth",
						});
					}
				}
				this.loading = false
			})
		}
	}
}
</script>

<template>
	<div class="container-fluid login-container-fluid d-flex main pt-5 pb-5 overflow-scroll vh-100"
	     :data-bs-theme="this.store.Configuration.Server.dashboard_theme || 'auto'">
		<div class="m-auto text-body p-4 p-md-5 rounded-3 shadow-lg bg-body-tertiary" style="max-width: 550px; width: 100%;">
			<div class="text-center mb-4">
				<img src="/logo.png" alt="WGDashboard Logo" style="height: 50px; margin-bottom: 1rem;">
				<h1 class="dashboardLogo h3">
					<LocaleText t="Nice to meet you!"></LocaleText>
				</h1>
				<p class="mb-4 text-muted">
					<LocaleText t="Please fill in the following fields to finish setup"></LocaleText>
					😊
				</p>
			</div>

			<div v-if="this.errorMessage" class="alert alert-danger alert-dismissible fade show" role="alert">
				<i class="bi bi-exclamation-triangle-fill me-2"></i> {{this.errorMessage}}
				<button type="button" class="btn-close" @click="this.errorMessage = ''" aria-label="Close"></button>
			</div>

			<form id="createAccount" @submit.prevent="submit" class="d-flex flex-column gap-3">
				<div class="form-floating">
					<input type="text"
					       autocomplete="username"
					       v-model.trim="this.setup.username"
					       class="form-control" id="username" name="username" placeholder="Enter an username" required>
					<label for="username">
						<LocaleText t="Username"></LocaleText>
					</label>
				</div>
				<div class="form-floating">
					<input type="password"
					       autocomplete="new-password"
					       v-model="this.setup.newPassword"
					       class="form-control" id="password" name="password" placeholder="Enter a password" required>
					<label for="password">
						<LocaleText t="Password"></LocaleText>
					</label>
					<div class="form-text ps-2">
						<LocaleText t="(At least 8 characters and make sure is strong enough!)"></LocaleText>
					</div>
				</div>
				<div class="form-floating">
					<input type="password"
					       autocomplete="confirm-new-password"
					       v-model="this.setup.repeatNewPassword"
					       class="form-control" id="confirmPassword" name="confirmPassword" placeholder="Confirm password" required>
					<label for="confirmPassword">
						<LocaleText t="Confirm password"></LocaleText>
					</label>
				</div>

				<!-- TOTP Section is commented out in original, keeping it that way -->
				<!-- <div class="form-check form-switch mt-3">
					<input class="form-check-input" type="checkbox" role="switch" id="enable_totp"
					       v-model="this.setup.enable_totp">
					<label class="form-check-label"
					       for="enable_totp">Enable 2 Factor Authentication? <strong>Strongly recommended</strong></label>
				</div> -->

				<button class="btn btn-primary btn-lg mt-4 d-flex align-items-center justify-content-center"
				        type="submit"
				        :disabled="!this.goodToSubmit || this.loading || this.done">
					<span v-if="!this.loading && !this.done" class="d-flex align-items-center">
						<LocaleText t="Next"></LocaleText>
						<i class="bi bi-chevron-right ms-2"></i>
					</span>
					<span v-else-if="this.done" class="d-flex align-items-center">
						<LocaleText t="Redirecting..."></LocaleText>
						<i class="bi bi-check-circle-fill ms-2"></i>
					</span>
					<span v-else class="d-flex align-items-center">
						<LocaleText t="Saving..."></LocaleText>
						<span class="spinner-border ms-2 spinner-border-sm" role="status">
						  <span class="visually-hidden"><LocaleText t="Loading..."></LocaleText></span>
						</span>
					</span>
				</button>
			</form>
		</div>
	</div>
</template>

<style scoped>
.login-container-fluid {
    background: var(--bs-light); /* Fallback for older browsers */
    background: linear-gradient(135deg, var(--bs-primary-bg-subtle) 0%, var(--bs-tertiary-bg) 100%);
}
.form-text {
    font-size: 0.875em;
}
.dashboardLogo img {
    filter: drop-shadow(0 2px 2px rgba(0,0,0,0.1));
}
</style>