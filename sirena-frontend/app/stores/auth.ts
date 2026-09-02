// C:\sirena\sirena-frontend\app\stores\auth.ts
import { defineStore } from 'pinia';
import Cookies from 'js-cookie';
import { safeJSONParse } from '../utils/safe-json';
import type { MenuItem } from '../types/menu';

interface PermisosMap {
    [menuTitulo: string]: {
        crear: boolean;
        editar: boolean;
        eliminar: boolean;
        archivar?: boolean;
        desarchivar?: boolean;
    };
}

interface AuthData {
    user: any;
    token: string;
    menu: MenuItem[];
    permisos: PermisosMap;
}

export const useAuthStore = defineStore('auth', {
    state: () => {
        const isClient = process.client;
        const authData = isClient ? (safeJSONParse(localStorage.getItem('auth_data'), null) as AuthData | null) : null;

        return {
            user: authData?.user || null,
            menu: authData?.menu || ([] as MenuItem[]),
            token: authData?.token || (isClient ? Cookies.get('auth_token') : null) || null,
            permisos: authData?.permisos || {} as PermisosMap
        };
    },

    getters: {
        isLoggedIn: (state) => !!state.token,
        can: (state) => (menuTitulo: string, accion: string) => {
            if (state.user?.rolCodigo === 'ADM') return true;
            return state.permisos[menuTitulo]?.[accion as keyof PermisosMap[string]] === true;
        }
    },

    actions: {
        startSession(userData: any, token: string, menuData: MenuItem[], permisosData: PermisosMap) {
            this.user = userData;
            this.token = token;
            this.menu = menuData;
            this.permisos = permisosData;

            Cookies.set('auth_token', token, {
                expires: 1,
                path: '/',
                sameSite: 'Lax',
                secure: false,
            });

            if (process.client) {
                localStorage.setItem('auth_data', JSON.stringify({
                    user: userData,
                    token: token,
                    menu: menuData,
                    permisos: permisosData
                }));
            }
        },

        logout() {
            this.user = null;
            this.token = null;
            this.menu = [];
            this.permisos = {};

            Cookies.remove('auth_token');
            if (process.client) {
                localStorage.removeItem('auth_data');
            }

            return navigateTo('/');
        }
    }
});