// C:\sirena\sirena-frontend\app\stores\auth.ts
import { defineStore } from 'pinia';
import Cookies from 'js-cookie';
import { safeJSONParse } from '../utils/safe-json';
import type {
    MenuItem,
    MenuItemBackend,
    PermisosMap,
    PermisosTabla,
} from '../types/menu';

interface UserData {
    usuario_id: number;
    login: string;
    avatar: string;
    rol_id: number;
    rol_codigo: string;
    rol_nombre: string;
    es_admin: boolean;
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

/**
 * Normaliza el menú del backend (MenuItemBackend) a la forma canónica
 * que espera el PanelMenu de PrimeVue (MenuItem).
 *
 * Reglas críticas:
 *  - `null` se convierte en `undefined` para `to` y `url`
 *    (PrimeVue no acepta `null`).
 *  - Se generan `key` automáticas basadas en `label` para el PanelMenu.
 *  - Acepta alias del backend: titulo → label, icono → icon, url → to.
 */
const normalizeMenu = (items: MenuItemBackend[] = []): MenuItem[] => {
    return items.map((item) => {
        const label = item.label ?? item.titulo ?? '';
        const to = item.to ?? item.url ?? undefined;

        const normalized: MenuItem = {
            label,
            icon: item.icon ?? item.icono ?? undefined,
            // ⬇️ Coerción explícita: null/'' → undefined
            to: to ? to : undefined,
            key: label,
        };

        if (item.items && item.items.length) {
            normalized.items = normalizeMenu(item.items);
        }

        return normalized;
    });
};

export const useAuthStore = defineStore('auth', {
    state: () => {
        const isClient = process.client;
        const authData = isClient ? (safeJSONParse(sessionStorage.getItem('auth_data'), null) as AuthData | null) : null;

        return {
            user: authData?.user || null,
            menu: normalizeMenu((authData?.menu as MenuItemBackend[]) || []),
            token: authData?.token || (isClient ? Cookies.get('auth_token') : null) || null,
            permisos: authData?.permisos || ({} as PermisosMap),
        };
    },

    getters: {
        isLoggedIn: (state) => !!state.token,
        isAdmin: (state) => state.user?.es_admin === true,

        can: (state) => (nombreTabla: string, accion: keyof PermisosTabla): boolean => {
            if (state.user?.es_admin) return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return permisosTabla[accion] === true;
        },

        canAny: (state) => (nombreTabla: string, acciones: (keyof PermisosTabla)[]): boolean => {
            if (state.user?.es_admin) return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return acciones.some(accion => permisosTabla[accion] === true);
        },

        canAll: (state) => (nombreTabla: string, acciones: (keyof PermisosTabla)[]): boolean => {
            if (state.user?.es_admin) return true;
            const permisosTabla = state.permisos[nombreTabla];
            if (!permisosTabla) return false;
            return acciones.every(accion => permisosTabla[accion] === true);
        },
    },

    actions: {
        startSession(
            userData: UserData,
            token: string,
            menuData: MenuItemBackend[],
            permisosData: PermisosMap,
        ) {
            this.user = {
                ...userData,
                usuario_id: Number(userData.usuario_id),
                trabajador_id: Number(userData.trabajador_id),
                rol_id: Number(userData.rol_id),
                es_admin: userData.es_admin === true,
                empresa_id: userData.empresa_id ? Number(userData.empresa_id) : null,
                sucursal_id: userData.sucursal_id ? Number(userData.sucursal_id) : null,
                cargo_id: userData.cargo_id ? Number(userData.cargo_id) : null,
            };

            this.token = token;
            this.menu = normalizeMenu(menuData);
            this.permisos = { ...permisosData };

            Cookies.set('auth_token', token, {
                path: '/',
                sameSite: 'Lax',
                secure: process.env.NODE_ENV === 'production',
            });

            if (process.client) {
                sessionStorage.setItem(
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

        async logout() {
            Cookies.remove('auth_token');
            if (process.client) {
                sessionStorage.removeItem('auth_data');
            }

            await navigateTo('/');

            this.user = null;
            this.token = null;
            this.menu = [];
            this.permisos = {};
        },
    },
});
