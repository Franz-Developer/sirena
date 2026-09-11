// C:\sirena\sirena-frontend\app\composables\useCrudTable.ts
import { useCrudService, type FindParams } from '~/services/crud.service';
import { ESTADO_ACTIVO } from '~/constants/estados.constant';

// ============================================================
// TIPOS
// ============================================================
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

// ============================================================
// CANDIDATOS DE PK GENERADOS DINÁMICAMENTE
// ============================================================
/**
 * Genera todos los candidatos posibles de nombre de PK para una tabla,
 * cubriendo los patrones reales de la base de datos SIRENA.
 *
 * Patrones cubiertos:
 *  1. `id` genérico
 *  2. `<tabla>_id`                    → 'bancos_id'  (raro, pero por si acaso)
 *  3. `<tabla_sin_s>_id`              → 'banco_id'
 *  4. `<cada_palabra_singular>_id`    → 'tipo_cambio_id' (desde 'tipos_cambios')
 *  5. `<última_palabra_singular>_id`  → 'venta_id' (fallback)
 *  6. Casos especiales documentados en SIRENA
 */
const generarCandidatosPK = (tabla: string): string[] => {
    const candidatos = new Set<string>();

    // 1. Genérico
    candidatos.add('id');

    // 2. Tabla tal cual + _id
    candidatos.add(`${tabla}_id`);

    // 3. Tabla sin la 's' final
    const sinS = tabla.replace(/s$/, '');
    candidatos.add(`${sinS}_id`);

    // 4. Singularizar CADA palabra por separado
    const singularPorPalabra = tabla
        .split('_')
        .map((palabra) => palabra.replace(/s$/, ''))
        .join('_');
    candidatos.add(`${singularPorPalabra}_id`);

    // 5. Última palabra singularizada
    const palabras = tabla.split('_');
    const ultimaPalabra = palabras[palabras.length - 1] ?? '';
    const ultimaSingular = ultimaPalabra.replace(/s$/, '');
    if (ultimaSingular) {
        candidatos.add(`${ultimaSingular}_id`);
    }

    // 6. Casos especiales documentados en SIRENA
    const casosEspeciales: Record<string, string> = {
        // ─── Plurales irregulares ───
        'tipos_cambios': 'tipo_cambio_id',
        'lotes_productos': 'lote_id',
        'puntos_venta': 'punto_venta_id',
        'rangos_edad': 'rango_edad_id',

        // ─── Productos (relaciones polimórficas) ───
        'productos_controlados': 'producto_controlado_id',
        'productos_principios': 'producto_principio_id',
        'productos_rangos_edad': 'producto_rango_edad_id',
        'productos_ubicaciones': 'producto_ubicacion_id',
        'productos_vias': 'producto_via_id',
        'promociones_productos': 'promocion_producto_id',

        // ─── Proveedores ───
        'proveedores_contactos': 'proveedor_contacto_id',
        'proveedores_rating_historico': 'rating_historico_id',

        // ─── Planes de pago ───
        'planes_pagos': 'plan_pago_id',
        'tipos_planes_pago': 'tipo_plan_pago_id',

        // ─── Roles y permisos ───
        'roles_permisos_tablas': 'rol_permiso_tabla_id',
        'roles_permisos_sucesos': 'rol_permiso_suceso_id',
        'roles_menus': 'rol_menu_id',

        // ─── Empresas ───
        'empresas_nits': 'empresa_nit_id',
        'empresas_cuentas': 'empresa_cuenta_id',

        // ─── Almacenes ───
        'almacenes_puntos_venta': 'almacen_punto_venta_id',

        // ─── Inventarios ───
        'inventarios_fisicos': 'inventario_fisico_id',
        'inventarios_fisicos_detalle': 'inventario_fisico_detalle_id',

        // ─── Kardex ───
        'kardex_productos': 'kardex_producto_id',

        // ─── E-commerce ───
        'detalles_pedidos_online': 'detalle_pedido_online_id',
        'detalles_carritos': 'detalle_carrito_id',
        'carritos_compra': 'carrito_id',
        'pedidos_online': 'pedido_online_id',

        // ─── Ubicaciones ───
        'ubicaciones_movimientos': 'ubicacion_movimiento_id',
        'ubicaciones_historial': 'ubicacion_historial_id',

        // ─── Analítica / IA ───
        'analitica_productos': 'analitica_id',
        'patrones_consumo': 'patron_id',
        'metricas_rendimiento': 'metrica_id',
        'logs_ejecucion': 'log_id',
        'variables_exogenas': 'variable_exogena_id',
        'umbrales_configuracion': 'umbral_id',

        // ─── RRHH ───
        'trabajadores_cargos': 'trabajador_cargo_id',
        'planillas_detalle': 'planilla_detalle_id',

        // ─── Compras ───
        'ordenes_compra': 'orden_compra_id',
        'comprobantes_pagos': 'comprobante_pago_id',

        // ─── Caja ───
        'arqueos_detalle': 'arqueo_detalle_id',

        // ─── Alertas / Tareas / Parámetros ───
        'alertas_notificaciones': 'alerta_notificacion_id',
        'tareas_programadas': 'tarea_id',
        'parametros_globales': 'parametro_id',
        'control_facturas': 'control_factura_id',

        // ─── Productos (catálogos) ───
        'registros_sanitarios': 'registro_sanitario_id',
        'principios_activos': 'principio_activo_id',

        // ─── Precios ───
        'listas_precios': 'lista_precio_id',
        'precios_productos': 'precio_producto_id',
        'costos_promedio': 'costo_promedio_id',
        'politicas_precios': 'politica_precio_id',

        // ─── Conversiones ───
        'conversiones_unidad': 'conversion_id',
    };

    const pkEspecial = casosEspeciales[tabla];
    if (pkEspecial) {
        candidatos.add(pkEspecial);
    }

    return Array.from(candidatos);
};

// ============================================================
// COMPOSABLE PRINCIPAL
// ============================================================
export const useCrudTable = <T extends { [k: string]: any }>(opts: UseCrudTableOptions<T>) => {
    const { notify } = useNotify();
    const { $rules } = useNuxtApp() as any;

    const crud = useCrudService<T>(opts.tabla);
    const permisos = crud.permisos(opts.tablaPermisos);

    // ---------- Primary key resolver ----------
    /**
     * Resuelve la PK de un item de forma robusta.
     *
     * Orden de búsqueda:
     *  1. Si el usuario definió `getPrimaryKey`, se usa.
     *  2. Se generan candidatos dinámicos + casos especiales documentados.
     *  3. Se retorna el primer candidato con valor no nulo/vacío.
     *  4. Si nada coincide, se lanza error con lista de candidatos.
     */
    const resolvePK = (item: T): number | string => {
        // 1. Override del usuario
        if (opts.getPrimaryKey) return opts.getPrimaryKey(item);

        // 2. Candidatos generados
        const candidatos = generarCandidatosPK(opts.tabla);

        // 3. Buscar el primer candidato que exista en el item
        for (const key of candidatos) {
            const valor = item[key];
            if (valor !== undefined && valor !== null && valor !== '') {
                return valor;
            }
        }

        // 4. Error explícito con candidatos probados
        throw new Error(
            `[useCrudTable] No se pudo resolver la PK de "${opts.tabla}". ` +
            `Candidatos probados: ${candidatos.join(', ')}. ` +
            `Define getPrimaryKey() en las opciones del composable.`
        );
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
        if (!formObj.value?.tiene_dependencias) return [];
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
        formObj.value = { ...data };
        submitted.value = false;
        touched.value = {};
        dialog.value = true;

        try {
            const pk = resolvePK(data);
            const detalle = await crud.obtener(pk);
            console.log(`[edit] detalle desde /${opts.tabla}/:id:`, detalle);
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
