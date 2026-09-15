<!-- C:\sirena\sirena-frontend\app\pages\configuracion\puntos-venta\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <CrudPageHeader
            icon="pi pi-shopping-cart"
            title="Puntos de Venta"
            subtitle="Gestión de puntos de venta por sucursal"
            :show-action="permisos.crear && !!filters.sucursal_id"
            action-label="NUEVO PUNTO DE VENTA"
            action-icon="pi pi-plus"
            @action="openNewConSucursal"
        />

        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden" style="height: 75vh;">
            <BaseTable
                :value="items"
                :loading="loading"
                :columns="columns"
                :totalRecords="totalRecords"
                :rows="lazyParams.rows"
                :first="lazyParams.first"
                :sortField="lazyParams.sortField"
                :sortOrder="lazyParams.sortOrder"
                @page="onPage"
                @sort="onSort"
            >
                <template #header>
                    <div class="px-4 py-3 bg-white border-b border-slate-200 flex flex-col gap-3">
                        <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-end">
                            <div class="hidden lg:block lg:col-span-3"></div>
                            <div class="lg:col-span-6 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Buscar
                                </label>
                                <BaseSearch
                                    ref="searchRef"
                                    autofocus
                                    v-model="filters.global"
                                    placeholder="Nombre, código, sucursal..."
                                    @search="onSearch"
                                    class="w-full"
                                />
                            </div>

                            <div class="lg:col-span-3 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Coincidencia
                                </label>
                                <BaseSelect
                                    v-model="filters.exactMatch"
                                    :options="opcionesExactMatch"
                                    option-label="label"
                                    option-value="value"
                                    size="sm"
                                    @update:model-value="onSearch"
                                    class="w-full"
                                />
                            </div>
                        </div>

                        <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-end">
                            <!-- Empresa (obligatoria, nunca vacía) -->
                            <div class="lg:col-span-4 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Empresa <span class="text-red-500">*</span>
                                </label>
                                <BaseSelect
                                    v-model="filters.empresa_id"
                                    :options="empresaOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Seleccionar empresa..."
                                    size="sm"
                                    filter
                                    :loading="loadingEmpresas"
                                    :disabled="empresaOptions.length <= 1"
                                    @update:model-value="onEmpresaChange"
                                    class="w-full"
                                />
                            </div>

                            <!-- Sucursal (dependiente de empresa, obligatoria) -->
                            <div class="lg:col-span-5 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Sucursal <span class="text-red-500">*</span>
                                </label>
                                <BaseSelect
                                    v-model="filters.sucursal_id"
                                    :options="sucursalOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Seleccionar sucursal..."
                                    size="sm"
                                    filter
                                    show-clear
                                    :loading="loadingSucursales"
                                    :disabled="!filters.empresa_id"
                                    @update:model-value="onSucursalChange"
                                    class="w-full"
                                />
                            </div>

                            <!-- Tipo -->
                            <div class="lg:col-span-3 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Tipo
                                </label>
                                <BaseSelect
                                    v-model="filters.tipo_punto_venta_id"
                                    :options="tipoOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todos"
                                    size="sm"
                                    show-clear
                                    @update:model-value="onSearch"
                                    class="w-full"
                                />
                            </div>
                        </div>
                    </div>
                </template>

                <template #body-codigo="{ data }">
                    <span class="font-mono font-bold text-blue-600">{{ data.codigo }}</span>
                </template>

                <template #body-nombre="{ data }">
                    <span class="font-bold text-slate-700">{{ data.nombre }}</span>
                </template>

                <template #body-sucursal="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight">
                        <span class="font-bold text-slate-700">{{ data.sucursal_nombre || '—' }}</span>
                        <span v-if="data.sucursal_codigo" class="text-slate-400 font-mono">
                            {{ data.sucursal_codigo }}
                        </span>
                    </div>
                </template>

                <template #body-tipo="{ data }">
                    <Tag
                        :value="data.tipo_punto_venta?.abreviatura || '—'"
                        :severity="Number(data.tipo_punto_venta_id) === TipoPuntoVenta.CAJA ? 'success' : 'secondary'"
                        class="text-[10px] font-bold uppercase px-2"
                    />
                </template>

                <template #body-estado="{ data }">
                    <CrudEstadoBadge
                        :estado="data.estado_registro"
                        :estado-id="Number(data.estado_id)"
                    />
                </template>

                <template #body-acciones="{ data }">
                    <CrudRowActions
                        :estado-id="Number(data.estado_id)"
                        :puede="permisos"
                        @edit="handleEdit(data)"
                        @toggle="toggleEstado(data)"
                        @delete="confirmDelete(data)"
                    />
                </template>
            </BaseTable>
        </div>

        <!-- Dialog -->
        <Dialog
            v-model:visible="dialog"
            :modal="true"
            :closable="!loading"
            class="custom-modal w-[95vw] sm:w-[90vw] md:w-[800px]"
            :style="{ maxHeight: '95vh' }"
            @show="focusFirstField"
        >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow">
                        <i class="pi pi-shopping-cart text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos del punto de venta</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                        <span>Información del Punto de Venta</span>
                        <span class="text-slate-600 normal-case font-bold text-[10px]">
                            Campos obligatorios <span class="text-red-500">*</span>
                        </span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                        <!-- Empresa (informativa, depende de la del filtro) -->
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Empresa
                            </label>
                            <BaseSelect
                                v-model="formObj.empresa_id"
                                :options="empresaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar empresa..."
                                size="sm"
                                filter
                                :loading="loadingEmpresas"
                                :disabled="true"
                                class="opacity-70"
                            />
                            <small class="text-slate-400 text-[10px]">
                                <i class="pi pi-info-circle mr-1"></i>Se toma de la empresa del filtro
                            </small>
                        </div>

                        <!-- Sucursal -->
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Sucursal <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                ref="sucursalSelectRef"
                                v-model="formObj.sucursal_id"
                                :options="sucursalOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar sucursal..."
                                size="sm"
                                filter
                                :loading="loadingSucursales"
                                :disabled="(estaProtegido('sucursal_id') && !authStore.isAdmin) || !formObj.empresa_id"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('sucursal_id') && !authStore.isAdmin }"
                                @update:model-value="touched.sucursal_id = true"
                            />
                            <small v-if="estaProtegido('sucursal_id') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('sucursal_id') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.sucursal_id) && $rules.obligatoria()(formObj.sucursal_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Código -->
                        <div class="md:col-span-4">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Código <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model.number="formObj.codigo"
                                type="number"
                                :min="0"
                                size="sm"
                                placeholder="Ej: 1"
                                :disabled="estaProtegido('codigo') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('codigo') && !authStore.isAdmin }"
                                @blur="touched.codigo = true"
                            />
                            <small v-if="estaProtegido('codigo') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('codigo') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.codigo) && $rules.soloEnteros()(formObj.codigo) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.soloEnteros()(formObj.codigo) }}
                            </small>
                            <small
                                v-else-if="(submitted || touched.codigo) && Number(formObj.codigo) < 0"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Debe ser mayor o igual a 0
                            </small>
                        </div>

                        <!-- Tipo -->
                        <div class="md:col-span-8">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Tipo de Punto de Venta
                            </label>
                            <BaseSelect
                                v-model="formObj.tipo_punto_venta_id"
                                :options="tipoOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar tipo..."
                                size="sm"
                                :disabled="estaProtegido('tipo_punto_venta_id') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('tipo_punto_venta_id') && !authStore.isAdmin }"
                            />
                        </div>

                        <!-- Nombre -->
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Nombre <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                ref="nombreRef"
                                v-model="formObj.nombre"
                                :maxlength="500"
                                size="sm"
                                placeholder="Ej: CAJA PRINCIPAL"
                                :disabled="estaProtegido('nombre') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('nombre') && !authStore.isAdmin }"
                                @blur="touched.nombre = true"
                            />
                            <small v-if="estaProtegido('nombre') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('nombre') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.nombre) && $rules.longitudMinima(4)(formObj.nombre) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.longitudMinima(4)(formObj.nombre) }}
                            </small>
                        </div>
                    </div>
                </div>
            </div>

            <template #footer>
                <div class="flex justify-end gap-3 pb-2 pt-4">
                    <BaseButton
                        label="Cancelar"
                        icon="pi pi-times"
                        :loading="loading"
                        variant="danger"
                        @click="hideDialog"
                    />
                    <BaseButton
                        :label="isUpdate ? 'Actualizar' : 'Guardar Registro'"
                        icon="pi pi-save"
                        :loading="loading"
                        variant="primary"
                        @click="save"
                    />
                </div>
            </template>
        </Dialog>

        <CrudDeleteDialog
            v-model:visible="deleteDialog"
            title="Eliminar Punto de Venta"
            :item-name="deleteItemName"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    import { ref, computed, shallowRef, watch, nextTick } from 'vue';
    import { useAuthStore } from '@/stores/auth';
    import { ESTADO_ACTIVO, TipoPuntoVenta, TIPO_PUNTO_VENTA_METADATA } from '~/constants/estados.constant';

    useHead({ title: 'Puntos de Venta | SIRENA' });

    interface SelectOption {
        label: string;
        value: number;
    }

    const { $rules } = useNuxtApp() as any;
    const { $api } = useNuxtApp() as any;
    const authStore = useAuthStore();

    const empresaOptions = shallowRef<SelectOption[]>([]);
    const loadingEmpresas = ref(false);
    const sucursalOptions = shallowRef<SelectOption[]>([]);
    const loadingSucursales = ref(false);

    const opcionesExactMatch = [
        { label: 'Parecido', value: 0 },
        { label: 'Exacto',   value: 1 },
    ];

    // Opciones del enum TipoPuntoVenta (3950 NINGUNO, 3951 CAJA)
    const tipoOptions: SelectOption[] = Object.values(TipoPuntoVenta)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => ({
            value: id,
            label: TIPO_PUNTO_VENTA_METADATA[id]?.abreviatura ?? `Tipo ${id}`,
        }));

    // Empresa inicial: SIEMPRE la del usuario (nunca null)
    const empresaIdInicial = Number(authStore.user?.empresa_id) || null;
    const sucursalIdInicial = Number(authStore.user?.sucursal_id) || null;

    // ═══════════════════════════════════════════════════════════
    // CARGA DE EMPRESAS
    // ═══════════════════════════════════════════════════════════
    const cargarEmpresas = async () => {
        loadingEmpresas.value = true;
        try {
            const res = await $api('/empresas', {
                method: 'GET',
                params: { limit: 100, sortField: 'empresa', sortOrder: 1, estado_id: ESTADO_ACTIVO },
            });

            const lista = Array.isArray(res) ? res : (res?.data ?? []);

            empresaOptions.value = lista.map((e: any): SelectOption => ({
                label: `${e.codigo} — ${e.empresa}`,
                value: Number(e.empresa_id),
            }));

            // Si la empresa del usuario no está en la lista, la agregamos
            if (empresaIdInicial && !empresaOptions.value.some(o => o.value === empresaIdInicial)) {
                empresaOptions.value = [
                    {
                        label: authStore.user?.empresa_nombre
                            ? `${authStore.user.empresa_codigo ?? ''} — ${authStore.user.empresa_nombre}`.trim()
                            : `Empresa ${empresaIdInicial}`,
                        value: empresaIdInicial,
                    },
                    ...empresaOptions.value,
                ];
            }
        } catch (err) {
            console.error('Error al cargar empresas:', err);
            empresaOptions.value = [];
        } finally {
            loadingEmpresas.value = false;
        }
    };

    // ═══════════════════════════════════════════════════════════
    // CARGA DE SUCURSALES (depende de empresa_id)
    // ═══════════════════════════════════════════════════════════
    const cargarSucursales = async (empresaId: number | null | undefined) => {
        if (!empresaId) {
            sucursalOptions.value = [];
            return;
        }

        loadingSucursales.value = true;
        try {
            const res = await $api('/sucursales', {
                method: 'GET',
                params: {
                    limit: 100,
                    sortField: 'sucursal',
                    sortOrder: 1,
                    estado_id: ESTADO_ACTIVO,
                    empresa_id: Number(empresaId),
                },
            });

            const lista = Array.isArray(res) ? res : (res?.data ?? []);

            sucursalOptions.value = lista.map((s: any): SelectOption => ({
                label: `${s.codigo ?? ''} — ${s.sucursal}`.trim().replace(/^—\s*/, ''),
                value: Number(s.sucursal_id),
            }));
        } catch (err) {
            console.error('Error al cargar sucursales:', err);
            sucursalOptions.value = [];
        } finally {
            loadingSucursales.value = false;
        }
    };

    // ═══════════════════════════════════════════════════════════
    // CRUD TABLE
    // ═══════════════════════════════════════════════════════════
    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos, estaProtegido,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
    } = useCrudTable<any>({
        tabla: 'puntos-venta',
        // ⚠️ IMPORTANTE: ajusta al nombre exacto del mapa de permisos del backend
        tablaPermisos: 'puntos_venta',
        sortFieldDefault: 'punto_venta_id',
        rowsDefault: 10,
        autoLoad: false,

        camposProtegidosPorDependencia: ['sucursal_id', 'codigo', 'nombre'],

        defaultFilters: {
            global: '',
            exactMatch: 0,
            empresa_id: empresaIdInicial,
            sucursal_id: sucursalIdInicial,
            tipo_punto_venta_id: null,
        },

        getExtraFilters: (f) => {
            const extra: Record<string, any> = {
                exactMatch: f.exactMatch ?? 0,
            };
            // sucursal_id es OBLIGATORIO en el backend
            if (f.sucursal_id) extra.sucursal_id = Number(f.sucursal_id);
            if (f.tipo_punto_venta_id) extra.tipo_punto_venta_id = Number(f.tipo_punto_venta_id);
            return extra;
        },

        getPrimaryKey: (item) => item.punto_venta_id,

        getCleanForm: () => ({
            punto_venta_id: null,
            empresa_id: empresaIdInicial ? Number(empresaIdInicial) : null,
            sucursal_id: sucursalIdInicial ? Number(sucursalIdInicial) : null,
            codigo: 0,
            nombre: '',
            tipo_punto_venta_id: TipoPuntoVenta.NINGUNO,
        }),

        buildPayload: (form) => {
            const payload: Record<string, any> = {
                sucursal_id: Number(form.sucursal_id),
                codigo: Number(form.codigo),
                nombre: form.nombre?.trim().toUpperCase(),
            };
            if (form.tipo_punto_venta_id != null) {
                payload.tipo_punto_venta_id = Number(form.tipo_punto_venta_id);
            }
            return payload;
        },

        validate: (form, rules, notify) => {
            if (rules.obligatoria()(form.sucursal_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar una sucursal.');
                return false;
            }
            if (rules.soloEnteros()(form.codigo) !== true) {
                notify('warn', 'Código inválido', 'El código debe ser un número entero.');
                return false;
            }
            if (Number(form.codigo) < 0) {
                notify('warn', 'Código inválido', 'El código debe ser mayor o igual a 0.');
                return false;
            }
            if (rules.longitudMinima(4)(form.nombre) !== true) {
                notify('warn', 'Nombre inválido', rules.longitudMinima(4)(form.nombre));
                return false;
            }
            if (rules.longitudMaxima(500)(form.nombre) !== true) {
                notify('warn', 'Nombre inválido', rules.longitudMaxima(500)(form.nombre));
                return false;
            }
            return true;
        },
    });

    const deleteItemName = computed(() => {
        const codigo = formObj.value.codigo ?? '';
        const nombre = formObj.value.nombre ?? '';
        return `${codigo} — ${nombre}`;
    });

    // ═══════════════════════════════════════════════════════════
    // HANDLERS DE FILTROS
    // ═══════════════════════════════════════════════════════════
    const onEmpresaChange = async () => {
        // Al cambiar empresa, recargar sucursales y resetear sucursal seleccionada
        filters.value.sucursal_id = null;
        await cargarSucursales(filters.value.empresa_id);
        lazyParams.value.first = 0;
        // No disparamos onSearch aún porque no hay sucursal seleccionada
    };

    const onSucursalChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const openNewConSucursal = () => {
        openNew();
        const sucursalId = filters.value.sucursal_id ? Number(filters.value.sucursal_id) : null;
        const empresaId = filters.value.empresa_id ? Number(filters.value.empresa_id) : null;
        if (sucursalId) formObj.value.sucursal_id = sucursalId;
        if (empresaId) formObj.value.empresa_id = empresaId;
    };

    const handleEdit = async (item: any) => {
        // Asegurar que la empresa del filtro se propague al form
        formObj.value.empresa_id = filters.value.empresa_id ? Number(filters.value.empresa_id) : null;

        if (sucursalOptions.value.length === 0 && filters.value.empresa_id) {
            await cargarSucursales(filters.value.empresa_id);
        }

        const sucursalId = item.sucursal_id != null ? Number(item.sucursal_id) : null;
        const existe = sucursalOptions.value.some(o => o.value === sucursalId);

        if (sucursalId && !existe) {
            sucursalOptions.value = [
                ...sucursalOptions.value,
                {
                    label: item.sucursal_nombre
                        ? `${item.sucursal_codigo ?? ''} — ${item.sucursal_nombre}`.trim()
                        : `Sucursal ${sucursalId}`,
                    value: sucursalId,
                },
            ];
        }

        await edit(item);

        // Normalizaciones post-edit
        formObj.value.empresa_id = filters.value.empresa_id ? Number(filters.value.empresa_id) : null;
        formObj.value.sucursal_id = sucursalId;
        formObj.value.codigo = item.codigo != null ? Number(item.codigo) : 0;
        formObj.value.tipo_punto_venta_id = item.tipo_punto_venta_id != null
            ? Number(item.tipo_punto_venta_id)
            : TipoPuntoVenta.NINGUNO;
    };

    const columns = [
        { field: 'codigo', header: 'CÓDIGO', sortable: true, template: 'body-codigo', bodyClass: '!text-center', class: 'w-24' },
        { field: 'nombre', header: 'NOMBRE', sortable: true, template: 'body-nombre' },
        { field: 'sucursal_nombre', header: 'SUCURSAL', sortable: true, template: 'body-sucursal', class: 'w-48' },
        { field: 'tipo_punto_venta_id', header: 'TIPO', sortable: true, template: 'body-tipo', bodyClass: '!text-center', class: 'w-28' },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    const searchRef = ref<any>(null);
    const nombreRef = ref<any>(null);
    const sucursalSelectRef = ref<any>(null);

    // Foco: en "nuevo" → select sucursal; en "editar" → nombre
    const focusFirstField = async () => {
        await nextTick();
        setTimeout(() => {
            if (!isUpdate.value) {
                const el = sucursalSelectRef.value?.getSelectEl?.() as HTMLElement | null;
                const trigger = el?.querySelector('.p-select-label') as HTMLElement | null;
                trigger?.focus();
                trigger?.click();
            } else {
                const input = nombreRef.value?.$el?.querySelector('input') as HTMLInputElement | null;
                input?.focus();
                input?.select();
            }
        }, 350);
    };

    // Normalizar tipos numéricos al abrir el dialog
    watch(dialog, async (isOpen) => {
        if (!isOpen) return;
        await nextTick();
        setTimeout(() => {
            if (formObj.value.empresa_id != null) {
                formObj.value.empresa_id = Number(formObj.value.empresa_id);
            }
            if (formObj.value.sucursal_id != null) {
                formObj.value.sucursal_id = Number(formObj.value.sucursal_id);
            }
            if (formObj.value.codigo != null) {
                formObj.value.codigo = Number(formObj.value.codigo);
            }
            if (formObj.value.tipo_punto_venta_id != null) {
                formObj.value.tipo_punto_venta_id = Number(formObj.value.tipo_punto_venta_id);
            }
        }, 150);
    });

    // Watch: si cambia empresa_id en el form, recargar sucursales
    watch(
        () => formObj.value.empresa_id,
        async (newId, oldId) => {
            if (!dialog.value) return;
            if (!newId || newId === oldId) return;
            if (!sucursalOptions.value.length || sucursalOptions.value[0]?.value !== newId) {
                // Solo recargar si la empresa del form es distinta a la del filtro
                if (Number(newId) !== Number(filters.value.empresa_id)) {
                    await cargarSucursales(Number(newId));
                }
            }
        }
    );

    // ═══════════════════════════════════════════════════════════
    // INIT
    // ═══════════════════════════════════════════════════════════
    onMounted(async () => {
        await cargarEmpresas();

        // Asegurar que empresa_id siempre tenga valor
        if (!filters.value.empresa_id && empresaOptions.value.length > 0) {
            filters.value.empresa_id = empresaOptions.value[0]?.value ?? null;
        }

        if (filters.value.empresa_id) {
            await cargarSucursales(filters.value.empresa_id);
        }

        // Si hay sucursal inicial, cargar la tabla
        if (filters.value.sucursal_id) {
            onSearch();
        }
    });
</script>
