<script>
import Navbar from "@/components/navbar.vue";
import {DashboardConfigurationStore} from "@/stores/DashboardConfigurationStore.js";
import Message from "@/components/messageCentreComponent/message.vue";
import { computed, watch } from "vue";
import { useRoute } from "vue-router";

// برای اعمال استایل‌های سراسری، فایل global.css را ایمپورت کنید.
// مثال: import '@/assets/css/global.css'; (مسیر را مطابق با ساختار پروژه خود تنظیم کنید)

export default {
	name: "index",
	components: {Message, Navbar},
	setup(){
		const dashboardConfigurationStore = DashboardConfigurationStore();
        const route = useRoute();

        // Apply theme to HTML element for global theme consistency (e.g. modals not in this component)
        watch(() => dashboardConfigurationStore.Configuration.Server.dashboard_theme, (newTheme) => {
            if (document.documentElement) {
                document.documentElement.setAttribute('data-bs-theme', newTheme || 'auto');
            }
        }, { immediate: true });

        // Apply language to HTML element for global lang consistency
         watch(() => dashboardConfigurationStore.Configuration.Server.dashboard_language, (newLang) => {
            if (document.documentElement) {
                document.documentElement.setAttribute('lang', newLang || 'en');
            }
        }, { immediate: true });


		const getMessages = computed(() => {
			return dashboardConfigurationStore.Messages.filter(x => x.show);
		});

		return { dashboardConfigurationStore, getMessages, route };
	}
}
</script>

<template>
	<div class="container-fluid d-flex flex-column vh-100 p-0 main-wrapper" :data-bs-theme="dashboardConfigurationStore.Configuration.Server.dashboard_theme || 'auto'">
		<div class="row g-0 flex-grow-1">
			<Navbar class="col-md-3 col-lg-2 d-md-block bg-body-tertiary sidebar collapse"></Navbar>
			<main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 py-3 overflow-y-scroll main-content">
				<Suspense>
					<RouterView v-slot="{Component}">
						<Transition name="fade-router" mode="out-in" appear>
							<Component :is="Component" :key="route.path"></Component>
						</Transition>
					</RouterView>
                    <template #fallback>
                        <div class="d-flex justify-content-center align-items-center" style="min-height: 80vh;">
                            <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                                <span class="visually-hidden">Loading page...</span>
                            </div>
                        </div>
                    </template>
				</Suspense>
			</main>
		</div>
		<div class="messageCentre text-body position-fixed bottom-0 end-0 p-3 d-flex" style="z-index: 1100;">
			<TransitionGroup name="message-transition" tag="div"
			                 class="d-flex flex-column align-items-end gap-2">
				<Message v-for="m in getMessages.slice().reverse()"
				         :message="m" :key="m.id"></Message>
			</TransitionGroup>
		</div>
	</div>
</template>

<style>
/* استایل‌های عمومی به فایل src/assets/css/global.css منتقل شدند. */
/* لطفاً آن فایل را در main.js یا App.vue ایمپورت کنید. */
</style>