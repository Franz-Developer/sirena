// C:\sirena\sirena-frontend\app\stores\catalogos.ts
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

                // 🔥 CAMBIO: Usar /constantes en lugar de /catalogos/ids
                const response = await $fetch<any>(
                    `${config.public.apiBase}/constantes`,
                    {
                        headers: { Authorization: `Bearer ${authStore.token}` },
                        params: {
                            // Obtener TODOS los tipos de constantes
                            limit: 1000, // Suficiente para todas las constantes
                            offset: 0
                        }
                    }
                );

                // 🔄 Transformar la respuesta al formato esperado
                const ids: CatalogoIds = {};
                for (const item of response.data) {
                    const tipo = item.tipo; // 'estado_id', 'tipo_moneda_id', etc.
                    if (!ids[tipo]) {
                        ids[tipo] = {};
                    }
                    ids[tipo][item.abreviatura] = item.id;
                }

                this.ids = ids;
                this.loaded = true;
                sessionStorage.setItem('catalogos_ids', JSON.stringify(ids));

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