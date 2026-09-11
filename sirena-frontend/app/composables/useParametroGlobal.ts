// C:\sirena\sirena-frontend\app\composables\useParametroGlobal.ts
interface ParametroGlobalResponse {
    parametro_id: number;
    clave: string;
    valor: string;
    tipo_dato_id: number;
    datos_json: Record<string, any> | null;
    descripcion: string | null;
    editable: number;
    estado_id: number;
    estado_registro: string;
}

const cache = new Map<string, ParametroGlobalResponse | null>();
const inflight = new Map<string, Promise<ParametroGlobalResponse | null>>();

export const useParametroGlobal = () => {
    const { $api } = useNuxtApp() as any;

    /**
     * Carga un parámetro global por su clave (cachea en memoria).
     * Devuelve null si no existe o si la petición falla.
     */
    const getByClave = async (clave: string): Promise<ParametroGlobalResponse | null> => {
        if (cache.has(clave)) return cache.get(clave)!;
        if (inflight.has(clave)) return inflight.get(clave)!;

        const promise = $api('/parametros_globales', {
            method: 'GET',
            params: { clave, estado_id: 1000, limit: 1 },
        })
            .then((res: any) => {
                const item = res?.data?.[0] ?? null;
                cache.set(clave, item);
                return item;
            })
            .catch((err: any) => {
                console.warn(`[useParametroGlobal] Error cargando "${clave}":`, err);
                cache.set(clave, null);
                return null;
            })
            .finally(() => {
                inflight.delete(clave);
            });

        inflight.set(clave, promise);
        return promise;
    };

    /**
     * Devuelve el JSON de un parámetro (o null si no es JSONB / no existe).
     */
    const getJson = async (clave: string): Promise<Record<string, any> | null> => {
        const param = await getByClave(clave);
        return param?.datos_json ?? null;
    };

    const clearCache = (clave?: string) => {
        if (clave) cache.delete(clave);
        else cache.clear();
    };

    return { getByClave, getJson, clearCache };
};
