// C:\sirena\sirena-frontend\app\plugins\catalogos.ts
import { useCatalogosStore } from '~/stores/catalogos';
import { useAuthStore } from '~/stores/auth';

export default defineNuxtPlugin(async () => {
    const catalogosStore = useCatalogosStore();
    const authStore = useAuthStore();

    const loadCatalogos = async () => {
        await catalogosStore.fetchIds();
    };

    if (authStore.token) {
        await loadCatalogos();
    }

    watch(
        () => authStore.token,
        async (newToken, oldToken) => {
            if (newToken && !catalogosStore.isReady) {
                await loadCatalogos();
            }

            if (!newToken && oldToken) {
                catalogosStore.clear();
            }
        }
    );
});
