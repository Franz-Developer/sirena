<!-- C:\sirena\sirena-frontend\app\pages\configuracion\nits\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <CrudPageHeader
            icon="pi pi-id-card"
            title="NITs Fiscales"
            subtitle="Registro de NITs, dosificaciones y datos fiscales por empresa"
            :show-action="permisos.crear && !!filters.empresa_id"
            action-label="NUEVO NIT"
            action-icon="pi pi-plus"
            @action="openNewConEmpresa"
        />

        <div
            v-if="!filters.empresa_id && !loadingEmpresas"
            class="mb-4 flex items-start gap-3 bg-amber-50 border border-amber-200 text-amber-800 p-4 rounded-2xl"
        >
            <i class="pi pi-info-circle mt-0.5 text-lg"></i>
            <div class="flex flex-col">
                <span class="text-xs font-black uppercase tracking-wider">Seleccione una empresa</span>
                <p class="text-[11px] font-semibold mt-0.5">
                    El listado de NITs requiere filtrar por empresa. Seleccione una para continuar.
                </p>
            </div>
        </div>

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
                        <!-- Primera fila: Empresa, Buscar, Coincidencia -->
                        <div class="grid grid-cols-1 md:grid-cols-12 gap-4 items-end">
                            <div class="md:col-span-6 w-full">
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
                                    @update:model-value="onEmpresaChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="md:col-span-4 w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Buscar
                                </label>
                                <BaseSearch
                                    v-model="filters.global"
                                    placeholder="NIT, razón social, etiqueta..."
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

                        <!-- Segunda fila: Ambiente, Modalidad, Inicio Vigencia, Fin Vigencia -->
                        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4 items-end">
                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Ambiente
                                </label>
                                <BaseSelect
                                    v-model="filters.ambiente_id"
                                    :options="ambienteOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Todos"
                                    size="sm"
                                    show-clear
                                    @update:model-value="onFilterChange"
                                    class="w-full"
                                />
                            </div>

                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Modalidad Facturación
                                </label>
                                <BaseSelect
                                    v-model="filters.modalidad_facturacion_id"
                                    :options="modalidadOptions"
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
                                    Inicio Vigencia
                                </label>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 w-full">
                                    <BaseInput
                                        v-model="filters.fecha_inicio_vigencia_desde"
                                        type="date"
                                        size="sm"
                                        placeholder="Desde"
                                        @update:model-value="onFilterChange"
                                        class="w-full"
                                    />
                                    <BaseInput
                                        v-model="filters.fecha_inicio_vigencia_hasta"
                                        type="date"
                                        size="sm"
                                        placeholder="Hasta"
                                        @update:model-value="onFilterChange"
                                        class="w-full"
                                    />
                                </div>
                            </div>

                            <div class="w-full">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Fin Vigencia
                                </label>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 w-full">
                                    <BaseInput
                                        v-model="filters.fecha_fin_vigencia_desde"
                                        type="date"
                                        size="sm"
                                        placeholder="Desde"
                                        @update:model-value="onFilterChange"
                                        class="w-full"
                                    />
                                    <BaseInput
                                        v-model="filters.fecha_fin_vigencia_hasta"
                                        type="date"
                                        size="sm"
                                        placeholder="Hasta"
                                        @update:model-value="onFilterChange"
                                        class="w-full"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </template>

                <template #body-nit="{ data }">
                    <div class="flex flex-col">
                        <span class="font-mono font-bold text-blue-600">{{ data.nit }}</span>
                        <span v-if="data.etiqueta" class="text-[9px] text-slate-400 font-semibold uppercase">
                            {{ data.etiqueta }}
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

                <template #body-razon_social="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight items-end w-full lg:items-center">
                        <span class="font-semibold text-slate-700 truncate max-w-full" :title="data.razon_social">
                            {{ data.razon_social }}
                        </span>
                        <span v-if="data.email_fiscal" class="text-slate-400 truncate max-w-full" :title="data.email_fiscal">
                            <i class="pi pi-envelope text-[9px] mr-1"></i>{{ data.email_fiscal }}
                        </span>
                    </div>
                </template>

                <template #body-ambiente="{ data }">
                    <Tag
                        :value="data.ambiente?.abreviatura || '—'"
                        :severity="data.ambiente?.abreviatura === 'PRODUCCION' ? 'success' : 'warn'"
                        class="text-[10px] font-bold uppercase px-2"
                    />
                </template>

                <template #body-modalidad="{ data }">
                    <span class="text-[10px] font-semibold text-slate-600">
                        {{ data.modalidad_facturacion?.abreviatura || '—' }}
                    </span>
                </template>

                <template #body-vigencia="{ data }">
                    <div class="flex flex-col text-[10px] leading-tight items-end w-full lg:items-center">
                        <span class="text-emerald-700 font-semibold">
                            <i class="pi pi-calendar-plus text-[9px] mr-1"></i>{{ data.fecha_inicio_vigencia || '—' }}
                        </span>
                        <span class="text-red-700 font-semibold">
                            <i class="pi pi-calendar-minus text-[9px] mr-1"></i>{{ data.fecha_fin_vigencia || '—' }}
                        </span>
                    </div>
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
                        @edit="edit(data)"
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
            class="custom-modal w-[95vw] sm:w-[90vw] md:w-[1100px]"
            :style="{ maxHeight: '95vh' }"
        >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow">
                        <i class="pi pi-id-card text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos fiscales y de dosificación</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                            <span>Identificación Fiscal</span>
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

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    NIT <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.nit"
                                    :maxlength="20"
                                    size="sm"
                                    placeholder="Ej: 1023456021"
                                    :disabled="estaProtegido('nit')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('nit') }"
                                    @blur="touched.nit = true"
                                />
                                <small v-if="estaProtegido('nit')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.nit) && $rules.nit()(formObj.nit) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    {{ $rules.nit()(formObj.nit) }}
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Etiqueta <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.etiqueta"
                                    :maxlength="30"
                                    size="sm"
                                    placeholder="Ej: CASA_MATRIZ"
                                    :disabled="estaProtegido('etiqueta')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('etiqueta') }"
                                    @blur="touched.etiqueta = true"
                                />
                                <small v-if="estaProtegido('etiqueta')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.etiqueta) && $rules.codigoMayusculas(1, 'Solo MAYÚSCULAS y guiones bajos')(formObj.etiqueta) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    {{ $rules.codigoMayusculas(1, 'Solo MAYÚSCULAS y guiones bajos')(formObj.etiqueta) }}
                                </small>
                            </div>

                            <div class="md:col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Razón Social <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.razon_social"
                                    :maxlength="500"
                                    size="sm"
                                    :disabled="estaProtegido('razon_social')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('razon_social') }"
                                    @blur="touched.razon_social = true"
                                />
                                <small v-if="estaProtegido('razon_social')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.razon_social) && $rules.longitudMinima(3)(formObj.razon_social) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    {{ $rules.longitudMinima(3)(formObj.razon_social) }}
                                </small>
                            </div>

                            <div class="md:col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Actividad Económica Principal <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.actividad_economica_principal"
                                    :maxlength="2000"
                                    size="sm"
                                    :disabled="estaProtegido('actividad_economica_principal')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('actividad_economica_principal') }"
                                    @blur="touched.actividad_economica_principal = true"
                                />
                                <small
                                    v-if="estaProtegido('actividad_economica_principal')"
                                    class="text-amber-500 font-semibold text-[10px]"
                                >
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.actividad_economica_principal) && $rules.longitudMinima(3)(formObj.actividad_economica_principal) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    {{ $rules.longitudMinima(3)(formObj.actividad_economica_principal) }}
                                </small>
                            </div>

                            <div class="md:col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Email Fiscal <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.email_fiscal"
                                    :maxlength="200"
                                    size="sm"
                                    placeholder="facturacion@empresa.com"
                                    :disabled="estaProtegido('email_fiscal')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('email_fiscal') }"
                                    @blur="touched.email_fiscal = true"
                                />
                                <small v-if="estaProtegido('email_fiscal')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.email_fiscal) && $rules.formatoCorreo()(formObj.email_fiscal) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    {{ $rules.formatoCorreo()(formObj.email_fiscal) }}
                                </small>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <span class="block text-xs font-black text-blue-700 uppercase tracking-wider mb-4">
                            Configuración Fiscal
                        </span>

                        <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Ambiente <span class="text-red-500">*</span>
                                </label>
                                <BaseSelect
                                    v-model="formObj.ambiente_id"
                                    :options="ambienteOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Seleccionar..."
                                    size="sm"
                                    @update:model-value="touched.ambiente_id = true"
                                />
                                <small
                                    v-if="(submitted || touched.ambiente_id) && $rules.seleccionObligatoria()(formObj.ambiente_id) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Modalidad Facturación <span class="text-red-500">*</span>
                                </label>
                                <BaseSelect
                                    v-model="formObj.modalidad_facturacion_id"
                                    :options="modalidadOptions"
                                    option-label="label"
                                    option-value="value"
                                    placeholder="Seleccionar..."
                                    size="sm"
                                    @update:model-value="touched.modalidad_facturacion_id = true"
                                />
                                <small
                                    v-if="(submitted || touched.modalidad_facturacion_id) && $rules.seleccionObligatoria()(formObj.modalidad_facturacion_id) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Inicio Vigencia <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.fecha_inicio_vigencia"
                                    type="date"
                                    size="sm"
                                    @blur="touched.fecha_inicio_vigencia = true"
                                />
                                <small
                                    v-if="(submitted || touched.fecha_inicio_vigencia) && $rules.obligatoria()(formObj.fecha_inicio_vigencia) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Fin Vigencia <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.fecha_fin_vigencia"
                                    type="date"
                                    size="sm"
                                    @blur="touched.fecha_fin_vigencia = true"
                                />
                                <small
                                    v-if="(submitted || touched.fecha_fin_vigencia) && $rules.obligatoria()(formObj.fecha_fin_vigencia) !== true"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div v-if="rangoFechasInvalido" class="md:col-span-12">
                                <div class="flex items-start gap-2 bg-amber-50 border border-amber-200 text-amber-800 p-2 rounded-lg">
                                    <i class="pi pi-exclamation-triangle mt-0.5 text-xs"></i>
                                    <span class="text-[10px] font-semibold">
                                        La fecha de inicio no puede ser mayor a la fecha de fin de vigencia.
                                    </span>
                                </div>
                            </div>

                            <div class="md:col-span-12 border-t border-dashed border-slate-200 my-2"></div>

                            <div class="md:col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Certificado Digital
                                </label>
                                <BaseInput
                                    v-model="formObj.certificado_digital"
                                    :maxlength="2000"
                                    size="sm"
                                    placeholder="Contenido o ruta del certificado"
                                />
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Password Certificado
                                </label>
                                <BaseInput
                                    v-model="formObj.certificado_password"
                                    type="password"
                                    :maxlength="500"
                                    size="sm"
                                    placeholder="••••••••"
                                />
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Token SIAT
                                </label>
                                <BaseInput
                                    v-model="formObj.token_siat"
                                    :maxlength="2000"
                                    size="sm"
                                    placeholder="Token de dosificación"
                                />
                            </div>
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
            title="Eliminar NIT Fiscal"
            :item-name="deleteItemName"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    import { ref, computed, shallowRef } from 'vue';
    import { Ambiente, AMBIENTE_METADATA, ModalidadFacturacion, MODALIDAD_FACTURACION_METADATA, ESTADO_ACTIVO } from '~/constants/estados.constant';

    useHead({ title: 'NITs Fiscales | SIRENA' });

    interface EmpresaOption {
        label: string;
        value: number;
    }

    const { $rules } = useNuxtApp() as any;
    const { $api } = useNuxtApp() as any;
    const authStore = useAuthStore();

    const empresaOptions = shallowRef<EmpresaOption[]>([]);
    const loadingEmpresas = ref(false);

    const ambienteOptions = Object.values(Ambiente)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => {
            const meta = AMBIENTE_METADATA[id as Ambiente];
            if (!meta) return null;
            return { label: meta.abreviatura, value: id };
        })
        .filter((o): o is { label: string; value: number } => o !== null);

    const modalidadOptions = Object.values(ModalidadFacturacion)
        .filter((v): v is number => typeof v === 'number')
        .map((id) => {
            const meta = MODALIDAD_FACTURACION_METADATA[id as ModalidadFacturacion];
            if (!meta) return null;
            return { label: meta.abreviatura, value: id };
        })
        .filter((o): o is { label: string; value: number } => o !== null);

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

    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos, estaProtegido,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem,
    } = useCrudTable<any>({
        tabla: 'empresas_nits',
        sortFieldDefault: 'empresa_nit_id',
        rowsDefault: 10,
        autoLoad: false,

        camposProtegidosPorDependencia: [],

        defaultFilters: {
            global: '',
            exactMatch: 0,
            empresa_id: empresaIdInicial,
            ambiente_id: null,
            modalidad_facturacion_id: null,
            fecha_inicio_vigencia_desde: null,
            fecha_inicio_vigencia_hasta: null,
            fecha_fin_vigencia_desde: null,
            fecha_fin_vigencia_hasta: null,
        },

        getExtraFilters: (f) => {
            const extra: Record<string, any> = {
                exactMatch: f.exactMatch ?? 0,
            };
            if (f.empresa_id) extra.empresa_id = Number(f.empresa_id);
            if (f.ambiente_id) extra.ambiente_id = f.ambiente_id;
            if (f.modalidad_facturacion_id) extra.modalidad_facturacion_id = f.modalidad_facturacion_id;
            if (f.fecha_inicio_vigencia_desde) extra.fecha_inicio_vigencia_desde = f.fecha_inicio_vigencia_desde;
            if (f.fecha_inicio_vigencia_hasta) extra.fecha_inicio_vigencia_hasta = f.fecha_inicio_vigencia_hasta;
            if (f.fecha_fin_vigencia_desde) extra.fecha_fin_vigencia_desde = f.fecha_fin_vigencia_desde;
            if (f.fecha_fin_vigencia_hasta) extra.fecha_fin_vigencia_hasta = f.fecha_fin_vigencia_hasta;
            return extra;
        },

        getPrimaryKey: (item) => item.empresa_nit_id,

        getCleanForm: () => ({
            empresa_nit_id: null,
            empresa_id: empresaIdInicial,
            ambiente_id: Ambiente.PILOTO_PRUEBAS,
            nit: '',
            razon_social: '',
            actividad_economica_principal: '',
            etiqueta: '',
            modalidad_facturacion_id: ModalidadFacturacion.NINGUNO,
            certificado_digital: '',
            certificado_password: '',
            token_siat: '',
            fecha_inicio_vigencia: new Date().toISOString().slice(0, 10),
            fecha_fin_vigencia: new Date(new Date().setFullYear(new Date().getFullYear() + 1))
                .toISOString()
                .slice(0, 10),
            email_fiscal: '',
        }),

        buildPayload: (form) => ({
            empresa_id: Number(form.empresa_id),
            ambiente_id: Number(form.ambiente_id),
            nit: form.nit?.trim(),
            razon_social: form.razon_social?.trim().toUpperCase(),
            actividad_economica_principal: form.actividad_economica_principal?.trim().toUpperCase(),
            etiqueta: form.etiqueta?.trim().toUpperCase(),
            modalidad_facturacion_id: Number(form.modalidad_facturacion_id),
            certificado_digital: form.certificado_digital?.trim() || undefined,
            certificado_password: form.certificado_password?.trim() || undefined,
            token_siat: form.token_siat?.trim() || undefined,
            fecha_inicio_vigencia: form.fecha_inicio_vigencia,
            fecha_fin_vigencia: form.fecha_fin_vigencia,
            email_fiscal: form.email_fiscal?.trim(),
        }),

        validate: (form, rules, notify) => {
            if (rules.obligatoria()(form.empresa_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar una empresa.');
                return false;
            }
            if (rules.nit()(form.nit) !== true) {
                notify('warn', 'NIT inválido', rules.nit()(form.nit));
                return false;
            }
            if (rules.longitudMinima(3)(form.razon_social) !== true) {
                notify('warn', 'Campos incompletos', 'La razón social es obligatoria (mín. 3 caracteres).');
                return false;
            }
            if (rules.longitudMinima(3)(form.actividad_economica_principal) !== true) {
                notify('warn', 'Campos incompletos', 'La actividad económica es obligatoria (mín. 3 caracteres).');
                return false;
            }
            if (rules.codigoMayusculas(1, 'Solo MAYÚSCULAS y guiones bajos')(form.etiqueta) !== true) {
                notify('warn', 'Etiqueta inválida', rules.codigoMayusculas(1, 'Solo MAYÚSCULAS y guiones bajos')(form.etiqueta));
                return false;
            }
            if (rules.seleccionObligatoria()(form.ambiente_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar un ambiente.');
                return false;
            }
            if (rules.seleccionObligatoria()(form.modalidad_facturacion_id) !== true) {
                notify('warn', 'Campos incompletos', 'Debe seleccionar una modalidad de facturación.');
                return false;
            }
            if (rules.obligatoria()(form.fecha_inicio_vigencia) !== true) {
                notify('warn', 'Campos incompletos', 'La fecha de inicio de vigencia es obligatoria.');
                return false;
            }
            if (rules.obligatoria()(form.fecha_fin_vigencia) !== true) {
                notify('warn', 'Campos incompletos', 'La fecha de fin de vigencia es obligatoria.');
                return false;
            }
            if (form.fecha_inicio_vigencia > form.fecha_fin_vigencia) {
                notify('warn', 'Regla de negocio', 'La fecha de inicio no puede ser mayor a la fecha de fin de vigencia.');
                return false;
            }
            if (rules.formatoCorreo()(form.email_fiscal) !== true) {
                notify('warn', 'Correo inválido', rules.formatoCorreo()(form.email_fiscal));
                return false;
            }
            return true;
        },
    });

    const rangoFechasInvalido = computed(() => {
        const ini = formObj.value.fecha_inicio_vigencia;
        const fin = formObj.value.fecha_fin_vigencia;
        return ini && fin && ini > fin;
    });

    const deleteItemName = computed(() => {
        const nit = formObj.value.nit ?? '';
        const razon = formObj.value.razon_social ?? '';
        return `NIT ${nit} — ${razon}`;
    });

    const onFilterChange = () => {
        lazyParams.value.first = 0;
        onSearch();
    };

    const onEmpresaChange = () => {
        lazyParams.value.first = 0;
        if (!filters.value.empresa_id) {
            items.value = [];
            totalRecords.value = 0;
            return;
        }
        onSearch();
    };

    const openNewConEmpresa = () => {
        openNew();
        if (filters.value.empresa_id) {
            formObj.value.empresa_id = Number(filters.value.empresa_id);
        }
    };

    const columns = [
        { field: 'nit', header: 'NIT', sortable: true, template: 'body-nit', bodyClass: '!text-center', class: 'w-40' },
        { field: 'empresa_nombre', header: 'EMPRESA', sortable: true, template: 'body-empresa', class: 'w-48' },
        { field: 'razon_social', header: 'RAZÓN SOCIAL', sortable: true, template: 'body-razon_social' },
        { field: 'ambiente_id', header: 'AMBIENTE', sortable: true, template: 'body-ambiente', bodyClass: '!text-center', class: 'w-32' },
        { field: 'modalidad_facturacion_id', header: 'MODALIDAD', sortable: true, template: 'body-modalidad', bodyClass: '!text-center', class: 'w-32' },
        { field: 'fecha_inicio_vigencia', header: 'VIGENCIA', sortable: true, template: 'body-vigencia', bodyClass: '!text-center', class: 'w-32' },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    onMounted(async () => {
        await cargarEmpresas();

        if (filters.value.empresa_id) {
            onSearch();
            return;
        }
    });
</script>

<!-- C:\sirena\sirena-frontend\app\components\base\BaseInput.vue -->
<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label v-if="label" class="text-[9px] font-bold text-slate-500 uppercase tracking-wider">{{ label }}</label>
        <div class="relative">
            <i v-if="icon" :class="icon" class="absolute left-3 top-1/2 -translate-y-1/2 z-10 pointer-events-none text-slate-400 text-xs"></i>
            <InputText
                v-bind="$attrs"
                :model-value="modelValue"
                :class="[
                    'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] px-3 py-2 transition-all',
                    'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
                    icon ? 'pl-9' : '',
                    size === 'sm' ? 'h-[38px] !text-xs !py-0' : 'h-10 text-sm'
                ]"
                :placeholder="placeholder"
                :disabled="disabled"
                @update:model-value="onInput"
            />
        </div>
        <small v-if="error" class="text-red-500 font-medium text-[10px]">{{ error }}</small>
    </div>
</template>

<script setup>
    const props = defineProps({
        label: { type: String, default: '' },
        placeholder: { type: String, default: '' },
        icon: { type: String, default: '' },
        size: { type: String, default: 'sm' },
        disabled: { type: Boolean, default: false },
        error: { type: String, default: '' },
        modelValue: { type: [String, Number], default: '' }
    });

    const emit = defineEmits(['update:modelValue']);

    const onInput = (value) => {
        emit('update:modelValue', value);
    };
</script>

<!-- C:\sirena\sirena-frontend\app\components\base\BaseSelect.vue -->
<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label
            v-if="label"
            class="text-[9px] font-bold text-slate-500 uppercase tracking-wider"
        >
            {{ label }}
        </label>

        <Select
            v-bind="$attrs"
            :class="[selectClasses, 'base-select']"
            :panelClass="panelClass"
            :placeholder="placeholder"
            :disabled="disabled"
            :options="options"
            :optionLabel="optionLabel"
            :optionValue="optionValue"
            :optionDisabled="optionDisabled"
            :filter="filter"
            :filterPlaceholder="filterPlaceholder"
            :showClear="showClear"
            :modelValue="modelValue"
            @update:modelValue="onUpdate"
        />

        <small v-if="error" class="text-red-500 font-medium text-[10px]">
            {{ error }}
        </small>
    </div>
</template>

<script setup lang="ts">
    // ⬇️ 1. Props con tipado fuerte
    const props = withDefaults(defineProps<{
        label?: string;
        placeholder?: string;
        size?: 'sm' | 'default';
        disabled?: boolean;
        error?: string;
        options: any[];
        optionLabel?: string;
        optionValue?: string;
        optionDisabled?: string;
        modelValue?: string | number | boolean | object | null | any[];
        panelClass?: string;
        filter?: boolean;
        filterPlaceholder?: string;
        showClear?: boolean;
    }>(), {
        label: '',
        placeholder: 'Seleccionar...',
        size: 'sm',
        disabled: false,
        error: '',
        optionLabel: 'label',
        optionValue: 'value',
        optionDisabled: undefined,
        modelValue: null,
        // ⬇️ 2. panelClass con valor por defecto pero PERSONALIZABLE desde fuera
        panelClass: 'min-w-[320px] max-w-[600px]',
        filter: false,
        filterPlaceholder: 'Buscar...',
        showClear: false,
    });

    const emit = defineEmits<{
        'update:modelValue': [value: any];
    }>();

    // ⬇️ 3. Computed para las clases del trigger (más limpio que en el template)
    const selectClasses = computed(() => [
        'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] transition-all',
        'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
        props.size === 'sm' ? 'min-h-[38px] text-xs' : 'min-h-[40px] text-sm',
    ]);

    const onUpdate = (value: any) => {
        emit('update:modelValue', value);
    };
</script>

/* C:\sirena\sirena-frontend\app\assets\css\main.postcss */
/* 1. DIRECTIVAS DE TAILWIND */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* 2. VARIABLES GLOBALES */
:root {
    --primary-color: #2563eb;
    --primary-dark: #113f67;
    --primary-dark-hover: #0d3152;
    --secondary-color: #ea580c;
    --secondary-hover: #c2410c;
    --danger-color: #c53030;
    --danger-hover: #9b2c2c;
    --border-color: #cbd5e1;
    --text-main: #1e293b;
    --text-muted: #64748b;
    --bg-disabled: #f1f5f9;
    --white: #ffffff;
    --radius-std: 0.5rem;
}

body {
    @apply antialiased bg-white text-slate-800;
    color: var(--text-main);
}

::placeholder {
    color: var(--text-muted);
    opacity: 0.8;
}

/* 3. UTILIDADES DE LAYOUT GLOBALES (SOLO ESTRUCTURA) */
.page-container {
    @apply pt-0 md:pt-2 px-4 md:px-6 pb-6;
}

.page-header {
    @apply flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6;
}

.custom-table {
    @apply bg-white rounded-2xl shadow-sm border border-slate-300 overflow-hidden;
}

.custom-header-filters {
    @apply flex flex-col gap-4 p-4 bg-slate-50/50 border-b border-slate-200;
}

.filter-grid {
    @apply grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3;
}

.filter-field {
    @apply flex flex-col gap-0.5;
}

/* 4. ESTILOS GLOBALES PARA TOAST Y OVERRIDES */
.toast-center {
    @apply fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[10000];
}

@media (max-width: 768px) {
    .p-dialog {
        @apply w-[92vw] !important;
    }
}

/* 5. ESTILOS GLOBALES PARA TABLAS */
.p-datatable .p-datatable-thead > tr > th {
    background-color: var(--primary-dark) !important;
    color: white !important;
    font-size: 10px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.05em !important;
    font-weight: 700 !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
    border-color: var(--primary-dark) !important;

    /* CENTRADO DE CABEZA */
    text-align: center !important;
    vertical-align: middle !important;
}

.p-datatable .p-datatable-column-header-content {
    justify-content: center !important;
}

.p-datatable .p-datatable-tbody > tr > td {
    font-size: 11px !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
}

.p-datatable .p-datatable-tbody > tr > td .p-button.p-button-sm {
    padding: 0.25rem 0.5rem !important;
    min-height: 28px !important;
    height: 28px !important;
    line-height: 1 !important;
}

.p-datatable .p-datatable-tbody > tr:hover {
    background-color: rgba(59, 130, 246, 0.08) !important;
}

.p-datatable .p-paginator {
    background-color: white !important;
    border-top: 1px solid #e2e8f0 !important;
    font-size: 11px !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
}

.p-paginator .p-paginator-element {
    font-size: 11px !important;
    min-width: 2rem !important;
    height: 2rem !important;
}

/* Esquinas redondeadas en cabecera */
.p-datatable .p-datatable-thead > tr:first-child > th:first-child {
    border-top-left-radius: 0.5rem !important;
}

.p-datatable .p-datatable-thead > tr:first-child > th:last-child {
    border-top-right-radius: 0.5rem !important;
}

/* 6. ESTILOS GLOBALES PARA DROPDOWNS Y SELECTS */

/* Control del panel desplegable - ancho dinámico */
.p-select-panel {
    min-width: 100% !important;    /* Mínimo el ancho del input */
    max-width: 600px !important;   /* Límite para no estirarse demasiado */
    width: auto !important;        /* Ajuste al contenido */
}

/* Control de las opciones individuales - wrap de texto */
.p-select-option,
.p-select-item {
    white-space: normal !important;
    word-break: break-word !important;
    overflow: visible !important;
    text-overflow: clip !important;
    padding: 0.5rem 0.75rem !important;
    line-height: 1.3 !important;
}

/* Asegurar que el panel se posicione correctamente en móviles */
@media (max-width: 640px) {
    .p-select-panel {
        min-width: 280px !important;
        max-width: 95vw !important;
    }
}

/* Ajuste fino para el scroll si hay muchas opciones */
.p-select-items-wrapper {
    max-height: 300px !important;
}

/* Tamaño de fuente consistente para todos los selects */
.p-select {
    font-size: 0.875rem !important; /* 14px - tamaño estándar */
}

.p-select-sm {
    font-size: 0.75rem !important; /* 12px - tamaño pequeño */
}

/* Asegurar que el tamaño del label del select sea consistente */
.p-select-label {
    font-size: inherit !important;
}

/* Estilo de error consistente */
.p-select.p-invalid {
    border-color: var(--danger-color) !important;
}

.p-select.p-invalid .p-select-label {
    color: var(--danger-color) !important;
}

/* 7. ESTILOS GLOBALES PARA MODALES (DIALOG) */
.p-dialog .p-dialog-content {
    overflow: auto !important;
    max-height: 80vh !important;
    padding: 0 !important;
}

@media (max-width: 640px) {
    .p-dialog {
        margin: 0.5rem !important;
        max-height: 98vh !important;
        width: 95vw !important;
    }

    .p-dialog .p-dialog-content {
        max-height: 75vh !important;
        padding: 0.5rem !important;
    }

    .p-dialog .p-dialog-header {
        padding: 0.75rem !important;
    }

    .p-dialog .p-dialog-footer {
        padding: 0.75rem !important;
        flex-wrap: wrap;
        gap: 0.5rem;
    }
}

@media (min-width: 641px) and (max-width: 1024px) {
    .p-dialog {
        width: 92vw !important;
        max-height: 90vh !important;
    }
}

/* 8. BASE TABLE — Layout, scroll y cabecera fija. Solo aplica a <BaseTable> (marcado con .base-table) */
/* Contenedor principal: columna flex con altura completa */
.base-table {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
}

/* El DataTable ocupa todo el alto del padre */
.base-table > .p-datatable {
    display: flex;
    flex-direction: column;
    flex: 1 1 auto;
    min-height: 0;
}

/* El header (CrudTableFilter) se queda arriba */
.base-table > .p-datatable > .p-datatable-header {
    flex: 0 0 auto;
}

/* El wrapper de filas ocupa el espacio disponible y hace scroll */
.base-table > .p-datatable > .p-datatable-wrapper {
    flex: 1 1 auto;
    min-height: 0;
    overflow-y: auto !important;
    overflow-x: auto !important;
}

/* El paginador se queda abajo, siempre visible */
.base-table > .p-datatable > .p-paginator {
    flex: 0 0 auto;
    background-color: white !important;
    border-top: 1px solid #e2e8f0 !important;
    font-size: 11px !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
}

/* Cabecera azul */
.base-table .p-datatable .p-datatable-thead > tr > th {
    background-color: var(--primary-dark) !important;
    color: white !important;
    font-size: 10px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.05em !important;
    font-weight: 700 !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
    border-color: var(--primary-dark) !important;

    /* Sticky header */
    position: sticky !important;
    top: 0 !important;
    z-index: 2 !important;
}

/* Celdas del body */
.base-table .p-datatable .p-datatable-tbody > tr > td {
    font-size: 11px !important;
    padding-top: 0.5rem !important;
    padding-bottom: 0.5rem !important;
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
}

/* Hover de fila */
.base-table .p-datatable .p-datatable-tbody > tr:hover {
    background-color: rgba(59, 130, 246, 0.08) !important;
}

/* Elementos del paginador */
.base-table .p-paginator .p-paginator-element {
    font-size: 11px !important;
    min-width: 2rem !important;
    height: 2rem !important;
}

/* Esquinas redondeadas en cabecera */
.base-table .p-datatable .p-datatable-thead > tr:first-child > th:first-child {
    border-top-left-radius: 0.5rem !important;
}

.base-table .p-datatable .p-datatable-thead > tr:first-child > th:last-child {
    border-top-right-radius: 0.5rem !important;
}

/* Layout flex controlado en móvil para que las tarjetas tengan scroll interno y el paginador permanezca visible */
@media screen and (max-width: 960px) {
    .base-table,
    .base-table.h-full {
        display: flex !important;
        flex-direction: column !important;
        height: 100% !important;
        min-height: 0 !important;
        max-height: none !important;
    }
}

/* 9. EFECTO RIPPLE GLOBAL PARA BOTONES */
.ripple-btn {
    position: relative;
    overflow: hidden;
    -webkit-tap-highlight-color: transparent;
    isolation: isolate; /* crea un nuevo contexto de apilamiento */
}

.ripple-btn::after {
    content: "";
    position: absolute;
    top: 50%;
    left: 50%;
    width: 8px;
    height: 8px;
    margin-top: -4px;
    margin-left: -4px;
    border-radius: 50%;
    background: rgba(100, 116, 139, 0.55);
    transform: scale(0);
    opacity: 0;
    pointer-events: none;
    z-index: -1;
}

/* Animación al hacer :active */
.ripple-btn:active::after {
    animation: ripple-expand 0.6s ease-out;
}

@keyframes ripple-expand {
    0% {
        transform: scale(0);
        opacity: 0.7;
    }
    100% {
        transform: scale(6);
        opacity: 0;
    }
}

/* 10. CABECERA DE TABLA FIJA (STICKY HEADER) */
/* Fuerza que la cabecera se quede pegada arriba al hacer scroll vertical */
.p-datatable-scrollable .p-datatable-thead > tr > th {
    position: sticky !important;
    top: 0 !important;
    z-index: 2 !important;
    background-color: var(--primary-dark) !important;
    color: white !important;
}

/* Evita que el fondo se transparente al hacer scroll */
.p-datatable-scrollable .p-datatable-thead {
    background-color: var(--primary-dark) !important;
}

/* El contenedor de la tabla con scroll interno */
.p-datatable-scrollable > .p-datatable-wrapper {
    overflow-y: auto !important;
    overflow-x: auto !important;
}

/* Opcional: barra de scroll más delgada y bonita */
.p-datatable-scrollable > .p-datatable-wrapper::-webkit-scrollbar {
    width: 8px;
    height: 8px;
}
.p-datatable-scrollable > .p-datatable-wrapper::-webkit-scrollbar-track {
    background: #f1f5f9;
}
.p-datatable-scrollable > .p-datatable-wrapper::-webkit-scrollbar-thumb {
    background: #94a3b8;
    border-radius: 4px;
}
.p-datatable-scrollable > .p-datatable-wrapper::-webkit-scrollbar-thumb:hover {
    background: #64748b;
}

/* 11. ETIQUETA DEL SELECT — wrap de texto Solo aplica a <BaseSelect> (marcado con .base-select) */
.base-select .p-select-label {
    white-space: normal !important;
    overflow: visible !important;
    text-overflow: clip !important;
    word-break: break-word !important;
    line-height: 1.3 !important;
    padding-right: 2rem !important;
    min-height: 1.5rem !important;
}


COMO PUEDO igualar el tamaño de las letras entre los select o combos los imputs
EL tamaño de imputs esta bien pero de select es grande ver foto 
