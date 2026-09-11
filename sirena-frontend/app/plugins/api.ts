// C:\sirena\sirena-frontend\app\plugins\api.ts
import Cookies from 'js-cookie';

export default defineNuxtPlugin((nuxtApp) => {
    const config = useRuntimeConfig();

    const apiFetcher = $fetch.create({
        baseURL: config.public.apiBase,
        onRequest({ options }) {
            const token = Cookies.get('auth_token');
            if (token) {
                // Creamos un nuevo objeto de headers para evitar conflictos de tipos
                options.headers = new Headers(options.headers);
                options.headers.set('Authorization', `Bearer ${token}`);
            }
        },
        onResponseError({ response }) {
            if (response.status === 401) {
                const authStore = useAuthStore();
                authStore.logout();
            }
        }
    });

    return {
        provide: {
            api: apiFetcher
        }
    };
});
