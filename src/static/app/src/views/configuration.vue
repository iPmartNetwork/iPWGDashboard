<script>
export default {
	name: "configuration", // This view acts as a layout/router-view for nested configuration routes
}
</script>

<template>
	<div class="text-body">
		<RouterView v-slot="{ Component, route }">
			<Transition name="fade-fast" mode="out-in">
				<Suspense>
					<Component :is="Component" :key="route.path"></Component>
                    <template #fallback>
                        <div class="d-flex justify-content-center align-items-center" style="min-height: 70vh;">
                            <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                                <span class="visually-hidden">Loading configuration section...</span>
                            </div>
                        </div>
                    </template>
				</Suspense>
			</Transition>
		</RouterView>
	</div>
</template>

<style scoped>
.fade-fast-enter-active,
.fade-fast-leave-active {
  transition: opacity 0.15s ease-in-out;
}
.fade-fast-enter-from,
.fade-fast-leave-to {
  opacity: 0;
}
</style>