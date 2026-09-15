<!-- C:\sirena\sirena-frontend\app\pages\configuracion\sucursales\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <CrudPageHeader
            icon="pi pi-map-marker"
            title="Sucursales"
            subtitle="Gestión de sucursales por empresa"
            :show-action="permisos.crear && !!filters.empresa_id"
            action-label="NUEVA SUCURSAL"
            action-icon="pi pi-plus"
            @action="openNewConEmpresa"
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
                    <div class="px-4 py-3 bg-white border-b border-slate-200">
                        <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-end">
                            <div class="lg:col-span-5 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Empresa
                                </label>
                                <BaseSelect
                                    v-model="filters.empresa_id"
                                    :options="empresaOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Seleccionar empresa..."
                                    size="sm"
                                    filter
                                    show-clear
                                    :loading="loadingEmpresas"
                                    @update:model-value="onEmpresaChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="lg:col-span-5 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Buscar
                                </label>
                                <BaseSearch
                                    autofocus
                                    v-model="filters.global"
                                    placeholder="Sucursal, código, teléfono..."
                                    @search="onSearch"
                                    class="w-full"
                                />
                            </div>

                            <div class="lg:col-span-2 w-full">
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
                    </div>
                </template>

                <template #body-codigo="{ data }">
                    <span class="font-mono font-bold text-blue-600">{{ data.codigo }}</span>
                </template>

                <template #body-codigo_sin="{ data }">
                    <span class="font-mono font-semibold text-slate-600 text-[11px]">
                        {{ data.codigo_sin ?? '—' }}
                    </span>
                </template>

                <template #body-sucursal="{ data }">
                    <div class="flex flex-col">
                        <span class="font-bold text-slate-700">{{ data.sucursal }}</span>
                        <span v-if="data.sucursal_largo" class="text-[9px] text-slate-400 italic">
                            {{ data.sucursal_largo }}
                        </span>
                    </div>
                </template>

                <template #body-empresa="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight">
                        <span class="font-bold text-slate-700">{{ data.empresa_nombre || '—' }}</span>
                        <span v-if="data.empresa_codigo" class="text-slate-400 font-mono">
                            {{ data.empresa_codigo }}
                        </span>
                    </div>
                </template>

                <template #body-factor_venta="{ data }">
                    <span class="font-mono font-semibold text-slate-700 text-[11px]">
                        {{ Number(data.factor_venta).toFixed(2) }}
                    </span>
                </template>

                <template #body-factor_facturacion="{ data }">
                    <span class="font-mono font-semibold text-slate-700 text-[11px]">
                        {{ Number(data.factor_facturacion).toFixed(2) }}
                    </span>
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

        <Dialog
            v-model:visible="dialog"
            :modal="true"
            :closable="!loading"
            class="custom-modal w-[95vw] sm:w-[90vw] md:w-[900px]"
            :style="{ maxHeight: '95vh' }"
            @show="focusEmpresa"
        >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow">
                        <i class="pi pi-map-marker text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos de la sucursal</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                        <span>Información de la Sucursal</span>
                        <span class="text-slate-600 normal-case font-bold text-[10px]">
                            Campos obligatorios <span class="text-red-500">*</span>
                        </span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Empresa <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                ref="empresaSelectRef"
                                v-model="formObj.empresa_id"
                                :options="empresaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar empresa..."
                                size="sm"
                                filter
                                :loading="loadingEmpresas"
                                :disabled="estaProtegido('empresa_id') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('empresa_id') && !authStore.isAdmin }"
                                @update:model-value="touched.empresa_id = true"
                            />
                            <small v-if="estaProtegido('empresa_id') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('empresa_id') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.empresa_id) && $rules.obligatoria()(formObj.empresa_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Sucursal <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                ref="sucursalRef"
                                v-model="formObj.sucursal"
                                :maxlength="150"
                                size="sm"
                                placeholder="Ej: SUCURSAL CENTRAL"
                                :disabled="estaProtegido('sucursal') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('sucursal') && !authStore.isAdmin }"
                                @blur="touched.sucursal = true"
                            />
                            <small v-if="estaProtegido('sucursal') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('sucursal') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.sucursal) && $rules.obligatoria()(formObj.sucursal) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>
                        <div class="md:col-span-3">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Código <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.codigo"
                                :maxlength="30"
                                size="sm"
                                placeholder="Ej: SUC-001"
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
                                v-else-if="(submitted || touched.codigo) && $rules.codigoMayusculas(3)(formObj.codigo) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.codigoMayusculas(3)(formObj.codigo) }}
                            </small>
                        </div>
                        <div class="md:col-span-3">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Código SIN <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model.number="formObj.codigo_sin"
                                type="number"
                                :min="0"
                                size="sm"
                                placeholder="Ej: 0"
                                :disabled="estaProtegido('codigo_sin') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('codigo_sin') && !authStore.isAdmin }"
                                @blur="touched.codigo_sin = true"
                            />
                            <small v-if="estaProtegido('codigo_sin') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('codigo_sin') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.codigo_sin) && $rules.soloEnteros()(formObj.codigo_sin) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.soloEnteros()(formObj.codigo_sin) }}
                            </small>
                        </div>
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Sucursal (Nombre Largo) <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.sucursal_largo"
                                :maxlength="300"
                                size="sm"
                                placeholder="Ej: SUCURSAL CENTRAL - AV. PRINCIPAL #123"
                                :disabled="estaProtegido('sucursal_largo') && !authStore.isAdmin"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('sucursal_largo') && !authStore.isAdmin }"
                                @blur="touched.sucursal_largo = true"
                            />
                            <small v-if="estaProtegido('sucursal_largo') && !authStore.isAdmin" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="estaProtegido('sucursal_largo') && authStore.isAdmin" class="text-blue-600 font-semibold text-[10px]">
                                <i class="pi pi-shield mr-1"></i>Modo ADMIN: edición permitida
                            </small>
                            <small
                                v-else-if="(submitted || touched.sucursal_largo) && $rules.obligatoria()(formObj.sucursal_largo) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Teléfono -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Teléfono</label>
                            <BaseInput
                                v-model="formObj.telefono"
                                :maxlength="100"
                                size="sm"
                                placeholder="Ej: 2-1234567"
                            />
                        </div>

                        <!-- Horario Atención -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Horario de Atención</label>
                            <BaseInput
                                v-model="formObj.horario_atencion"
                                :maxlength="200"
                                size="sm"
                                placeholder="Ej: LUN-VIE 8:00-20:00"
                            />
                        </div>

                        <!-- Ubicación -->
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Ubicación</label>
                            <BaseInput
                                v-model="formObj.ubicacion"
                                :maxlength="500"
                                size="sm"
                                placeholder="Dirección completa de la sucursal"
                            />
                        </div>

                        <!-- Factor Venta -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Factor Venta
                            </label>
                            <BaseInput
                                v-model.number="formObj.factor_venta"
                                type="number"
                                step="0.01"
                                :min="1.01"
                                size="sm"
                                placeholder="1.50"
                                @blur="touched.factor_venta = true"
                            />
                            <small
                                v-if="(submitted || touched.factor_venta) && formObj.factor_venta && $rules.factorMayorQueUno()(formObj.factor_venta) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.factorMayorQueUno()(formObj.factor_venta) }}
                            </small>
                        </div>

                        <!-- Factor Facturación -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Factor Facturación
                            </label>
                            <BaseInput
                                v-model.number="formObj.factor_facturacion"
                                type="number"
                                step="0.01"
                                :min="1.01"
                                size="sm"
                                placeholder="1.19"
                                @blur="touched.factor_facturacion = true"
                            />
                            <small
                                v-if="(submitted || touched.factor_facturacion) && formObj.factor_facturacion && $rules.factorMayorQueUno()(formObj.factor_facturacion) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.factorMayorQueUno()(formObj.factor_facturacion) }}
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
            title="Eliminar Sucursal"
            :item-name="deleteItemName"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    import { ref, computed, shallowRef, watch, nextTick } from 'vue';
    import { ESTADO_ACTIVO } from '~/constants/estados.constant';

    useHead({ title: 'Sucursales | SIRENA' });

    interface EmpresaOption {
        label: string;
        value: number;
    }

    const { $rules } = useNuxtApp() as any;
    const { $api } = useNuxtApp() as any;
    const authStore = useAuthStore();

    const empresaOptions = shallowRef<EmpresaOption[]>([]);
    const loadingEmpresas = ref(false);

    const opcionesExactMatch = [
        { label: 'Parecido', value: 0 },
        { label: 'Exacto',   value: 1 },
    ];

    const empresaIdInicial = Number(authStore.user?.empresa_id) || null;

    const cargarEmpresas = async () => {
        loadingEmpresas.value = true;
        try {
            const res = await $api('/empresas', {
                method: 'GET',
                params: { limit: 100, sortField: 'empresa', sortOrder: 1, estado_id: ESTADO_ACTIVO },
            });

            const lista = Array.isArray(res) ? res : (res?.data ?? []);

            empresaOptions.value = lista.map((e: any): EmpresaOption => ({
                label: `${e.codigo} — ${e.empresa}`,
                value: Number(e.empresa_id),
            }));
        } catch (err) {
            console.error('Error al cargar empresas:', err);
            empresaOptions.value = [];
        } finally {
            loadingEmpresas.value = false;
        }
    };

    const sugerirCodigoSin = async (empresaId: number | null | undefined): Promise<void> => {
        if (!empresaId) {
            formObj.value.codigo_sin = 0;
            return;
        }

        try {
            const res = await $api('/sucursales/siguiente-codigo-sin', {
                method: 'GET',
                params: { empresa_id: Number(empresaId) },
            });

            const siguiente = Number(res?.codigo_sin);
            formObj.value.codigo_sin = Number.isFinite(siguiente) && siguiente >= 0 ? siguiente : 0;
        } catch (err) {
            console.warn('No se pudo obtener el siguiente codigo_sin:', err);
            formObj.value.codigo_sin = 0;
        }
    };

    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos, estaProtegido,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
    } = useCrudTable<any>({
        tabla: 'sucursales',
        sortFieldDefault: 'sucursal_id',
        rowsDefault: 10,
        autoLoad: false,

        camposProtegidosPorDependencia: ['empresa_id', 'sucursal', 'sucursal_largo', 'codigo', 'codigo_sin'],

        defaultFilters: {
            global: '',
            exactMatch: 0,
            empresa_id: empresaIdInicial,
        },

        getExtraFilters: (f) => {
            const extra: Record<string, any> = {
                exactMatch: f.exactMatch ?? 0,
            };
            if (f.empresa_id) extra.empresa_id = Number(f.empresa_id);
            return extra;
        },

        getPrimaryKey: (item) => item.sucursal_id,

        getCleanForm: () => ({
            sucursal_id: null,
            empresa_id: empresaIdInicial ? Number(empresaIdInicial) : null,
            sucursal: '',
            sucursal_largo: '',
            codigo: '',
            codigo_sin: 0,
            telefono: '',
            ubicacion: '',
            horario_atencion: '',
            factor_venta: 1.50,
            factor_facturacion: 1.19,
        }),

        buildPayload: (form) => {
            const payload: Record<string, any> = {
                empresa_id: Number(form.empresa_id),
                sucursal: form.sucursal?.trim().toUpperCase(),
                sucursal_largo: form.sucursal_largo?.trim().toUpperCase(),
                codigo: form.codigo?.trim().toUpperCase(),
                codigo_sin: Number(form.codigo_sin),
            };

            if (form.telefono?.trim()) payload.telefono = form.telefono.trim();
            if (form.ubicacion?.trim()) payload.ubicacion = form.ubicacion.trim();
            if (form.horario_atencion?.trim()) payload.horario_atencion = form.horario_atencion.trim();
            if (form.factor_venta !== null && form.factor_venta !== undefined) {
                payload.factor_venta = Number(form.factor_venta);
            }
            if (form.factor_facturacion !== null && form.factor_facturacion !== undefined) {
                payload.factor_facturacion = Number(form.factor_facturacion);
            }

            return payload;
        },

        validate: (form, rules, notify) => {
            if (rules.obligatoria()(form.empresa_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar una empresa.');
                return false;
            }
            if (rules.obligatoria()(form.sucursal) !== true) {
                notify('warn', 'Campos incompletos', 'El nombre de la sucursal es obligatorio.');
                return false;
            }
            if (rules.obligatoria()(form.sucursal_largo) !== true) {
                notify('warn', 'Campos incompletos', 'El nombre largo de la sucursal es obligatorio.');
                return false;
            }
            if (rules.codigoMayusculas(3)(form.codigo) !== true) {
                notify('warn', 'Código inválido', rules.codigoMayusculas(3)(form.codigo));
                return false;
            }
            if (rules.soloEnteros()(form.codigo_sin) !== true) {
                notify('warn', 'Código SIN inválido', 'El código SIN debe ser un número entero.');
                return false;
            }
            if (form.codigo_sin === null || form.codigo_sin === undefined || form.codigo_sin < 0) {
                notify('warn', 'Código SIN inválido', 'El código SIN debe ser mayor o igual a 0.');
                return false;
            }
            if (form.factor_venta && rules.factorMayorQueUno()(form.factor_venta) !== true) {
                notify('warn', 'Factor Venta inválido', 'El factor de venta debe ser mayor a 1.');
                return false;
            }
            if (form.factor_facturacion && rules.factorMayorQueUno()(form.factor_facturacion) !== true) {
                notify('warn', 'Factor Facturación inválido', 'El factor de facturación debe ser mayor a 1.');
                return false;
            }
            return true;
        },
    });

    const deleteItemName = computed(() => {
        const codigo = formObj.value.codigo ?? '';
        const sucursal = formObj.value.sucursal ?? '';
        return `${codigo} — ${sucursal}`;
    });

    const onEmpresaChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const openNewConEmpresa = async () => {
        openNew();
        const empresaId = filters.value.empresa_id ? Number(filters.value.empresa_id) : null;

        if (empresaId) {
            formObj.value.empresa_id = empresaId;
            await sugerirCodigoSin(empresaId);
        } else {
            formObj.value.codigo_sin = 0;
        }
    };

    const columns = [
        { field: 'codigo', header: 'CÓDIGO', sortable: true, template: 'body-codigo', bodyClass: '!text-center', class: 'w-28' },
        { field: 'codigo_sin', header: 'CÓD. SIN', sortable: true, template: 'body-codigo_sin', bodyClass: '!text-center', class: 'w-24' },
        { field: 'sucursal', header: 'SUCURSAL', sortable: true, template: 'body-sucursal' },
        { field: 'empresa_nombre', header: 'EMPRESA', sortable: true, template: 'body-empresa', class: 'w-48' },
        { field: 'factor_venta', header: 'F. VENTA', sortable: true, template: 'body-factor_venta', bodyClass: '!text-center', class: 'w-24' },
        { field: 'factor_facturacion', header: 'F. FACT.', sortable: true, template: 'body-factor_facturacion', bodyClass: '!text-center', class: 'w-24' },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    const sucursalRef = ref<any>(null);
    const empresaSelectRef = ref<any>(null);

    const focusEmpresa = async () => {
        await nextTick();
        setTimeout(() => {
            const el = empresaSelectRef.value?.getSelectEl?.() as HTMLElement | null;
            if (!el) return;

            // El trigger clickeable es el label interno de PrimeVue
            const trigger = el.querySelector('.p-select-label') as HTMLElement | null;

            if (trigger) {
                // Enfocamos y abrimos el dropdown
                trigger.focus();
                trigger.click();
            } else {
                // Fallback: click directo en el contenedor
                el.click();
            }
        }, 350);
    };

    const handleEdit = async (item: any) => {
        if (empresaOptions.value.length === 0) {
            await cargarEmpresas();
        }

        const empresaId = item.empresa_id != null ? Number(item.empresa_id) : null;
        const existe = empresaOptions.value.some(o => o.value === empresaId);

        if (empresaId && !existe) {
            empresaOptions.value = [
                ...empresaOptions.value,
                {
                    label: item.empresa_nombre
                        ? `${item.empresa_codigo ?? ''} — ${item.empresa_nombre}`.trim()
                        : `Empresa ${empresaId}`,
                    value: empresaId,
                },
            ];
        }

        edit(item);
        formObj.value.empresa_id = empresaId;
        formObj.value.factor_venta = item.factor_venta ? Number(item.factor_venta) : 1.50;
        formObj.value.factor_facturacion = item.factor_facturacion ? Number(item.factor_facturacion) : 1.19;
        formObj.value.codigo_sin = item.codigo_sin != null ? Number(item.codigo_sin) : 0;
    };

    watch(
        () => formObj.value.empresa_id,
        async (newId, oldId) => {
            if (isUpdate.value) { return; }
            if (!newId || newId === oldId) { return; }
            if (!dialog.value) { return; }
            await sugerirCodigoSin(Number(newId));
        }
    );

    watch(dialog, async (isOpen) => {
        if (!isOpen) return;

        await nextTick();
        setTimeout(() => {
            if (formObj.value.empresa_id != null) {
                formObj.value.empresa_id = Number(formObj.value.empresa_id);
            }
            if (formObj.value.codigo_sin != null) {
                formObj.value.codigo_sin = Number(formObj.value.codigo_sin);
            }
            if (formObj.value.factor_venta != null) {
                formObj.value.factor_venta = Number(formObj.value.factor_venta);
            }
            if (formObj.value.factor_facturacion != null) {
                formObj.value.factor_facturacion = Number(formObj.value.factor_facturacion);
            }

            const empresaId = formObj.value.empresa_id;
            if (empresaId && !empresaOptions.value.some(o => o.value === empresaId)) {
                const item = items.value.find((i: any) => Number(i.empresa_id) === empresaId);
                empresaOptions.value = [
                    ...empresaOptions.value,
                    {
                        label: item
                            ? `${item.empresa_codigo ?? ''} — ${item.empresa_nombre}`.trim()
                            : `Empresa ${empresaId}`,
                        value: empresaId,
                    },
                ];
            }
        }, 150);
    });

    onMounted(async () => {
        await cargarEmpresas();

        if (filters.value.empresa_id) {
            onSearch();
        }
    });
</script>
