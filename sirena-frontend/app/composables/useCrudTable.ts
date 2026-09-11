// C:\sirena\sirena-frontend\app\composables\useCrudTable.ts
import { useCrudService, type FindParams } from '~/services/crud.service';
import { ESTADO_ACTIVO } from '~/constants/estados.constant';

export interface UseCrudTableOptions<T> {
    /** Nombre de la tabla en el backend (ej. 'bancos', 'sucursales') */
    tabla: string;

    /** Nombre de la tabla en el mapa de permisos → snake_case. Por defecto = tabla */
    tablaPermisos?: string;

    /** Devuelve un objeto limpio para "nuevo registro" */
    getCleanForm: () => T;

    /** Extrae la PK del registro (por defecto busca `id`, `<tabla_singular>_id`, o `<tabla>_id`) */
    getPrimaryKey?: (item: T) => number | string;

    /** Construye el payload que se envía al backend (POST/PATCH) */
    buildPayload: (form: T) => Partial<T>;

    /** Validación personalizada. Retorna `true` si todo ok, `false` si hay error */
    validate?: (form: T, rules: any, notify: any) => boolean;

    /** Campo por defecto para ordenar (ej. 'banco_id', 'empresa_id') */
    sortFieldDefault?: string;

    /** Filas por página (default 20) */
    rowsDefault?: number;

    /** Si `false`, NO carga automáticamente al montar. Útil cuando dependes de otra carga */
    autoLoad?: boolean;

    /** Filtros iniciales del módulo (ej. { exactMatch: 0, estado_id: null }) */
    defaultFilters?: Record<string, any>;

    /** Traduce los filtros de la UI a los parámetros del backend */
    getExtraFilters?: (filters: Record<string, any>) => Record<string, any>;

    /** Campos que se deben bloquear si el registro tiene dependencias activas */
    camposProtegidosPorDependencia?: string[];
}

export const useCrudTable = <T extends { [k: string]: any }>(opts: UseCrudTableOptions<T>) => {
    const { notify } = useNotify();
    const { $rules } = useNuxtApp() as any;

    const crud = useCrudService<T>(opts.tabla);
    const permisos = crud.permisos(opts.tablaPermisos);

    // ---------- Primary key resolver ----------
    const resolvePK = (item: T): number | string => {
        if (opts.getPrimaryKey) return opts.getPrimaryKey(item);
        // Busca patrones comunes: 'id', 'banco_id', 'empresas_id', etc.
        const singular = opts.tabla.replace(/s$/, '');
        const candidates = ['id', `${singular}_id`, `${opts.tabla}_id`];
        for (const key of candidates) {
            if (item[key] !== undefined && item[key] !== null) return item[key];
        }
        throw new Error(`No se pudo resolver la PK de ${opts.tabla}. Define getPrimaryKey().`);
    };

    // ---------- Estado del listado ----------
    const items = ref<T[]>([]) as Ref<T[]>;
    const loading = ref(false);
    const totalRecords = ref(0);
    const filters = ref<Record<string, any>>({
        global: '',
        ...(opts.defaultFilters ?? {}),
    });
    const lazyParams = ref({
        first: 0,
        rows: opts.rowsDefault ?? 20,
        page: 0,
        sortField: opts.sortFieldDefault ?? 'id',
        sortOrder: -1,
    });

    // ---------- Estado del formulario ----------
    const dialog = ref(false);
    const deleteDialog = ref(false);
    const formObj = ref<T>(opts.getCleanForm()) as Ref<T>;
    const submitted = ref(false);
    const touched = ref<Record<string, boolean>>({});

    const isUpdate = computed(() => {
        try {
            const pk = resolvePK(formObj.value);
            return pk !== null && pk !== undefined && pk !== '' && pk !== 0;
        } catch {
            return false;
        }
    });

    const formTitle = computed(() => (isUpdate.value ? 'Editar registro' : 'Nuevo registro'));

    // ---------- Campos protegidos por dependencias ----------
    const camposProtegidos = computed<string[]>(() => {
        // Si el registro NO tiene dependencias, no se protege ningún campo.
        if (!formObj.value?.tiene_dependencias) return [];
        // Si tiene dependencias, se protegen los campos configurados o los que vengan del backend.
        return opts.camposProtegidosPorDependencia ?? formObj.value?.campos_protegidos ?? [];
    });

    const estaProtegido = (campo: string): boolean => {
        return camposProtegidos.value.includes(campo);
    };

    // ---------- Cargar listado ----------
    const load = async (search = '', silent = false) => {
        if (!silent) { loading.value = true; }
        try {
            const params: FindParams = {
                limit: lazyParams.value.rows,
                offset: lazyParams.value.first,
                sortField: lazyParams.value.sortField,
                sortOrder: lazyParams.value.sortOrder,
            };
            if (search?.trim()) params.q = search.trim();
            if (opts.getExtraFilters) {
                Object.assign(params, opts.getExtraFilters(filters.value));
            }
            const response = await crud.listar(params);
            items.value = response.data || [];
            totalRecords.value = response.total || 0;
        } catch (err) {
            notify('error', 'Error al cargar', 'No se pudo recuperar la lista desde el servidor.');
            console.error(`Error al cargar ${opts.tabla}:`, err);
        } finally {
            if (!silent) loading.value = false;
        }
    };

    // ---------- Paginación / orden / búsqueda ----------
    const onPage = (event: any) => {
        lazyParams.value = event;
        load(filters.value.global, true);
    };

    const onSort = (event: any) => {
        lazyParams.value = event;
        load(filters.value.global, true);
    };

    const onSearch = () => {
        lazyParams.value.first = 0;
        load(filters.value.global, true);
    };

    // ---------- Formulario: abrir/cerrar ----------
    const resetForm = () => {
        formObj.value = opts.getCleanForm();
        submitted.value = false;
        touched.value = {};
    };

    const openNew = () => {
        resetForm();
        dialog.value = true;
    };

    const edit = async (data: T) => {
        // 1. Relleno inmediato con lo que viene del listado (evita que se vea vacío).
        formObj.value = { ...data };
        submitted.value = false;
        touched.value = {};
        dialog.value = true;

        // 2. Traigo el detalle completo (con tiene_dependencias y campos_protegidos).
        try {
            const pk = resolvePK(data);
            const detalle = await crud.obtener(pk);
            console.log('[edit] detalle desde /bancos/:id:', detalle);
            formObj.value = { ...detalle };
        } catch (err) {
            console.warn(`No se pudo cargar el detalle de ${opts.tabla}:`, err);
        }
    };

    const hideDialog = () => {
        dialog.value = false;
        resetForm();
    };

    // ---------- Guardar ----------
    const save = async () => {
        submitted.value = true;

        // Validación personalizada (si existe)
        if (opts.validate && !opts.validate(formObj.value, $rules, notify)) return;

        try {
            loading.value = true;
            const payload = opts.buildPayload(formObj.value);

            if (isUpdate.value) {
                const pk = resolvePK(formObj.value);
                await crud.actualizar(pk, payload);
                notify('success', 'Actualizado', 'El registro se actualizó correctamente.');
            } else {
                await crud.crear(payload);
                notify('success', 'Creado', 'El registro se creó correctamente.');
            }

            await load();
            hideDialog();
        } catch (err: any) {
            const msg = err?.data?.message || 'No se pudo guardar el registro';
            notify('error', isUpdate.value ? 'Error al actualizar' : 'Error al crear',
                Array.isArray(msg) ? msg.join(', ') : msg);
            console.error(`Error al guardar ${opts.tabla}:`, err);
        } finally {
            loading.value = false;
        }
    };

    // ---------- Archivar / Desarchivar ----------
    const toggleEstado = async (data: T) => {
        const accion = data.estado_id === ESTADO_ACTIVO ? 'archivar' : 'desarchivar';
        try {
            const pk = resolvePK(data);
            if (accion === 'archivar') await crud.archivar(pk);
            else await crud.desarchivar(pk);

            notify('success', 'Estado actualizado',
                `El registro se ${accion === 'archivar' ? 'archivó' : 'restauró'} correctamente.`);
            load(filters.value.global, true);
        } catch (err: any) {
            const msg = err?.data?.message || `No se pudo ${accion} el registro`;
            notify('error', 'Error al actualizar estado', Array.isArray(msg) ? msg.join(', ') : msg);
            console.error(`Error al ${accion}:`, err);
        }
    };

    // ---------- Eliminar ----------
    const confirmDelete = (data: T) => {
        formObj.value = { ...data };
        deleteDialog.value = true;
    };

    const deleteItem = async () => {
        try {
            deleteDialog.value = false;
            loading.value = true;
            const pk = resolvePK(formObj.value);
            await crud.eliminar(pk);
            notify('success', 'Eliminado', 'El registro se eliminó correctamente.');
            await load();
        } catch (err: any) {
            const errorData = err?.data;
            const msg = errorData?.message || 'No se pudo eliminar el registro';
            let extra = '';
            if (errorData?.detalles) {
                const motivos = [];
                if (errorData.detalles.activas) motivos.push(`${errorData.detalles.activas} activo(s)`);
                if (errorData.detalles.historicas) motivos.push(`${errorData.detalles.historicas} histórico(s)`);
                if (motivos.length) extra = `. Dependencias: ${motivos.join(' y ')}.`;
            }
            notify('error', 'Error al eliminar',
                `${Array.isArray(msg) ? msg.join(', ') : msg}${extra}`);
            console.error(`Error al eliminar ${opts.tabla}:`, err);
        } finally {
            loading.value = false;
        }
    };

    // ---------- Init ----------
    if (opts.autoLoad !== false) {
        onMounted(() => {
            if (permisos.leer) load();
            else notify('warn', 'Acceso denegado', 'No tiene permisos para ver este módulo.');
        });
    }

    return {
        // Estado
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        // Derivados
        isUpdate, formTitle, permisos, crud,
        // Protegidos
        camposProtegidos, estaProtegido,
        // Acciones
        load, onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
        // Utilidad
        resolvePK,
    };
};