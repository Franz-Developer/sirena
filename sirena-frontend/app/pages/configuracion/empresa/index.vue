<!-- C:\sirena\sirena-frontend\app\pages\configuracion\empresa\index.vue -->
<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <CrudPageHeader
            icon="pi pi-building"
            title="Datos de la Empresa"
            subtitle="Gestión de datos fiscales y organizacionales"
            :show-action="permisos.crear"
            action-label="NUEVA EMPRESA"
            action-icon="pi pi-plus"
            @action="openNew"
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
                    <CrudTableFilter
                        v-model:search-value="filters.global"
                        v-model:exact-match="filters.exactMatch"
                        search-placeholder="Buscar empresa, código, NIT..."
                        @search="onSearch"
                    />
                </template>

                <template #body-codigo="{ data }">
                    <span class="font-mono font-bold text-blue-600">{{ data.codigo }}</span>
                </template>

                <template #body-empresa="{ data }">
                    <div class="flex flex-col">
                        <span class="font-bold text-slate-700">{{ data.empresa }}</span>
                        <span v-if="data.eslogan" class="text-[9px] text-slate-400 italic">{{ data.eslogan }}</span>
                    </div>
                </template>

                <template #body-contacto="{ data }">
                    <div class="flex flex-col items-end text-[10px] leading-tight min-w-0">
                        <span v-if="data.telefono" class="text-slate-600">
                            <i class="pi pi-phone text-[9px] mr-1"></i>{{ data.telefono }}
                        </span>
                        <span v-if="data.email" class="text-slate-500 truncate max-w-full">
                            <i class="pi pi-envelope text-[9px] mr-1"></i>{{ data.email }}
                        </span>
                        <span v-if="!data.telefono && !data.email" class="text-slate-300">—</span>
                    </div>
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
                        <i class="pi pi-building text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Datos institucionales y fiscales</p>
                    </div>
                </div>
            </template>

            <div class="p-6">
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-4">
                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                            <span>Información Fiscal e Identidad</span>
                            <span class="text-slate-600 normal-case font-bold text-[10px]">
                                Campos obligatorios <span class="text-red-500">*</span>
                            </span>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-12 gap-x-4 gap-y-3">
                            <div class="md:col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Razón Social <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.empresa"
                                    :maxlength="200"
                                    size="sm"
                                    :disabled="estaProtegido('empresa')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('empresa') }"
                                    @blur="touched.empresa = true"
                                />
                                <small v-if="estaProtegido('empresa')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.empresa) && !formObj.empresa"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    La razón social es obligatoria
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Código Interno <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.codigo"
                                    :maxlength="30"
                                    size="sm"
                                    :disabled="estaProtegido('codigo')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('codigo') }"
                                    @blur="touched.codigo = true"
                                />
                                <small v-if="estaProtegido('codigo')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.codigo) && !formObj.codigo"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">
                                    Matrícula Comercio <span class="text-red-500">*</span>
                                </label>
                                <BaseInput
                                    v-model="formObj.matricula_comercio"
                                    :maxlength="50"
                                    size="sm"
                                    :disabled="estaProtegido('matricula_comercio')"
                                    :class="{ 'opacity-60 cursor-not-allowed': estaProtegido('matricula_comercio') }"
                                    @blur="touched.matricula_comercio = true"
                                />
                                <small v-if="estaProtegido('matricula_comercio')" class="text-amber-500 font-semibold text-[10px]">
                                    <i class="pi pi-lock mr-1"></i>Bloqueado por dependencias
                                </small>
                                <small
                                    v-else-if="(submitted || touched.matricula_comercio) && !formObj.matricula_comercio"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Requerido
                                </small>
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Representante Legal</label>
                                <BaseInput v-model="formObj.representante" :maxlength="100" size="sm" />
                            </div>

                            <div class="md:col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Eslogan</label>
                                <BaseInput v-model="formObj.eslogan" :maxlength="150" size="sm" />
                            </div>
                        </div>
                    </div>
                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <span class="block text-xs font-black text-blue-700 uppercase tracking-wider mb-4">Contacto y Ubicación</span>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Teléfono</label>
                                <BaseInput v-model="formObj.telefono" :maxlength="100" size="sm" />
                            </div>

                            <div>
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Correo</label>
                                <BaseInput v-model="formObj.email" :maxlength="100" size="sm" @blur="touched.email = true" />
                                <small
                                    v-if="(submitted || touched.email) && formObj.email && !esEmailValido(formObj.email)"
                                    class="text-red-500 font-semibold text-[10px]"
                                >
                                    Formato de correo inválido
                                </small>
                            </div>

                            <div class="md:col-span-2">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Dirección Exacta</label>
                                <BaseInput v-model="formObj.direccion" :maxlength="500" size="sm" />
                            </div>

                            <div class="md:col-span-2">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Lugar / Ciudad</label>
                                <BaseInput v-model="formObj.lugar" :maxlength="60" size="sm" placeholder="Ej: La Paz - Bolivia" />
                            </div>

                            <div class="md:col-span-2">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Descripción</label>
                                <BaseInput v-model="formObj.descripcion" :maxlength="500" size="sm" />
                            </div>
                        </div>
                    </div>
                </div>

                <div class="mt-4 bg-white p-6 rounded-2xl border border-slate-300 shadow-sm">
                    <span class="block text-xs font-black text-blue-700 uppercase tracking-wider mb-5">Logo Institucional</span>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
                        <div class="flex items-center justify-center">
                            <div class="w-full h-48 rounded-2xl border-2 border-dashed border-slate-300 bg-slate-50 flex items-center justify-center overflow-hidden transition-all hover:border-blue-400 hover:bg-blue-50/30">
                                <img v-if="logoPreview" :src="logoPreview" class="w-full h-full object-contain p-4" />
                                <div v-else class="flex flex-col items-center gap-3 text-slate-400">
                                    <i class="pi pi-image text-5xl"></i>
                                    <span class="text-[11px] font-bold uppercase tracking-wider">Sin logo</span>
                                    <span class="text-[10px]">Click en "Cargar Logo"</span>
                                </div>
                            </div>
                        </div>

                        <div class="flex flex-col gap-4">
                            <div class="bg-slate-50 rounded-xl p-4 border border-slate-200">
                                <span class="block text-[10px] font-black text-slate-600 uppercase tracking-wider mb-2">
                                    Requisitos del logo
                                </span>
                                <ul class="space-y-1.5 text-[11px] text-slate-600">
                                    <li class="flex items-center gap-2">
                                        <i class="pi pi-check-circle text-emerald-500 text-xs"></i>
                                        Peso máximo: <b>{{ logoConfig?.maxSizeKB ?? '—' }} KB</b>
                                    </li>
                                    <li class="flex items-center gap-2">
                                        <i class="pi pi-check-circle text-emerald-500 text-xs"></i>
                                        Formatos: <b>{{ logoConfig?.formats ?? '—' }}</b>
                                    </li>
                                    <li class="flex items-center gap-2">
                                        <i class="pi pi-check-circle text-emerald-500 text-xs"></i>
                                        Dimensiones máximas: <b>{{ logoConfig?.maxWidth ?? '—' }} × {{ logoConfig?.maxHeight ?? '—' }} px</b>
                                    </li>
                                </ul>
                            </div>

                            <input
                                ref="logoInput"
                                type="file"
                                class="hidden"
                                accept="image/jpeg,image/jpg,image/png"
                                @change="onLogoChange"
                            />

                            <div class="flex gap-2 justify-center">
                                <BaseButton
                                    v-if="logoPreview"
                                    label="Quitar"
                                    icon="pi pi-trash"
                                    variant="ghost-red"
                                    size="sm"
                                    @click="quitarLogo"
                                />
                                <BaseButton
                                    :label="logoPreview ? 'Cambiar Logo' : 'Cargar Logo'"
                                    icon="pi pi-upload"
                                    variant="ghost-sky"
                                    size="sm"
                                    @click="abrirSelectorLogo"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <template #footer>
                <div class="flex justify-end gap-3 pb-2 pt-4">
                    <BaseButton label="Cancelar" icon="pi pi-times" :loading="loading" variant="danger" @click="hideDialog" />
                    <BaseButton
                        :label="isUpdate ? 'Actualizar' : 'Guardar Registro'"
                        icon="pi pi-save"
                        :loading="loading"
                        variant="primary"
                        @click="saveEmpresa"
                    />
                </div>
            </template>
        </Dialog>

        <CrudDeleteDialog
            v-model:visible="deleteDialog"
            title="Eliminar Empresa"
            :item-name="formObj.empresa || 'esta empresa'"
            @confirm="deleteItem"
        />
    </div>
</template>

<script setup lang="ts">
    useHead({ title: 'Empresas | SIRENA' });

    const { validate: validateImage, getConfigDisplay } = useImageValidator()

    const {
        items, loading, totalRecords, filters, lazyParams,
        dialog, deleteDialog, formObj, submitted, touched,
        isUpdate, formTitle, permisos, estaProtegido,
        onPage, onSort, onSearch,
        openNew: openNewBase, edit: editBase, hideDialog,
        toggleEstado, confirmDelete, deleteItem,
        resolvePK,
    } = useCrudTable<any>({
        tabla: 'empresas',
        sortFieldDefault: 'empresa_id',
        rowsDefault: 10,

        camposProtegidosPorDependencia: ['empresa', 'codigo', 'matricula_comercio'],

        defaultFilters: {
            global: '',
            exactMatch: 0,
        },

        getExtraFilters: (f) => ({
            exactMatch: f.exactMatch ?? 0,
        }),

        getPrimaryKey: (item) => item.empresa_id,

        getCleanForm: () => ({
            empresa_id: null,
            empresa: '',
            codigo: '',
            logo: '',
            eslogan: '',
            descripcion: '',
            lugar: '',
            representante: '',
            direccion: '',
            telefono: '',
            email: '',
            matricula_comercio: '',
        }),

        buildPayload: (form) => form,

        validate: () => true,
    });

    const { notify } = useNotify();
    const { $api } = useNuxtApp() as any;

    const logoInput = ref<HTMLInputElement | null>(null);
    const logoFile = ref<File | null>(null);
    const logoPreview = ref<string | null>(null);
    const logoOriginal = ref<string | null>(null);

    const esEmailValido = (v: string): boolean => {
        if (!v) return true;
        return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(v.trim());
    };

    const saveWithLogo = async (
        payload: Record<string, any>,
        file: File | null,
        id?: number | string | null,
    ): Promise<any> => {
        const formData = new FormData();

        Object.entries(payload).forEach(([key, value]) => {
            if (value !== null && value !== undefined && value !== '') {
                formData.append(key, value as any);
            }
        });

        if (file) {
            formData.append('logo', file);
        }

        const url = id ? `/empresas/${id}` : '/empresas';
        const method = id ? 'PATCH' : 'POST';

        return $api(url, { method, body: formData });
    };

    const onLogoChange = async (event: Event) => {
        const target = event.target as HTMLInputElement;
        const file = target.files?.[0];
        if (!file) return;

        const result = await validateImage(file, 'logo_config');

        if (!result.valid) {
            notify('warn', 'Imagen no válida', result.error || 'Archivo no permitido');
            target.value = '';
            return;
        }

        logoFile.value = file;
        const reader = new FileReader();
        reader.onload = () => {
            logoPreview.value = reader.result as string;
        };
        reader.readAsDataURL(file);
    };

    const quitarLogo = () => {
        logoFile.value = null;
        logoPreview.value = null;
        formObj.value.logo = '';
        if (logoInput.value) logoInput.value.value = '';
    };

    const abrirSelectorLogo = (): void => {
        logoInput.value?.click();
    };

    const openNew = () => {
        openNewBase();
        logoFile.value = null;
        logoPreview.value = null;
        logoOriginal.value = null;
    };

    const edit = async (data: any) => {
        await editBase(data);
        logoOriginal.value = formObj.value.logo || null;
        logoPreview.value = formObj.value.logo || null;
        logoFile.value = null;
    };

    const saveEmpresa = async () => {
        submitted.value = true;

        if (!formObj.value.empresa?.trim()) {
            notify('warn', 'Campos incompletos', 'La razón social es obligatoria.');
            return;
        }
        if (!formObj.value.codigo?.trim()) {
            notify('warn', 'Campos incompletos', 'El código interno es obligatorio.');
            return;
        }
        if (!formObj.value.matricula_comercio?.trim()) {
            notify('warn', 'Campos incompletos', 'La matrícula de comercio es obligatoria.');
            return;
        }
        if (formObj.value.email && !esEmailValido(formObj.value.email)) {
            notify('warn', 'Correo inválido', 'El formato del correo no es válido.');
            return;
        }
        if (!isUpdate.value && !logoFile.value && !formObj.value.logo) {
            notify('warn', 'Logo requerido', 'Debe cargar un logo al crear la empresa.');
            return;
        }

        try {
            loading.value = true;

            const payload: Record<string, any> = {
                empresa: formObj.value.empresa?.trim().toUpperCase(),
                codigo: formObj.value.codigo?.trim().toUpperCase(),
                matricula_comercio: formObj.value.matricula_comercio?.trim().toUpperCase(),
            };

            const opcionales = ['eslogan', 'descripcion', 'lugar', 'representante', 'direccion', 'telefono', 'email'];
            opcionales.forEach((key) => {
                const val = formObj.value[key];
                if (val !== null && val !== undefined && val !== '') {
                    payload[key] = typeof val === 'string' ? val.trim() : val;
                }
            });

            const pk = isUpdate.value ? resolvePK(formObj.value) : null;
            await saveWithLogo(payload, logoFile.value, pk);

            notify(
                'success',
                isUpdate.value ? 'Actualizado' : 'Creado',
                'Registro guardado correctamente.'
            );

            lazyParams.value.first = 0;
            onSearch();

            hideDialog();
            logoFile.value = null;
            logoPreview.value = null;
        } catch (err: any) {
            const msg = err?.data?.message || 'No se pudo guardar la empresa.';
            notify(
                'error',
                isUpdate.value ? 'Error al actualizar' : 'Error al crear',
                Array.isArray(msg) ? msg.join(', ') : msg
            );
            console.error('Error al guardar empresa:', err);
        } finally {
            loading.value = false;
        }
    };

    const columns = [
        { field: 'codigo', header: 'CÓDIGO', template: 'body-codigo', sortable: true, class: 'w-28' },
        { field: 'empresa', header: 'RAZÓN SOCIAL', template: 'body-empresa', sortable: true },
        { field: 'telefono', header: 'CONTACTO', template: 'body-contacto', sortable: false },
        { field: 'lugar', header: 'UBICACIÓN', sortable: true },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];

    const logoConfig = ref<{ maxSizeKB: number; maxWidth: number; maxHeight: number; formats: string } | null>(null);

    onMounted(async () => {
        logoConfig.value = await getConfigDisplay('logo_config');
    });
</script>
