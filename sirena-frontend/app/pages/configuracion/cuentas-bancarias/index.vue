<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <CrudPageHeader
            icon="pi pi-credit-card"
            title="Cuentas Bancarias"
            subtitle="Registro de cuentas bancarias por empresa"
            :show-action="permisos.crear"
            :action-disabled="!filters.empresa_id"
            action-disabled-tooltip="Seleccione una empresa para crear una cuenta"
            action-label="NUEVA CUENTA"
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
                    <div class="px-4 py-3 bg-white border-b border-slate-200 max-h-[45vh] overflow-y-auto">
                        <!-- Fila 1: Empresa, Buscar, Coincidencia -->
                        <div class="grid grid-cols-1 md:grid-cols-12 gap-4 items-end">
                            <div class="md:col-span-6 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Empresa
                                </label>
                                <BaseSelect
                                    v-model="filters.empresa_id"
                                    :options="empresaOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todas las empresas"
                                    size="sm"
                                    filter
                                    show-clear
                                    :loading="loadingEmpresas"
                                    @update:model-value="onEmpresaChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="md:col-span-4 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Buscar
                                </label>
                                <BaseSearch
                                    autofocus
                                    v-model="filters.global"
                                    placeholder="Nro. cuenta, titular, banco..."
                                    @search="onSearch"
                                    class="w-full"
                                />
                            </div>

                            <div class="md:col-span-2 w-full">
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

                        <!-- Fila 2: Banco, Tipo Moneda, Tipo Cuenta -->
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4 items-end">
                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Banco
                                </label>
                                <BaseSelect
                                    v-model="filters.banco_id"
                                    :options="bancoOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todos"
                                    size="sm"
                                    filter
                                    show-clear
                                    :loading="loadingBancos"
                                    @update:model-value="onFilterChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Tipo Moneda
                                </label>
                                <BaseSelect
                                    v-model="filters.tipo_moneda_id"
                                    :options="tipoMonedaOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todas"
                                    size="sm"
                                    show-clear
                                    @update:model-value="onFilterChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Tipo Cuenta
                                </label>
                                <BaseSelect
                                    v-model="filters.tipo_cuenta_id"
                                    :options="tipoCuentaOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todas"
                                    size="sm"
                                    show-clear
                                    @update:model-value="onFilterChange"
                                    class="w-full"
                                />
                            </div>
                        </div>
                    </div>
                </template>

                <template #body-nro_cuenta="{ data }">
                    <div class="flex flex-col">
                        <span class="font-mono font-bold text-blue-600">{{ data.nro_cuenta }}</span>
                        <span class="text-[9px] text-slate-400 font-semibold uppercase">
                            {{ data.tipo_cuenta?.abreviatura || '—' }}
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

                <template #body-banco="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight">
                        <span class="font-bold text-slate-700">{{ data.banco_nombre || '—' }}</span>
                        <span v-if="data.banco_abreviatura" class="text-slate-400 font-mono">
                            {{ data.banco_abreviatura }}
                            <span v-if="data.banco_codigo_asfi"> · ASFI {{ data.banco_codigo_asfi }}</span>
                        </span>
                    </div>
                </template>

                <template #body-titular="{ data }">
                    <span class="text-[10px] font-semibold text-slate-700 truncate max-w-full" :title="data.titular">
                        {{ data.titular }}
                    </span>
                </template>

                <template #body-tipo_moneda="{ data }">
                    <Tag
                        :value="data.tipo_moneda?.abreviatura || '—'"
                        :severity="data.tipo_moneda?.abreviatura === 'BOLIVIANO' ? 'success' : 'info'"
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
                        <i class="pi pi-credit-card text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos de la cuenta bancaria</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                        <span>Información de la Cuenta</span>
                        <span class="text-slate-600 normal-case font-bold text-[10px]">
                            Campos obligatorios <span class="text-red-500">*</span>
                        </span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                        <!-- Empresa -->
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
                                :disabled="estaProtegido('empresa_id')"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('empresa_id') }"
                                @update:model-value="touched.empresa_id = true"
                            />
                            <small v-if="estaProtegido('empresa_id')" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.empresa_id) && $rules.obligatoria()(formObj.empresa_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Banco -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Banco <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                v-model="formObj.banco_id"
                                :options="bancoOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar banco..."
                                size="sm"
                                filter
                                :loading="loadingBancos"
                                :disabled="estaProtegido('banco_id')"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('banco_id') }"
                                @update:model-value="touched.banco_id = true"
                            />
                            <small v-if="estaProtegido('banco_id')" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.banco_id) && $rules.seleccionObligatoria()(formObj.banco_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Nro Cuenta -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Nro. Cuenta <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.nro_cuenta"
                                :maxlength="50"
                                size="sm"
                                placeholder="Ej: 1234567890"
                                :disabled="estaProtegido('nro_cuenta')"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('nro_cuenta') }"
                                @blur="touched.nro_cuenta = true"
                            />
                            <small v-if="estaProtegido('nro_cuenta')" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.nro_cuenta) && $rules.numeroCuenta()(formObj.nro_cuenta) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.numeroCuenta()(formObj.nro_cuenta) }}
                            </small>
                        </div>

                        <!-- Tipo Moneda -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Tipo Moneda <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                v-model="formObj.tipo_moneda_id"
                                :options="tipoMonedaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar..."
                                size="sm"
                                @update:model-value="touched.tipo_moneda_id = true"
                            />
                            <small
                                v-if="(submitted || touched.tipo_moneda_id) && $rules.seleccionObligatoria()(formObj.tipo_moneda_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Tipo Cuenta -->
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Tipo Cuenta <span class="text-red-500">*</span>
                            </label>
                            <BaseSelect
                                v-model="formObj.tipo_cuenta_id"
                                :options="tipoCuentaOptions"
                                option-label="label"
                                option-value="value"
                                placeholder="Seleccionar..."
                                size="sm"
                                @update:model-value="touched.tipo_cuenta_id = true"
                            />
                            <small
                                v-if="(submitted || touched.tipo_cuenta_id) && $rules.seleccionObligatoria()(formObj.tipo_cuenta_id) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>

                        <!-- Titular -->
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                Titular <span class="text-red-500">*</span>
                            </label>
                            <BaseInput
                                v-model="formObj.titular"
                                :maxlength="150"
                                size="sm"
                                placeholder="Ej: FARMACIA SALUD Y VIDA S.R.L."
                                :disabled="estaProtegido('titular')"
                                :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('titular') }"
                                @blur="touched.titular = true"
                            />
                            <small v-if="estaProtegido('titular')" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.titular) && $rules.longitudMinima(3)(formObj.titular) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                {{ $rules.longitudMinima(3)(formObj.titular) }}
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
            title="Eliminar Cuenta Bancaria"
            :item-name="deleteItemName"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    import { ref, computed, shallowRef, watch, nextTick } from 'vue';
    import {
        TipoMoneda, TIPO_MONEDA_METADATA,
        TipoCuenta, TIPO_CUENTA_METADATA,
        ESTADO_ACTIVO,
    } from '~/constants/estados.constant';

    useHead({ title: 'Cuentas Bancarias | SIRENA' });

    interface OptionItem {
        label: string;
        value: number;
    }

    const { $rules } = useNuxtApp() as any;
    const { $api } = useNuxtApp() as any;
    const authStore = useAuthStore();

    // ---------- Catálogos (empresas / bancos) ----------
    const empresaOptions = shallowRef<OptionItem[]>([]);
    const bancoOptions = shallowRef<OptionItem[]>([]);
    const loadingEmpresas = ref(false);
    const loadingBancos = ref(false);

    // ---------- Opciones de constantes (moneda / tipo cuenta) ----------
    const tipoMonedaOptions: OptionItem[] = Object.values(TipoMoneda)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => {
            const meta = TIPO_MONEDA_METADATA[id as TipoMoneda];
            return meta ? { label: meta.abreviatura, value: id } : null;
        })
        .filter((o): o is OptionItem => o !== null);

    const tipoCuentaOptions: OptionItem[] = Object.values(TipoCuenta)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => {
            const meta = TIPO_CUENTA_METADATA[id as TipoCuenta];
            return meta ? { label: meta.abreviatura, value: id } : null;
        })
        .filter((o): o is OptionItem => o !== null);

    const opcionesExactMatch: OptionItem[] = [
        { label: 'Parecido', value: 0 },
        { label: 'Exacto',   value: 1 },
    ];

    const empresaIdInicial = Number(authStore.user?.empresa_id) || null;

    // ---------- Carga de empresas ----------
    const cargarEmpresas = async () => {
        loadingEmpresas.value = true;
        try {
            const res = await $api('/empresas', {
                method: 'GET',
                params: { limit: 100, sortField: 'empresa', sortOrder: 1, estado_id: ESTADO_ACTIVO },
            });
            const lista = Array.isArray(res) ? res : (res?.data ?? []);
            empresaOptions.value = lista.map((e: any): OptionItem => ({
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

    // ---------- Carga de bancos ----------
    const cargarBancos = async () => {
        loadingBancos.value = true;
        try {
            const res = await $api('/bancos', {
                method: 'GET',
                params: { limit: 100, sortField: 'banco', sortOrder: 1, estado_id: ESTADO_ACTIVO },
            });
            const lista = Array.isArray(res) ? res : (res?.data ?? []);
            bancoOptions.value = lista.map((b: any): OptionItem => ({
                label: `${b.abreviatura} — ${b.banco}`,
                value: Number(b.banco_id),
            }));
        } catch (err) {
            console.error('Error al cargar bancos:', err);
            bancoOptions.value = [];
        } finally {
            loadingBancos.value = false;
        }
    };

    // ---------- CRUD ----------
    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos, estaProtegido,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
    } = useCrudTable<any>({
        tabla: 'empresas_cuentas',
        sortFieldDefault: 'empresa_cuenta_id',
        rowsDefault: 10,
        autoLoad: false,

        defaultFilters: {
            global: '',
            exactMatch: 0,
            empresa_id: empresaIdInicial,
            banco_id: null,
            tipo_moneda_id: null,
            tipo_cuenta_id: null,
        },

        getExtraFilters: (f) => {
            const extra: Record<string, any> = {
                exactMatch: f.exactMatch ?? 0,
            };
            if (f.empresa_id) extra.empresa_id = Number(f.empresa_id);
            if (f.banco_id) extra.banco_id = Number(f.banco_id);
            if (f.tipo_moneda_id) extra.tipo_moneda_id = f.tipo_moneda_id;
            if (f.tipo_cuenta_id) extra.tipo_cuenta_id = f.tipo_cuenta_id;
            return extra;
        },

        getPrimaryKey: (item) => item.empresa_cuenta_id,

        getCleanForm: () => ({
            empresa_cuenta_id: null,
            empresa_id: empresaIdInicial ? Number(empresaIdInicial) : null,
            banco_id: null,
            tipo_moneda_id: TipoMoneda.BOLIVIANO,
            nro_cuenta: '',
            tipo_cuenta_id: TipoCuenta.NO_APLICA,
            titular: '',
        }),

        buildPayload: (form) => ({
            empresa_id: Number(form.empresa_id),
            banco_id: Number(form.banco_id),
            tipo_moneda_id: Number(form.tipo_moneda_id),
            nro_cuenta: form.nro_cuenta?.trim(),
            tipo_cuenta_id: Number(form.tipo_cuenta_id),
            titular: form.titular?.trim().toUpperCase(),
        }),

        validate: (form, rules, notify) => {
            if (rules.obligatoria()(form.empresa_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar una empresa.');
                return false;
            }
            if (rules.seleccionObligatoria()(form.banco_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar un banco.');
                return false;
            }
            if (rules.numeroCuenta()(form.nro_cuenta) !== true) {
                notify('warn', 'Nro. cuenta inválido', rules.numeroCuenta()(form.nro_cuenta));
                return false;
            }
            if (rules.seleccionObligatoria()(form.tipo_moneda_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar un tipo de moneda.');
                return false;
            }
            if (rules.seleccionObligatoria()(form.tipo_cuenta_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar un tipo de cuenta.');
                return false;
            }
            if (rules.longitudMinima(3)(form.titular) !== true) {
                notify('warn', 'Campos incompletos', 'El titular es obligatorio (mín. 3 caracteres).');
                return false;
            }
            return true;
        },
    });

    // ---------- Helpers de la pantalla ----------
    const deleteItemName = computed(() => {
        const nro = formObj.value.nro_cuenta ?? '';
        const titular = formObj.value.titular ?? '';
        return `Cuenta ${nro} — ${titular}`;
    });

    const onFilterChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const onEmpresaChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const openNewConEmpresa = () => {
        if (!filters.value.empresa_id) return;
        openNew();
        formObj.value.empresa_id = Number(filters.value.empresa_id);
    };

    // ---------- Columnas ----------
    const columns = [
        { field: 'nro_cuenta',      header: 'NRO. CUENTA',  sortable: true, template: 'body-nro_cuenta',  bodyClass: '!text-center', class: 'w-40' },
        { field: 'empresa_nombre',  header: 'EMPRESA',       sortable: true, template: 'body-empresa',     class: 'w-48' },
        { field: 'banco_nombre',    header: 'BANCO',         sortable: true, template: 'body-banco',       class: 'w-44' },
        { field: 'titular',         header: 'TITULAR',       sortable: true, template: 'body-titular' },
        { field: 'tipo_moneda_id',  header: 'MONEDA',        sortable: true, template: 'body-tipo_moneda', bodyClass: '!text-center', class: 'w-28' },
        { field: 'estado_registro', header: 'ESTADO',        template: 'body-estado',     bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES',       template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    const empresaSelectRef = ref<any>(null);

    const focusEmpresa = async () => {
        await nextTick();
        setTimeout(() => {
            const el = empresaSelectRef.value?.$el as HTMLElement | null;
            if (!el) return;
            const trigger = el.querySelector('.p-select-label') as HTMLElement | null;
            trigger?.click();
        }, 350);
    };

    // ---------- Edit ----------
    const handleEdit = async (item: any) => {
        // Asegurar catálogos cargados
        if (empresaOptions.value.length === 0) await cargarEmpresas();
        if (bancoOptions.value.length === 0)   await cargarBancos();

        // Normalizar a number
        const empresaId = item.empresa_id != null ? Number(item.empresa_id) : null;
        const bancoId   = item.banco_id   != null ? Number(item.banco_id)   : null;

        // Agregar opciones temporales si no existen
        if (empresaId && !empresaOptions.value.some(o => o.value === empresaId)) {
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
        if (bancoId && !bancoOptions.value.some(o => o.value === bancoId)) {
            bancoOptions.value = [
                ...bancoOptions.value,
                {
                    label: item.banco_nombre
                        ? `${item.banco_abreviatura ?? ''} — ${item.banco_nombre}`.trim()
                        : `Banco ${bancoId}`,
                    value: bancoId,
                },
            ];
        }

        edit(item);

        // Forzar tipos numéricos después del fetch del detalle
        formObj.value.empresa_id = empresaId;
        formObj.value.banco_id = bancoId;
        formObj.value.tipo_moneda_id = Number(item.tipo_moneda_id);
        formObj.value.tipo_cuenta_id = Number(item.tipo_cuenta_id);
    };

    // ---------- Watch: convertir strings → numbers cuando llegue el detalle ----------
    watch(() => formObj.value.empresa_id, (val) => {
        if (val != null && val !== '' && typeof val === 'string') {
            formObj.value.empresa_id = Number(val);
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
    });

    watch(() => formObj.value.banco_id, (val) => {
        if (val != null && val !== '' && typeof val === 'string') {
            formObj.value.banco_id = Number(val);
        }
        const bancoId = formObj.value.banco_id;
        if (bancoId && !bancoOptions.value.some(o => o.value === bancoId)) {
            const item = items.value.find((i: any) => Number(i.banco_id) === bancoId);
            bancoOptions.value = [
                ...bancoOptions.value,
                {
                    label: item
                        ? `${item.banco_abreviatura ?? ''} — ${item.banco_nombre}`.trim()
                        : `Banco ${bancoId}`,
                    value: bancoId,
                },
            ];
        }
    });

    watch(() => formObj.value.tipo_moneda_id, (val) => {
        if (val != null && val !== '' && typeof val === 'string') {
            formObj.value.tipo_moneda_id = Number(val);
        }
    });

    watch(() => formObj.value.tipo_cuenta_id, (val) => {
        if (val != null && val !== '' && typeof val === 'string') {
            formObj.value.tipo_cuenta_id = Number(val);
        }
    });

    // ---------- Init ----------
    onMounted(async () => {
        await Promise.all([cargarEmpresas(), cargarBancos()]);
        onSearch();
    });
</script>
