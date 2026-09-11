<!-- C:\sirena\sirena-frontend\app\pages\configuracion\tipos-cambio\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <!-- ENCABEZADO -->
        <CrudPageHeader
            icon="pi pi-dollar"
            title="Tipos de Cambio"
            subtitle="Cotizaciones de monedas por fecha"
            :show-action="permisos.crear"
            action-label="NUEVO TIPO DE CAMBIO"
            action-icon="pi pi-plus"
            @action="openNew"
        />

        <!-- TABLA -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
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
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="flex flex-col gap-3">
                                <div>
                                    <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                        Moneda Origen
                                    </label>
                                    <BaseSelect
                                        v-model="filters.origen_moneda_id"
                                        :options="monedaOptions"
                                        option-label="label"
                                        option-value="value"
                                        placeholder="Seleccionar moneda origen..."
                                        size="sm"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>

                                <div>
                                    <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                        Moneda Destino
                                    </label>
                                    <BaseSelect
                                        v-model="filters.destino_moneda_id"
                                        :options="monedaOptions"
                                        option-label="label"
                                        option-value="value"
                                        placeholder="Seleccionar moneda destino..."
                                        size="sm"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>
                            </div>

                            <div class="flex flex-col gap-3">
                                <div>
                                    <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                        Desde
                                    </label>
                                    <BaseInput
                                        v-model="filters.fecha_cotizacion_desde"
                                        type="date"
                                        size="sm"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>

                                <div>
                                    <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                        Hasta
                                    </label>
                                    <BaseInput
                                        v-model="filters.fecha_cotizacion_hasta"
                                        type="date"
                                        size="sm"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>
                            </div>

                        </div>
                    </div>
                </template>

                <!-- Fecha -->
                <template #body-fecha="{ data }">
                    <span class="font-mono text-slate-700 font-bold">{{ data.fecha_cotizacion }}</span>
                </template>

                <!-- Origen -->
                <template #body-origen="{ data }">
                    <Tag
                        :value="data.origen_moneda?.abreviatura || '—'"
                        severity="secondary"
                        class="text-[10px] font-bold uppercase px-2"
                    />
                </template>

                <!-- Destino -->
                <template #body-destino="{ data }">
                    <Tag
                        :value="data.destino_moneda?.abreviatura || '—'"
                        severity="info"
                        class="text-[10px] font-bold uppercase px-2"
                    />
                </template>

                <!-- Factores -->
                <template #body-factores="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight items-center">
                        <span class="text-emerald-700 font-bold">C: {{ data.factor_compra }}</span>
                        <span class="text-red-700 font-bold">V: {{ data.factor_venta }}</span>
                    </div>
                </template>

                <!-- Estado -->
                <template #body-estado="{ data }">
                    <CrudEstadoBadge
                        :estado="data.estado_registro"
                        :estado-id="data.estado_id"
                    />
                </template>

                <!-- Acciones -->
                <template #body-acciones="{ data }">
                    <CrudRowActions
                        :estado-id="data.estado_id"
                        :puede="permisos"
                        @edit="edit(data)"
                        @toggle="toggleEstado(data)"
                        @delete="confirmDelete(data)"
                    />
                </template>
            </BaseTable>
        </div>

        <!-- DIALOG CREAR / EDITAR -->
        <Dialog
            v-model:visible="dialog"
            :style="{ width: '720px', maxHeight: '90vh' }"
            :modal="true"
            :closable="!loading"
            class="custom-modal"
        >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow">
                        <i class="pi pi-dollar text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Cotización entre dos monedas</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                        <span>Información del Tipo de Cambio</span>
                        <span class="text-slate-600 normal-case font-bold text-[10px]">
                            Campos obligatorios <span class="text-red-500">*</span>
                        </span>
                    </div>

                    <div class="grid grid-cols-12 gap-x-4 gap-y-3">
                        <!-- Moneda Origen -->
                        <div class="col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Moneda Origen <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                v-model="formObj.origen_moneda_id"
                                :options="monedaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar..."
                                size="sm"
                                @update:model-value="touched.origen_moneda_id = true"
                            />
                            <small
                                v-if="(submitted || touched.origen_moneda_id) && !formObj.origen_moneda_id"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Moneda Destino -->
                        <div class="col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Moneda Destino <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                v-model="formObj.destino_moneda_id"
                                :options="monedaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar..."
                                size="sm"
                                @update:model-value="touched.destino_moneda_id = true"
                            />
                            <small
                                v-if="(submitted || touched.destino_moneda_id) && !formObj.destino_moneda_id"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Aviso monedas iguales -->
                        <div v-if="monedaError" class="col-span-12">
                            <div class="flex items-start gap-2 bg-red-50 border border-red-200 text-red-700 p-2 rounded-lg">
                                <i class="pi pi-exclamation-circle mt-0.5 text-xs"></i>
                                <span class="text-[10px] font-semibold">{{ monedaError }}</span>
                            </div>
                        </div>

                        <!-- Fecha Cotización -->
                        <div class="col-span-4">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Fecha Cotización <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.fecha_cotizacion"
                                type="date"
                                size="sm"
                                @blur="touched.fecha_cotizacion = true"
                            />
                            <small
                                v-if="(submitted || touched.fecha_cotizacion) && !formObj.fecha_cotizacion"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Factor Compra -->
                        <div class="col-span-4">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Factor Compra <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.factor_compra"
                                type="number"
                                step="0.0001"
                                min="0.0001"
                                size="sm"
                                @blur="touched.factor_compra = true"
                            />
                            <small
                                v-if="(submitted || touched.factor_compra) && !esFactorValido(formObj.factor_compra)"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Debe ser mayor a 0
                            </small>
                        </div>

                        <!-- Factor Venta -->
                        <div class="col-span-4">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Factor Venta <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.factor_venta"
                                type="number"
                                step="0.0001"
                                min="0.0001"
                                size="sm"
                                @blur="touched.factor_venta = true"
                            />
                            <small
                                v-if="(submitted || touched.factor_venta) && !esFactorValido(formObj.factor_venta)"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Debe ser mayor a 0
                            </small>
                        </div>

                        <!-- Aviso factor_compra <= factor_venta -->
                        <div v-if="factoresInvalidos" class="col-span-12">
                            <div class="flex items-start gap-2 bg-amber-50 border border-amber-200 text-amber-800 p-2 rounded-lg">
                                <i class="pi pi-exclamation-triangle mt-0.5 text-xs"></i>
                                <span class="text-[10px] font-semibold">
                                    El factor de compra debe ser menor o igual al factor de venta.
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Vista previa de conversión -->
                <div v-if="isUpdate && esFactorValido(formObj.factor_venta)" class="mt-4 bg-slate-50 p-4 rounded-2xl border border-slate-200">
                    <div class="flex items-center gap-2 mb-2 text-slate-700 uppercase font-black text-[10px]">
                        <i class="pi pi-calculator"></i>
                        <span>Vista previa de conversión</span>
                    </div>
                    <div class="flex items-center gap-3 text-xs">
                        <span class="font-mono font-bold text-slate-700">1 {{ monedaOrigenAbrev }}</span>
                        <i class="pi pi-arrow-right text-slate-400"></i>
                        <span class="font-mono font-bold text-slate-700">
                            {{ formObj.factor_venta }} {{ monedaDestinoAbrev }}
                        </span>
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

        <!-- DIALOG ELIMINAR -->
        <CrudDeleteDialog
            v-model:visible="deleteDialog"
            title="Eliminar Tipo de Cambio"
            :item-name="deleteItemName"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    import { TipoMoneda, TIPO_MONEDA_METADATA } from '~/constants/estados.constant';

    useHead({ title: 'Tipos de Cambio | SIRENA' });

    const monedaOptions = Object.values(TipoMoneda)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => {
            const meta = TIPO_MONEDA_METADATA[id as TipoMoneda];
            if (!meta) return null;                       // ← narrowing
            return {
                label: `${meta.abreviatura} (${meta.prefijo ?? '—'})`,
                value: id,
            };
        })
        .filter((o): o is { label: string; value: number } => o !== null);

    const esFactorValido = (v: any): boolean => {
        const n = Number(v);
        return Number.isFinite(n) && n > 0;
    };

    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
    } = useCrudTable<any>({
        tabla: 'tipos_cambios',
        sortFieldDefault: 'tipo_cambio_id',
        rowsDefault: 10,

        defaultFilters: {
            global: '',
            exactMatch: 0,
            origen_moneda_id: null,
            destino_moneda_id: null,
        },

        getExtraFilters: (f) => ({
            exactMatch: f.exactMatch ?? 0,
            ...(f.origen_moneda_id ? { origen_moneda_id: f.origen_moneda_id } : {}),
            ...(f.destino_moneda_id ? { destino_moneda_id: f.destino_moneda_id } : {}),
        }),

        getPrimaryKey: (item) => item.tipo_cambio_id,

        getCleanForm: () => ({
            tipo_cambio_id: null,
            origen_moneda_id: TipoMoneda.BOLIVIANO,
            destino_moneda_id: TipoMoneda.DOLAR,
            factor_compra: null,
            factor_venta: null,
            fecha_cotizacion: new Date().toISOString().slice(0, 10),
        }),

        buildPayload: (form) => ({
            origen_moneda_id: Number(form.origen_moneda_id),
            destino_moneda_id: Number(form.destino_moneda_id),
            factor_compra: Number(form.factor_compra),
            factor_venta: Number(form.factor_venta),
            fecha_cotizacion: form.fecha_cotizacion,
        }),

        validate: (form, rules, notify) => {
            if (!form.origen_moneda_id) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar la moneda de origen.');
                return false;
            }
            if (!form.destino_moneda_id) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar la moneda de destino.');
                return false;
            }
            if (form.origen_moneda_id === form.destino_moneda_id) {
                notify('warn', 'Regla de negocio', 'La moneda de origen y destino no pueden ser iguales.');
                return false;
            }
            if (!form.fecha_cotizacion) {
                notify('warn', 'Campos incompletos', 'La fecha de cotización es obligatoria.');
                return false;
            }
            if (!esFactorValido(form.factor_compra)) {
                notify('warn', 'Valor inválido', 'El factor de compra debe ser mayor a 0.');
                return false;
            }
            if (!esFactorValido(form.factor_venta)) {
                notify('warn', 'Valor inválido', 'El factor de venta debe ser mayor a 0.');
                return false;
            }
            if (Number(form.factor_compra) > Number(form.factor_venta)) {
                notify('warn', 'Regla de negocio', 'El factor de compra debe ser menor o igual al factor de venta.');
                return false;
            }
            return true;
        },
    });

    const onFilterChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const monedaError = computed(() => {
        if (!formObj.value.origen_moneda_id || !formObj.value.destino_moneda_id) return '';
        if (formObj.value.origen_moneda_id === formObj.value.destino_moneda_id) {
            return 'La moneda de origen y destino no pueden ser iguales.';
        }
        return '';
    });

    const factoresInvalidos = computed(() => {
        const c = Number(formObj.value.factor_compra);
        const v = Number(formObj.value.factor_venta);
        return Number.isFinite(c) && Number.isFinite(v) && c > v;
    });

    const monedaOrigenAbrev = computed(() =>
        TIPO_MONEDA_METADATA[formObj.value.origen_moneda_id as TipoMoneda]?.abreviatura ?? '—'
    );

    const monedaDestinoAbrev = computed(() =>
        TIPO_MONEDA_METADATA[formObj.value.destino_moneda_id as TipoMoneda]?.abreviatura ?? '—'
    );

    // ============================================
    // Nombre del item para el diálogo de eliminar
    // ============================================
    const deleteItemName = computed(() => {
        const o = TIPO_MONEDA_METADATA[formObj.value.origen_moneda_id as TipoMoneda]?.abreviatura ?? '—';
        const d = TIPO_MONEDA_METADATA[formObj.value.destino_moneda_id as TipoMoneda]?.abreviatura ?? '—';
        return `${o} → ${d} (${formObj.value.fecha_cotizacion ?? ''})`;
    });

    // ============================================
    // Columnas de la tabla
    // ============================================
    const columns = [
        {
            field: 'tipo_cambio_id',
            header: 'ID',
            sortable: true,
            bodyClass: '!text-center',
            class: 'w-16',
        },
        {
            field: 'fecha_cotizacion',
            header: 'FECHA',
            sortable: true,
            template: 'body-fecha',
            bodyClass: '!text-center',
            class: 'w-32',
        },
        {
            field: 'origen_moneda_id',
            header: 'ORIGEN',
            sortable: true,
            template: 'body-origen',
            bodyClass: '!text-center',
            class: 'w-24',
        },
        {
            field: 'destino_moneda_id',
            header: 'DESTINO',
            sortable: true,
            template: 'body-destino',
            bodyClass: '!text-center',
            class: 'w-24',
        },
        {
            field: 'factor_compra',
            header: 'FACTORES',
            sortable: false,
            template: 'body-factores',
            bodyClass: '!text-center',
            class: 'w-28',
        },
        {
            field: 'estado_registro',
            header: 'ESTADO',
            template: 'body-estado',
            bodyClass: '!text-center',
            class: 'w-24',
            sortable: false,
        },
        {
            header: 'ACCIONES',
            template: 'body-acciones',
            class: '!text-center !w-28',
            sortable: false,
        },
    ];
</script>
