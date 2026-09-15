// C:\sirena\sirena-frontend\app\middleware\auth.global.ts
import Cookies from 'js-cookie';
import { jwtDecode } from 'jwt-decode';

export default defineNuxtRouteMiddleware((to, from) => {
    if (process.server) return;

    const token = Cookies.get('auth_token');
    const sessionData = process.client ? sessionStorage.getItem('auth_data') : null;

    if (token && !sessionData) {
        console.warn('[auth] Cookie huérfana detectada. Eliminando sesión...');
        Cookies.remove('auth_token');
        if (process.client) {
            sessionStorage.removeItem('auth_data');
            localStorage.removeItem('auth_data');
        }
        return navigateTo('/');
    }

    if (!token && to.path !== '/') {
        if (process.client) {
            sessionStorage.removeItem('auth_data');
            localStorage.removeItem('auth_data');
        }
        return navigateTo('/');
    }

    if (token) {
        try {
            const decoded: any = jwtDecode(token);
            const now = Date.now() / 1000;

            // Token expirado
            if (decoded.exp && decoded.exp < now) {
                Cookies.remove('auth_token');
                if (process.client) {
                    sessionStorage.removeItem('auth_data');
                    localStorage.removeItem('auth_data');
                }
                return navigateTo('/');
            }

            // Token válido y quiere ir al login
            if (to.path === '/') {
                return navigateTo('/principal');
            }
        } catch {
            Cookies.remove('auth_token');
            if (process.client) {
                sessionStorage.removeItem('auth_data');
                localStorage.removeItem('auth_data');
            }
            return navigateTo('/');
        }
    }
});
