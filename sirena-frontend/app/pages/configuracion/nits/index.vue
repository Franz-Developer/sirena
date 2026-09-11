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
    <div class="px-4 py-3 bg-white border-b border-slate-200">
        <!-- Primera fila: Empresa, Buscar, Coincidencia -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
            <div class="md:col-span-1 w-full">
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

            <div class="md:col-span-1 w-full">
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

            <div class="md:col-span-1 w-full">
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
                <div class="flex gap-2 w-full">
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
                <div class="flex gap-2 w-full">
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
                <!--<template #header>
                    <div class="px-4 py-3 bg-white border-b border-slate-200">
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div class="md:col-span-1">
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
                                />
                            </div>

                            <div class="md:col-span-1">
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Buscar
                                </label>
                                <BaseSearch
                                    v-model="filters.global"
                                    placeholder="NIT, razón social, etiqueta..."
                                    @search="onSearch"
                                />
                            </div>

                            <div class="md:col-span-1 flex items-end gap-2">
                                <div class="flex-1">
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
                                    />
                                </div>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4">
                            <div>
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
                                />
                            </div>

                            <div>
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
                                />
                            </div>

                            <div>
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Inicio Vigencia
                                </label>
                                <div class="flex gap-2">
                                    <BaseInput
                                        v-model="filters.fecha_inicio_vigencia_desde"
                                        type="date"
                                        size="sm"
                                        placeholder="Desde"
                                        @update:model-value="onFilterChange"
                                    />
                                    <BaseInput
                                        v-model="filters.fecha_inicio_vigencia_hasta"
                                        type="date"
                                        size="sm"
                                        placeholder="Hasta"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>
                            </div>

                            <div>
                                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                                    Fin Vigencia
                                </label>
                                <div class="flex gap-2">
                                    <BaseInput
                                        v-model="filters.fecha_fin_vigencia_desde"
                                        type="date"
                                        size="sm"
                                        placeholder="Desde"
                                        @update:model-value="onFilterChange"
                                    />
                                    <BaseInput
                                        v-model="filters.fecha_fin_vigencia_hasta"
                                        type="date"
                                        size="sm"
                                        placeholder="Hasta"
                                        @update:model-value="onFilterChange"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </template>-->

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
                    <div class="flex flex-col text-[10px] leading-tight max-w-[260px]">
                        <span class="font-semibold text-slate-700 truncate" :title="data.razon_social">
                            {{ data.razon_social }}
                        </span>
                        <span v-if="data.email_fiscal" class="text-slate-400 truncate" :title="data.email_fiscal">
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
                    <div class="flex flex-col text-[10px] leading-tight items-center">
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
            :style="{ width: '1100px', maxHeight: '95vh' }"
            :modal="true"
            :closable="!loading"
            class="custom-modal"
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
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-4">
                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                            <span>Identificación Fiscal</span>
                            <span class="text-slate-600 normal-case font-bold text-[10px]">
                                Campos obligatorios <span class="text-red-500">*</span>
                            </span>
                        </div>

                        <div class="grid grid-cols-12 gap-x-4 gap-y-3">
                            <div class="col-span-12">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

                            <div class="col-span-12">
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

                            <div class="col-span-12">
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

                            <div class="col-span-12">
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

                        <div class="grid grid-cols-12 gap-x-4 gap-y-3">
                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

                            <div v-if="rangoFechasInvalido" class="col-span-12">
                                <div class="flex items-start gap-2 bg-amber-50 border border-amber-200 text-amber-800 p-2 rounded-lg">
                                    <i class="pi pi-exclamation-triangle mt-0.5 text-xs"></i>
                                    <span class="text-[10px] font-semibold">
                                        La fecha de inicio no puede ser mayor a la fecha de fin de vigencia.
                                    </span>
                                </div>
                            </div>

                            <div class="col-span-12 border-t border-dashed border-slate-200 my-2"></div>

                            <div class="col-span-12">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

        /*if (empresaOptions.value.length === 1) {
            filters.value.empresa_id = empresaOptions.value[0].value;
            onSearch();
        }*/
    });
</script>
