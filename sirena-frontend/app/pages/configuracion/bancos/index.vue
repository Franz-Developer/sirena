<!-- C:\sirena\sirena-frontend\app\pages\configuracion\bancos\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <!-- ENCABEZADO (usando CrudPageHeader) -->
        <CrudPageHeader
            icon="pi pi-building-columns"
            title="Bancos"
            subtitle="Catálogo de entidades financieras"
            :show-action="permisos.crear"
            action-label="NUEVO BANCO"
            action-icon="pi pi-plus"
            @action="openNew"
        />

        <!-- TABLA -->
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
                    <CrudTableFilter
                        autofocus
                        v-model:search-value="filters.global"
                        v-model:exact-match="filters.exactMatch"
                        search-placeholder="Buscar banco..."
                        @search="onSearch"
                    />
                </template>

                <template #body-codigo="{ data }">
                    <span class="font-mono font-bold text-blue-600">{{ data.codigo_asfi }}</span>
                </template>

                <template #body-abreviatura="{ data }">
                    <span class="font-semibold text-slate-700">{{ data.abreviatura }}</span>
                </template>

                <template #body-banco="{ data }">
                    <span class="font-bold text-slate-800">{{ data.banco }}</span>
                </template>

                <template #body-descripcion="{ data }">
                    <span class="text-slate-500 text-xs">{{ data.descripcion || 'Sin descripción' }}</span>
                </template>

                <template #body-estado="{ data }">
                    <CrudEstadoBadge
                        :estado="data.estado_registro"
                        :estado-id="data.estado_id"
                    />
                </template>

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
            :modal="true"
            :closable="!loading"
            class="custom-modal w-[95vw] sm:w-[90vw] md:w-[720px]"
            :style="{ maxHeight: '90vh' }"
            @show="focusFirstInput"
        >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow">
                        <i class="pi pi-building-columns text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos de la entidad bancaria</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                        <span>Información del Banco</span>
                        <span class="text-slate-600 normal-case font-bold text-[10px]">
                            Campos obligatorios <span class="text-red-500">*</span>
                        </span>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                        <div class="md:col-span-3">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Código ASFI <span class="text-red-500">*</span></label>
                            <BaseInput
                                ref="codigoAsfiRef"
                                v-model="formObj.codigo_asfi"
                                :maxlength="2"
                                size="sm"
                                :disabled="estaProtegido('codigo_asfi')"
                                :class="{
                                    'p-invalid': (submitted || touched.codigo_asfi) && $rules.obligatoria()(formObj.codigo_asfi) !== true,
                                    'opacity-60 cursor-not-allowed': estaProtegido('codigo_asfi')
                                }"
                                @blur="touched.codigo_asfi = true"
                            />
                            <small v-if="estaProtegido('codigo_asfi')" class="text-amber-500 font-semibold text-[10px]">
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small v-else-if="(submitted || touched.codigo_asfi) && $rules.obligatoria()(formObj.codigo_asfi) !== true" class="text-red-500 font-semibold text-[10px]">
                                Requerido
                            </small>
                        </div>
                        <div class="md:col-span-3">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Abreviatura <span class="text-red-500">*</span></label>
                            <BaseInput
                                v-model="formObj.abreviatura"
                                :maxlength="20"
                                size="sm"
                                placeholder=""
                                :disabled="estaProtegido('abreviatura')"
                                @blur="touched.abreviatura = true"
                                :class="{
                                    'p-invalid': (submitted || touched.abreviatura) && $rules.obligatoria()(formObj.abreviatura) !== true,
                                    'opacity-60 cursor-not-allowed': estaProtegido('abreviatura')
                                }"
                            />
                            <small
                                v-if="estaProtegido('abreviatura')"
                                class="text-amber-500 font-semibold text-[10px]"
                            >
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.abreviatura) && $rules.obligatoria()(formObj.abreviatura) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>
                        <div class="md:col-span-6">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Nombre del Banco <span class="text-red-500">*</span></label>
                            <BaseInput
                                v-model="formObj.banco"
                                :maxlength="60"
                                size="sm"
                                placeholder=""
                                :disabled="estaProtegido('banco')"
                                @blur="touched.banco = true"
                                :class="{
                                    'p-invalid': (submitted || touched.banco) && $rules.obligatoria()(formObj.banco) !== true,
                                    'opacity-60 cursor-not-allowed': estaProtegido('banco')
                                }"
                            />
                            <small
                                v-if="estaProtegido('banco')"
                                class="text-amber-500 font-semibold text-[10px]"
                            >
                                <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                            </small>
                            <small
                                v-else-if="(submitted || touched.banco) && $rules.obligatoria()(formObj.banco) !== true"
                                class="text-red-500 font-semibold text-[10px]"
                            >
                                Requerido
                            </small>
                        </div>
                        <div class="md:col-span-12">
                            <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Descripción</label>
                            <BaseInput v-model="formObj.descripcion" :maxlength="255" size="sm" placeholder="Observaciones o notas adicionales" />
                        </div>
                    </div>
                </div>
            </div>

            <template #footer>
                <div class="flex justify-end gap-3 pb-2 pt-4">
                    <BaseButton label="Cancelar" icon="pi pi-times" :loading="loading" variant="danger" @click="hideDialog" />
                    <BaseButton :label="isUpdate ? 'Actualizar' : 'Guardar Registro'" icon="pi pi-save" :loading="loading" variant="primary" @click="save" />
                </div>
            </template>
        </Dialog>

        <!-- DIALOG ELIMINAR (usando CrudDeleteDialog) -->
        <CrudDeleteDialog v-model:visible="deleteDialog" title="Eliminar Banco" :item-name="formObj.banco" @confirm="deleteItem" />
    </div>
</template>

<script setup lang="ts">
    import { ref, nextTick } from 'vue';

    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos,
        onPage, onSort, onSearch,
        openNew, edit, hideDialog, save,
        toggleEstado, confirmDelete, deleteItem, estaProtegido,
    } = useCrudTable<any>({
        tabla: 'bancos',
        sortFieldDefault: 'banco_id',
        rowsDefault: 10,
        camposProtegidosPorDependencia: ['banco', 'codigo_asfi', 'abreviatura'],

        // Filtros iniciales.
        defaultFilters: {
            global: '',
            exactMatch: 0,
        },

        // Traduce al backend.
        getExtraFilters: (f) => ({
            exactMatch: f.exactMatch ?? 0,
        }),

        getPrimaryKey: (item) => item.banco_id,

        getCleanForm: () => ({
            banco_id: null,
            banco: '',
            codigo_asfi: '',
            abreviatura: '',
            descripcion: '',
        }),

        buildPayload: (form) => ({
            banco: form.banco?.trim().toUpperCase(),
            codigo_asfi: form.codigo_asfi?.trim(),
            abreviatura: form.abreviatura?.trim().toUpperCase(),
            descripcion: form.descripcion?.trim() || null,
        }),

        validate: (form, rules, notify) => {
            if (rules.obligatoria()(form.codigo_asfi) !== true) {
                notify('warn', 'Campos incompletos', 'El código ASFI es obligatorio');
                return false;
            }
            if (!/^\d{2}$/.test(form.codigo_asfi?.trim() ?? '')) {
                notify('warn', 'Formato inválido', 'El código ASFI debe ser 2 dígitos.');
                return false;
            }
            if (rules.obligatoria()(form.abreviatura) !== true) {
                notify('warn', 'Campos incompletos', 'La abreviatura es obligatoria');
                return false;
            }
            if (rules.obligatoria()(form.banco) !== true) {
                notify('warn', 'Campos incompletos', 'El nombre del banco es obligatorio');
                return false;
            }
            return true;
        },
    });

    const codigoAsfiRef = ref<any>(null);
    const focusFirstInput = async () => {
        await nextTick();
        setTimeout(() => {
            const input = codigoAsfiRef.value?.$el?.querySelector('input') as HTMLInputElement | null;
            input?.focus();
            input?.select();
        }, 350);
    };

    const columns = [
        { field: 'codigo_asfi', header: 'CÓDIGO', sortable: true, template: 'body-codigo', bodyClass: '!text-center', class: 'w-20' },
        { field: 'abreviatura', header: 'ABREV.', sortable: true, template: 'body-abreviatura', class: 'w-24' },
        { field: 'banco', header: 'BANCO', sortable: true, template: 'body-banco' },
        { field: 'descripcion', header: 'DESCRIPCIÓN', sortable: false, template: 'body-descripcion' },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    useHead({ title: 'Bancos | SIRENA' });
</script>
