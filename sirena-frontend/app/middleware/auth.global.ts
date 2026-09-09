// C:\sirena\sirena-frontend\app\middleware\auth.global.ts
import Cookies from 'js-cookie';
import { jwtDecode } from 'jwt-decode';

export default defineNuxtRouteMiddleware((to, from) => {
    // Solo ejecutamos en el cliente
    if (process.server) return;

    const token = Cookies.get('auth_token');

    // 1. Si no hay token y el usuario intenta ir a cualquier página que NO sea el login (/)
    if (!token && to.path !== '/') {
        return navigateTo('/');
    }

    if (token) {
        try {
            const decoded: any = jwtDecode(token);
            const now = Date.now() / 1000;

            // Token expirado
            if (decoded.exp && decoded.exp < now) {
                Cookies.remove('auth_token');
                return navigateTo('/');
            }

            // Token válido y quiere ir al login
            if (to.path === '/') {
                return navigateTo('/principal');
            }
        } catch {
            // Token corrupto
            Cookies.remove('auth_token');
            return navigateTo('/');
        }
    }
});
