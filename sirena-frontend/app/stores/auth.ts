// C:\sirena\sirena-frontend\app\stores\auth.ts
import { defineStore } from 'pinia';
import Cookies from 'js-cookie';
import { safeJSONParse } from '../utils/safe-json';
import type { MenuItem, PermisosMap, PermisosTabla } from '../types/menu';

interface UserData {
    usuario_id: number;
    login: string;
    avatar: string;
    rol_id: number;
    rol_codigo: string;
    rol_nombre: string;
    trabajador_id: number;
    trabajador_nombres: string;
    trabajador_paterno: string;
    trabajador_materno: string | null;
    trabajador_dni: string;
    trabajador_nombre_completo: string;
    empresa_id?: number | null;
    empresa_nombre?: string | null;
    empresa_codigo?: string | null;
    sucursal_id?: number | null;
    sucursal_nombre?: string | null;
    sucursal_codigo?: string | null;
    cargo_id?: number | null;
    cargo_nombre?: string | null;
    cargo_codigo?: string | null;
    [key: string]: any;
}

interface AuthData {
    user: UserData | null;
    token: string | null;
    menu: MenuItem[];
    permisos: PermisosMap;
}

export const useAuthStore = defineStore('auth', {
    state: () => {
        const isClient = process.client;
        const authData = isClient
            ? (safeJSONParse(localStorage.getItem('auth_data'), null) as AuthData | null)
            : null;

        return {
            user: authData?.user || null,
            menu: authData?.menu || ([] as MenuItem[]),
            token: authData?.token || (isClient ? Cookies.get('auth_token') : null) || null,
            permisos: authData?.permisos || ({} as PermisosMap),
        };
    },

    getters: {
        isLoggedIn: (state) => !!state.token,

        can: (state) => (nombreTabla: string, accion: keyof PermisosTabla): boolean => {
            if (state.user?.rol_codigo === 'ADM') return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return permisosTabla[accion] === true;
        },

        canAny: (state) => (nombreTabla: string, acciones: (keyof PermisosTabla)[]): boolean => {
            if (state.user?.rol_codigo === 'ADM') return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return acciones.some(accion => permisosTabla[accion] === true);
        },

        canAll: (state) => (nombreTabla: string, acciones: (keyof PermisosTabla)[]): boolean => {
            if (state.user?.rol_codigo === 'ADM') return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return acciones.every(accion => permisosTabla[accion] === true);
        },
    },

    actions: {
        startSession(
            userData: UserData,
            token: string,
            menuData: MenuItem[],
            permisosData: PermisosMap,
        ) {
            this.user = {
                ...userData,
                usuario_id: Number(userData.usuario_id),
                trabajador_id: Number(userData.trabajador_id),
                rol_id: Number(userData.rol_id),
                empresa_id: userData.empresa_id ? Number(userData.empresa_id) : null,
                sucursal_id: userData.sucursal_id ? Number(userData.sucursal_id) : null,
                cargo_id: userData.cargo_id ? Number(userData.cargo_id) : null,
            };

            this.token = token;
            this.menu = [...menuData];
            this.permisos = { ...permisosData };

            Cookies.set('auth_token', token, {
                expires: 1,
                path: '/',
                sameSite: 'Lax',
                secure: process.env.NODE_ENV === 'production',
            });

            if (process.client) {
                localStorage.setItem(
                    'auth_data',
                    JSON.stringify({
                        user: this.user,
                        token: this.token,
                        menu: this.menu,
                        permisos: this.permisos,
                    }),
                );
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
        },
    },
});
