<template>
    <div class="pt-0 md:pt-2 px-4 md:px-6 pb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
            <div class="flex items-center gap-3">
                <div class="bg-[var(--primary-dark)] p-2.5 rounded-xl shadow-lg shadow-blue-900/20">
                <i class="pi pi-building text-white text-xl"></i>
            </div>
                <div>
                    <h1 class="text-xl font-black text-slate-800 dark:text-white uppercase tracking-tight">Empresas</h1>
                    <p class="text-slate-500 dark:text-slate-400 text-xs font-medium">Gestión de datos fiscales y organizacionales</p>
                </div>
            </div>
            <BaseButton v-if="permisosApi && permisos.crear" label="NUEVA EMPRESA" icon="pi pi-plus" variant="primary" size="lg" @click="openNew" />
        </div>

        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            <BaseTable :value="empresas" :loading="loading" :columns="columns" :totalRecords="totalRecords" :rows="lazyParams.rows" :first="lazyParams.first" :sortField="lazyParams.sortField" :sortOrder="lazyParams.sortOrder" @page="onPage" @sort="onSort" >
               <template #header>
                    <div class="px-4 py-3 flex justify-end bg-white border-b border-slate-200">
                        <IconField iconPosition="left" class="w-full md:w-80">
                            <BaseInput v-model="filters['global']" placeholder="Buscar empresa..." icon="pi pi-search" class="w-full" @input="onSearch" />
                        </IconField>
                    </div>
                </template>

                <template #body-codigo="{ data }">
                    <span class="font-bold text-blue-600">{{ data.codigo }}</span>
                </template>

                <template #body-estado="{ data }">
                    <Tag :value="data.estadoAbreviatura" :severity="data.estado_id == idActivo ? 'success' : 'info'" class="text-[10px] font-bold uppercase px-2" />
                </template>

                <template #body-acciones="{ data }">
                    <div class="flex gap-1 justify-center">
                        <BaseButton v-if="permisos.editar && data.estado_id == idActivo" icon="pi pi-pencil" variant="ghost" size="sm" @click="editEmpresa(data)" v-tooltip.top="'Editar'" />
                        <BaseButton v-if="permisos.archivar" :icon="data.estado_id == idActivo ? 'pi pi-lock-open' : 'pi pi-lock'" :variant="data.estado_id == idActivo ? 'ghost-orange' : 'ghost-green'" size="sm" @click="toggleEstado(data)" v-tooltip.top="data.estado_id == idActivo ? 'Archivar' : 'Restaurar'" />
                        <BaseButton v-if="permisos.eliminar && data.estado_id == idActivo" icon="pi pi-trash" variant="ghost-red" size="sm" @click="confirmDelete(data)" v-tooltip.top="'Eliminar'" />
                    </div>
                </template>
            </BaseTable>
        </div>

        <Dialog v-model:visible="empresaDialog" :style="{ width: '1100px', maxHeight: '90vh' }" :modal="true" :closable="!loading" class="custom-modal" content-class="!bg-white" header-class="!bg-white" footer-class="!bg-white" >
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[#113f67] p-2 rounded-lg shadow">
                        <i class="pi pi-building text-white text-lg"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase">{{ formTitle }}</h3>
                        <p class="text-xs text-slate-500">Gestión de datos institucionales y fiscales</p>
                    </div>
                </div>
            </template>
            <div class="p-6" style="max-height: 90vh; overflow: auto;">
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-4">
                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <div class="flex justify-between items-center mb-4 text-blue-700 uppercase tracking-wider font-black text-xs">
                            <span>Información Fiscal e Identidad</span>
                            <span class="text-slate-600 normal-case font-bold text-[10px]">
                                Campos obligatorios <span class="text-red-500">*</span>
                            </span>
                        </div>
                        <div class="grid grid-cols-12 gap-x-4 gap-y-3">
                            <div class="col-span-12">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Razón Social <span class="text-red-500">*</span></label>
                                <BaseInput v-model="empresaObj.empresa" :maxlength="LIMITS.EMPRESA" size="sm" @blur="touched.empresa = true" :class="{'p-invalid': (submitted || touched.empresa) && ($rules.obligatoria()(empresaObj.empresa) !== true)}" />
                                <div class="flex justify-between mt-1">
                                    <small v-if="(submitted || touched.empresa) && $rules.obligatoria()(empresaObj.empresa) !== true" class="text-red-500 font-semibold text-[10px]">La razón social es obligatoria </small>
                                    <small class="text-[10px] font-bold ml-auto text-blue-600">{{ empresaObj.empresa?.length || 0 }}/{{ LIMITS.EMPRESA }} </small>
                                </div>
                            </div>
                            <div class="col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Código Interno <span class="text-red-500">*</span></label>
                                <BaseInput v-model="empresaObj.codigo" :maxlength="LIMITS.CODIGO" size="sm" @blur="touched.codigo = true" :class="{'p-invalid': (submitted || touched.codigo) && $rules.obligatoria()(empresaObj.codigo) !== true}" />
                                <div class="flex justify-between mt-1">
                                    <small v-if="(submitted || touched.codigo) && $rules.obligatoria()(empresaObj.codigo) !== true" class="text-red-500 font-semibold text-[10px]">Requerido</small>
                                    <small class="text-[10px] text-blue-600 font-bold ml-auto">{{ empresaObj.codigo?.length || 0 }}/{{ LIMITS.CODIGO }}</small>
                                </div>
                            </div>
                            <div class="col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">NIT / Identificación</label>
                                <BaseInput v-model="empresaObj.nit" :maxlength="LIMITS.NIT" size="sm" />
                                <div class="flex justify-end mt-1"><small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.nit?.length || 0 }}/{{ LIMITS.NIT }}</small></div>
                            </div>
                            <div class="col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Representante Legal</label>
                                <BaseInput v-model="empresaObj.representante" :maxlength="LIMITS.REPRESENTANTE" size="sm" />
                                <div class="flex justify-end mt-1">
                                    <small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.representante?.length || 0 }}/{{ LIMITS.REPRESENTANTE }}</small>
                                </div>
                            </div>
                            <div class="col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Eslogan Institucional</label>
                                <BaseInput v-model="empresaObj.eslogan" :maxlength="LIMITS.ESLOGAN" size="sm" />
                                <div class="flex justify-end mt-1">
                                    <small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.eslogan?.length || 0 }}/{{ LIMITS.ESLOGAN }}</small>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm">
                        <span class="block text-xs font-black text-blue-700 uppercase tracking-wider mb-4">Contacto y Ubicación</span>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Teléfono</label>
                                <BaseInput v-model="empresaObj.telefono" :maxlength="LIMITS.TELEFONO" size="sm" />
                                <div class="flex justify-end mt-1"><small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.telefono?.length || 0 }}/{{ LIMITS.TELEFONO }}</small></div>
                            </div>
                            <div class="md:col-span-1">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Correo</label>
                                <BaseInput v-model="empresaObj.email" :maxlength="LIMITS.EMAIL" size="sm" @blur="touched.email = true" :class="{'p-invalid': (submitted || touched.email) && empresaObj.email && $rules.formatoCorreo()(empresaObj.email) !== true}" />
                                <div class="flex justify-between mt-1">
                                    <small v-if="(submitted || touched.email) && empresaObj.email && $rules.formatoCorreo()(empresaObj.email) !== true" class="text-red-500 font-semibold text-[10px]">{{ $rules.formatoCorreo()(empresaObj.email) }}</small>
                                    <small class="text-[10px] text-blue-600 font-bold ml-auto">{{ empresaObj.email?.length || 0 }}/{{ LIMITS.EMAIL }}</small>
                                </div>
                            </div>
                            <div class="md:col-span-1">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Dirección Exacta</label>
                                <BaseInput v-model="empresaObj.direccion" :maxlength="LIMITS.DIRECCION" size="sm" />
                                <div class="flex justify-end mt-1">
                                    <small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.direccion?.length || 0 }}/{{ LIMITS.DIRECCION }}</small>
                                </div>
                            </div>
                            <div class="md:col-span-1">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Lugar / Ciudad</label>
                                <BaseInput v-model="empresaObj.lugar" :maxlength="LIMITS.LUGAR" size="sm" placeholder="Ej: La Paz - Bolivia" />
                                <div class="flex justify-end mt-1">
                                    <small class="text-[10px] text-blue-600 font-bold">{{ empresaObj.lugar?.length || 0 }}/{{ LIMITS.LUGAR }}</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-white p-5 rounded-2xl border border-slate-300 shadow-sm mt-4">
                    <div class="flex flex-col items-center gap-4">
                        <div class="text-[11px] text-slate-700 text-center">
                            <span class="font-bold text-slate-800">Requisitos del logo:</span>
                            <div>📌 Máx. 200 KB • Extensiones: JPG, JPEG, PNG • Dimensiones: Máx. 1500x450px</div>
                        </div>
                        <div class="w-96 h-52 rounded-2xl border-2 border-dashed border-slate-300 bg-slate-50 flex items-center justify-center overflow-hidden">
                            <img v-if="logoPreview" :src="logoPreview" class="w-full h-full object-contain" />
                            <i v-else class="pi pi-image text-slate-300 text-3xl"></i>
                        </div>
                        <input type="file" ref="logoInput" class="hidden" accept="image/*" @change="onLogoChange" />
                        <div class="flex gap-2 w-full justify-center max-w-sm">
                            <BaseButton :label="logoPreview ? 'Cambiar Logo' : 'Cargar Logo'" icon="pi pi-upload" variant="primary" size="sm" @click="$refs.logoInput.click()" />
                            <BaseButton v-if="logoPreview" label="Quitar" icon="pi pi-trash" variant="danger" size="sm" @click="logoPreview = null; empresaObj.logo = ''" />
                        </div>
                    </div>
                </div>
            </div>
            <template #footer>
                <div class="flex justify-end gap-3 pb-2 pt-4">
                    <BaseButton label="Cancelar" icon="pi pi-times" :loading="loading" variant="danger" @click="hideDialog" />
                    <BaseButton label="Guardar Registro" icon="pi pi-save" :loading="loading" variant="primary" @click="saveEmpresa" />
                </div>
            </template>
        </Dialog>

        <Dialog v-model:visible="deleteDialog" :style="{width: '450px'}" header="Eliminar Empresa" :modal="true">
            <div class="flex items-center gap-3">
                <i class="pi pi-exclamation-triangle text-red-500 text-3xl" />
                <span>¿Eliminar permanentemente a <b>{{empresaObj.empresa}}</b>?</span>
            </div>
            <template #footer>
                <BaseButton label="NO" variant="secondary-light" @click="deleteDialog = false" />
                <BaseButton label="SÍ, ELIMINAR" variant="danger" @click="deleteEmpresa" />
            </template>
        </Dialog>
    </div>
</template>

<script setup>
    const { notify } = useNotify();
    const { $rules } = useNuxtApp();
    const config = useRuntimeConfig();
    const authStore = useAuthStore();
    const catalogosStore = useCatalogosStore();
    const idActivo = computed(() => catalogosStore.getId('ESTADO', 'ACTIVO'));
    const MENU_ID = ref(null);
    const empresas = ref([]);
    const loading = ref(false);
    const empresaDialog = ref(false);
    const deleteDialog = ref(false);
    const filters = ref({ global: '' });
    const touched = ref({});
    const submitted = ref(false);
    const logoFile = ref(null);
    const logoPreview = ref(null);
    const logoInput = ref(null);
    const LIMITS = Object.freeze({ EMPRESA:200, CODIGO:30, NIT:30, REPRESENTANTE:60, TELEFONO:100, EMAIL:200, DIRECCION:3000, LUGAR:500, ESLOGAN:30, DESCRIPCION:1500 });
    const columns = [
        { field: 'codigo', header: 'CÓDIGO', sortable: true, template: 'body-codigo', bodyClass: '!text-center' },
        { field: 'empresa', header: 'RAZÓN SOCIAL', sortable: true },
        { field: 'nit', header: 'NIT' },
        { field: 'telefono', header: 'TELÉFONO' },
        { field: 'lugar', header: 'UBICACIÓN' },
        { field: 'estadoAbreviatura', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-20', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-24', sortable: false }
    ];
    const formTitle = computed(() => empresaObj.value.empresa_id ? 'Editar Empresa' : 'Nueva Empresa');
    const logoError = ref(false);
    const totalRecords = ref(0);
    const lazyParams = ref({
        first: 0,
        rows: 20,
        page: 0,
        sortField: 'empresa_id',
        sortOrder: -1
    });

    const loadEmpresas = async (search = '', silent = false) => {
        if (!silent) loading.value = true;
        try {
            const params = {
                limit: lazyParams.value.rows,
                offset: lazyParams.value.first,
                sortField: lazyParams.value.sortField,
                sortOrder: lazyParams.value.sortOrder
            };

            if (search?.trim()) params.q = search.trim();

            const response = await $fetch(`${config.public.apiBase}/empresas`, {
                headers: { Authorization: `Bearer ${authStore.token}` },
                params
            });

            empresas.value = response.data || [];
            totalRecords.value = response.total || 0;
            if ((response.data || []).length === 0 && search) notify('warn', 'Búsqueda', 'No se encontraron empresas con los criterios ingresados');
        } catch (err) {
            notify('error', 'Error al obtener la lista de empresas', 'No se pudo recuperar la lista de empresas desde el servidor. Verifica la conexión.');
            console.error('Error al cargar empresas:', err);
        } finally {
            loading.value = false;
        }
    };

    const getCleanForm = () => ({ empresa_id: null, empresa: '', nit: '', codigo: '', representante: '', telefono: '', direccion: '', email: '', lugar: '', eslogan: '', descripcion: '', logo: '' });
    const empresaObj = ref(getCleanForm());

    const onPage = (event) => {
        lazyParams.value = event;
        loadEmpresas(filters.value.global);
    };

    const onSort = (event) => {
        lazyParams.value = event;
        loadEmpresas(filters.value.global);
    };

    let timer;
    const onSearch = () => {
        clearTimeout(timer);
        timer = setTimeout(() => {
            lazyParams.value.first = 0;
            loadEmpresas(filters.value.global);
        }, 500);
    };

    const resetTouched = () => {
        touched.value = {
            empresa: false,
            codigo: false,
            nit: false,
            representante: false,
            telefono: false,
            email: false,
            direccion: false,
            lugar: false,
            eslogan: false,
            descripcion: false
        };
    };

    const resetForm = () => {
        empresaObj.value = getCleanForm();
        logoPreview.value = null;
        logoFile.value = null;
        submitted.value = false;
        touched.value = {};
    };

    const openNew = () => {
        resetForm();
        empresaDialog.value = true;
        logoError.value = false;
    };

    const editEmpresa = (data) => {
        empresaObj.value = { ...data };
        logoPreview.value = data.logo ? data.logo : null;
        resetTouched();
        submitted.value = false;
        empresaDialog.value = true;
        logoError.value = false;
    };

    const validateForm = () => {
        submitted.value = true;
        const isNew = !empresaObj.value.empresa_id;
        if (isNew && !empresaObj.value.logo) {
            notify('warn', 'Logo requerido', 'Debe cargar un logo.');
            return false;
        }

        const camposOk = $rules.obligatoria()(empresaObj.value.empresa) === true && $rules.obligatoria()(empresaObj.value.codigo) === true;
        if (!camposOk) {
            notify('warn', 'Atención', 'Complete los campos obligatorios.');
            return false;
        }
        return true;
    };

    const onLogoChange = async (event) => {
        const file = event.target.files[0];
        if (!file) {
            notify('warn', 'Imagen requerida', 'Debe seleccionar una imagen válida');
            return;
        }

        const MAX_SIZE_KB = 200;
        const allowedExtensions = ['image/jpeg', 'image/jpg', 'image/png'];
        if (!allowedExtensions.includes(file.type)) {
            notify('warn', 'Formato no permitido', 'Solo se aceptan imágenes JPG, JPEG o PNG.');
            event.target.value = '';
            return;
        }

        if (file.size > MAX_SIZE_KB * 1024) {
            notify('warn', 'Archivo muy pesado', `El logo no debe exceder los ${MAX_SIZE_KB} KB. (Tu archivo: ${(file.size / 1024).toFixed(1)} KB)`);
            event.target.value = '';
            return;
        }

        const reader = new FileReader();
        reader.onload = () => logoPreview.value = reader.result;
        reader.readAsDataURL(file);

        const formData = new FormData();
        formData.append("file", file);

        try {
            loading.value = true;
            const res = await $fetch(`${config.public.apiBase}/empresas/upload-logo`, {
                method: "POST",
                body: formData,
                headers: { Authorization: `Bearer ${authStore.token}` }
            });

            empresaObj.value.logo = res.filename;
            notify('success', 'Imagen válida', 'Dimensiones y peso verificados.');
        } catch (err) {
            logoPreview.value = null;
            event.target.value = '';
            notify('error', 'Error al subir el logo', 'No se pudo procesar la imagen seleccionada. Verifica que el archivo cumpla los requisitos.');
            console.error('Error al subir logo:', err);
        } finally {
            loading.value = false;
        }
    };

    const allowedFields = ["empresa", "codigo", "nit", "representante", "telefono", "direccion", "email", "lugar", "eslogan", "descripcion", "logo"];

    const saveEmpresa = async () => {
        if (!validateForm()) return;
        const isUpdate = !!empresaObj.value.empresa_id;
        const payload = {};
        allowedFields.forEach((key) => {
            if (empresaObj.value[key] !== undefined) {
                payload[key] = empresaObj.value[key];
            }
        });

        if (!payload.email || payload.email.trim() === '') { delete payload.email; }

        try {
            loading.value = true;
            const method = isUpdate ? 'PATCH' : 'POST';
            const url = isUpdate
                ? `${config.public.apiBase}/empresas/${empresaObj.value.empresa_id}`
                : `${config.public.apiBase}/empresas`;

            await $fetch(url, {
                method,
                body: payload,
                headers: {
                    Authorization: `Bearer ${authStore.token}`,
                    'Content-Type': 'application/json'
                }
            });

            notify('success', isUpdate ? 'Actualizado' : 'Creado', 'Datos guardados');
            await loadEmpresas();
            hideDialog();
        } catch (err) {
            const serverMessage = err.data?.message || 'Error desconocido';
            notify('error', 'Error al guardar empresa', serverMessage);
            if (serverMessage.includes('no existe en el servidor')) {
                empresaObj.value.logo = '';
                logoPreview.value = null;
            }
            console.error('Error al guardar empresa:', err);
        } finally {
            loading.value = false;
        }
    };

    const toggleEstado = async (data) => {
        const accion = data.estado_id == idActivo.value ? 'archivar' : 'desarchivar';
        try {
            await $fetch(`${config.public.apiBase}/empresas/${data.empresa_id}/${accion}`, {
                method: 'PATCH',
                headers: { Authorization: `Bearer ${authStore.token}` }
            });
            notify('success', 'Estado actualizado', 'El estado fue modificado correctamente');
            loadEmpresas(filters.value.global, true);
        } catch (err) {
            notify('error', 'Error al actualizar el estado de la empresa', `No se pudo ${accion} la empresa "${data.empresa}". Verifica que el servidor esté disponible.`);
            console.error(`Error al ${accion} empresa:`, err);
        }
    };

    const confirmDelete = (data) => {
        empresaObj.value = data;
        deleteDialog.value = true;
    };

    const deleteEmpresa = async () => {
        try {
            deleteDialog.value = false;
            loading.value = true;
            await $fetch(`${config.public.apiBase}/empresas/${empresaObj.value.empresa_id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${authStore.token}` }
            });
            notify('success', 'Eliminado', 'La empresa se eliminó correctamente.');
            await loadEmpresas();
        } catch (err) {
            const errorData = err.data;
            const msg = errorData?.message || 'No se pudo eliminar la empresa';
            let extraInfo = '';
            if (errorData?.detalles) {
                const motivos = [];
                if (errorData.detalles.activas > 0) motivos.push(`${errorData.detalles.activas} sucursal(es) activa(s)`);
                if (errorData.detalles.historicas > 0) motivos.push(`${errorData.detalles.historicas} sucursal(es) histórica(s)`);
                if (motivos.length > 0) extraInfo = `. Registros encontrados: ${motivos.join(' y ')}.`;
            }
            notify('error', 'Error al eliminar', `${msg}${extraInfo}`);
            console.error('Error al eliminar empresa:', err);
        } finally {
            loading.value = false;
        }
    };

    const hideDialog = () => {
        empresaDialog.value = false;
        resetForm();
    };

    const loadMenuId = async () => {
        MENU_ID.value = null;
        if (!idActivo.value) {
            notify('error', 'Error de Configuración', 'No se pudo determinar el estado ACTIVO para cargar el menú');
            return;
        }

        if (!authStore.token) {
            notify('warn', 'Sesión no encontrada', 'Debe iniciar sesión para cargar el módulo');
            return;
        }

        try {
            const response = await $fetch(`${config.public.apiBase}/menus`, {
                headers: { Authorization: `Bearer ${authStore.token}` },
                params: { estado_id: idActivo.value, q: 'EMPRESAS' }
            });
            const menus = Array.isArray(response) ? response : (response.data || []);
            if (menus.length > 0) {
                MENU_ID.value = menus[0].menu_id;
            } else {
                notify('error', 'Acceso Denegado', 'No se encontró configuración del menú EMPRESAS');
            }
        } catch (err) {
            notify('error', 'Error al cargar el menú de empresas', 'No se pudo recuperar la configuración del menú "EMPRESAS". Verifica la conexión.');
            console.error('Error al cargar menú:', err);
            throw err;
        }
    };

    const permisosApi = ref(null);

    const loadPermisos = async () => {
        permisosApi.value = null;
        if (!authStore.user?.rol_id || !idActivo.value || !MENU_ID.value) {
            if (!MENU_ID.value) notify('error', 'Fallo de identificación', 'No se encontró el identificador del módulo');
            return;
        }
        try {
            const res = await $fetch(`${config.public.apiBase}/roles-menus`, {
                headers: { Authorization: `Bearer ${authStore.token}` },
                params: { estado_id: idActivo.value, rol_id: authStore.user.rol_id, menu_id: MENU_ID.value }
            });
            permisosApi.value = res.data?.length > 0 ? res.data[0] : null;
            if (!permisosApi.value) notify('warn', 'Acceso denegado', 'Tu usuario no tiene permisos para operar en este módulo');
        } catch (err) {
            notify('error', 'Error al verificar permisos', `No se pudo obtener los permisos para el usuario. Verifica la conexión.`);
            console.error('Error al cargar permisos:', err);
        }
    };

    const permisos = computed(() => ({
        crear: permisosApi.value?.crear === 1,
        editar: permisosApi.value?.editar === 1,
        eliminar: permisosApi.value?.eliminar === 1,
        archivar: permisosApi.value?.archivar === 1,
        desarchivar: permisosApi.value?.desarchivar === 1
    }));

    const init = async () => {
        if (loading.value) {
            notify('warn', 'Procesando', 'Hay una operación en curso, espere un momento');
            return;
        }

        if (idActivo.value === undefined || idActivo.value === null) {
            notify('error', 'Error de Configuración', 'No se pudo determinar el estado "ACTIVO". Contacte a soporte.');
            return;
        }

        loading.value = true;

        try {
            await loadMenuId();
            if (!MENU_ID.value) {
                notify('error', 'Acceso Denegado', 'Módulo no configurado.');
                return;
            }
            await loadPermisos();
            if (permisosApi.value) { await loadEmpresas(); }
        } catch (err) {
            notify('error', 'Error crítico al preparar el módulo de empresas', 'Ocurrió un problema al inicializar el módulo. Verifica la conexión.');
            console.error('Error al inicializar módulo:', err);
        } finally {
            loading.value = false;
        }
    };

    watch([() => catalogosStore.isReady, () => authStore.token], async ([isReady, token]) => {
        if (isReady && token) await init();
    }, { immediate: true });
</script>
