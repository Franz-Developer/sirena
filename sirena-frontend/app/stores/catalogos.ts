import { defineStore } from 'pinia';
import { useAuthStore } from '~/stores/auth';

type CatalogoIds = Record<string, Record<string, number>>;

export const useCatalogosStore = defineStore('catalogos', {
    state: () => ({
        ids: {} as CatalogoIds,
        loading: false,
        loaded: false
    }),

    actions: {
        async fetchIds() {
        if (this.loaded || this.loading) return;
        if (import.meta.server) return;
        const authStore = useAuthStore();
        if (!authStore.token) return;
        const cached = sessionStorage.getItem('catalogos_ids');

        if (cached) {
            try {
                this.ids = JSON.parse(cached);
                this.loaded = true;
                return;
            } catch {
                sessionStorage.removeItem('catalogos_ids');
            }
        }
        this.loading = true;

        try {
            const config = useRuntimeConfig();
            const data = await $fetch<CatalogoIds>( `${config.public.apiBase}/catalogos/ids`,
                {
                    headers: {
                        Authorization: `Bearer ${authStore.token}`
                    }
                }
            );
            this.ids = data;
            this.loaded = true;
            sessionStorage.setItem('catalogos_ids', JSON.stringify(data));
        } catch (error) {
            console.error('Error cargando catálogo:', error);
        } finally {
            this.loading = false;
        }
        },
        clear() {
            this.ids = {};
            this.loaded = false;
            if (import.meta.client) {
                sessionStorage.removeItem('catalogos_ids');
            }
        }
    },

    getters: {
        isReady: (state) => state.loaded,
        getId: (state) => (grupo: string, clave: string) =>
        state.ids?.[grupo]?.[clave]
    }
});
