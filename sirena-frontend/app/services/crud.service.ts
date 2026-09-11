// C:\sirena\sirena-frontend\app\services\crud.service.ts
import type { PermisosTabla } from '~/types/menu';

export interface PaginatedResult<T> {
    data: T[];
    total: number;
}

export interface FindParams {
    q?: string;
    exactMatch?: number;
    estado_id?: number;
    usuario_id?: number;
    limit?: number;
    offset?: number;
    sortField?: string;
    sortOrder?: number;
    [key: string]: any;
}

/**
 * Servicio CRUD genérico para cualquier tabla del backend.
 * Las rutas siguen el patrón: /<tabla>, /<tabla>/:id, /<tabla>/:id/archivar, etc.
 */
export const useCrudService = <T extends { [k: string]: any } = any>(tabla: string) => {
    const { $api } = useNuxtApp() as any;
    const authStore = useAuthStore();

    const listar = (params: FindParams = {}): Promise<PaginatedResult<T>> => $api(`/${tabla}`, { method: 'GET', params });
    const obtener = (id: number | string): Promise<T> => $api(`/${tabla}/${id}`, { method: 'GET' });
    const crear = (payload: Partial<T>): Promise<T> => $api(`/${tabla}`, { method: 'POST', body: payload });
    const actualizar = (id: number | string, payload: Partial<T>): Promise<T> => $api(`/${tabla}/${id}`, { method: 'PATCH', body: payload });
    const eliminar = (id: number | string): Promise<T> => $api(`/${tabla}/${id}`, { method: 'DELETE' });
    const archivar = (id: number | string): Promise<T> => $api(`/${tabla}/${id}/archivar`, { method: 'PATCH' });
    const desarchivar = (id: number | string): Promise<T> => $api(`/${tabla}/${id}/desarchivar`, { method: 'PATCH' });

    /** Permisos del rol actual sobre esta tabla */
    const permisos = (): PermisosTabla => {
        const p = authStore.permisos[tabla];
        return {
            leer:        p?.leer        ?? false,
            crear:       p?.crear       ?? false,
            editar:      p?.editar      ?? false,
            eliminar:    p?.eliminar    ?? false,
            anular:      p?.anular      ?? false,
            archivar:    p?.archivar    ?? false,
            desarchivar: p?.desarchivar ?? false,
        };
    };

    return { listar, obtener, crear, actualizar, eliminar, archivar, desarchivar, permisos, tabla };
};
