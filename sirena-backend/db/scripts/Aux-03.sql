@baseUrl = http://localhost:3010/api
@baseUrl_parametros = {{baseUrl}}/parametros-globales

### LISTAR POR ESTADO ACTIVOS (1000)
GET {{baseUrl_parametros}}?estado_id=1000&clave=logo_config
Authorization: Bearer {{authToken}}
SALE 
{
  "data": [
    {
      "parametro_id": "33",
      "clave": "logo_config",
      "valor": "LOGO_CONFIG",
      "tipo_dato_id": 1805,
      "tipo_dato": {
        "abreviatura": "JSONB",
        "valor": 0,
        "prefijo": ""
      },
      "datos_json": {
        "max_size": 358400,
        "max_width": 1500,
        "max_height": 600,
        "default_logo": null,
        "retention_days": 1,
        "allowed_formats": [
          "png",
          "jpeg"
        ],
        "allowed_extensions": [
          "png",
          "jpg",
          "jpeg"
        ]
      },
      "descripcion": "Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)",
      "editable": 1,
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:46.605 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}

EN EL frotend 
necesito un archivo que permita ejecutar 
GET {{baseUrl_parametros}}?estado_id=1000&clave=logo_config o cualquier otra clave 

DELETE FROM parametros_globales;
ALTER SEQUENCE parametros_globales_parametro_id_seq RESTART WITH 1;

INSERT INTO parametros_globales (parametro_id,clave,valor,tipo_dato_id,datos_json,descripcion,editable,estado_id,usuario_id_registro) VALUES
	 (1,'ninguna','comodin_sistema',1800,NULL,'Registro comodin por defecto para parametros_globales',0,1000,1),
	 (2,'moneda_principal','BOB',1800,NULL,'Moneda base del sistema boliviano',0,1000,2),
	 (3,'porcentaje_iva','13.00',1802,NULL,'Alícuota general del IVA en Bolivia',0,1000,2),
	 (4,'limite_items_proforma','50',1801,NULL,'Cantidad máxima de ítems permitidos por proforma',1,1000,2),
	 (5,'controlar_lotes_vencidos','1',1803,NULL,'Habilitar bloqueo de venta para lotes expirados (1=Si, 0=No)',1,1000,2),
	 (6,'dias_alerta_vencimiento','90',1801,NULL,'Días de anticipación para notificar la expiración de medicamentos',1,1000,2),
	 (7,'modelo_arima_p','1',1801,NULL,'Orden autorregresivo (p) para modelo ARIMA',0,1000,2),
	 (8,'modelo_arima_d','1',1801,NULL,'Orden de diferenciación (d) para modelo ARIMA',0,1000,2),
	 (9,'modelo_arima_q','1',1801,NULL,'Orden de promedio móvil (q) para modelo ARIMA',0,1000,2),
	 (10,'modelo_sarima_p','1',1801,NULL,'Orden autorregresivo estacional (P) para SARIMA',0,1000,2),
	 (11,'modelo_sarima_d','1',1801,NULL,'Orden de diferenciación estacional (D) para SARIMA',0,1000,2),
	 (12,'modelo_sarima_q','1',1801,NULL,'Orden de promedio móvil estacional (Q) para SARIMA',0,1000,2),
	 (13,'modelo_sarima_s','7',1801,NULL,'Período estacional (s) para SARIMA (7=días, 12=meses)',0,1000,2),
	 (14,'modelo_kmeans_n_clusters','3',1801,NULL,'Número de clusters para K-Means (A, B, C)',0,1000,2),
	 (15,'modelo_kmeans_random_state','42',1801,NULL,'Semilla aleatoria para reproducibilidad',0,1000,2),
	 (16,'modelo_kmeans_max_iter','300',1801,NULL,'Máximo de iteraciones para K-Means',0,1000,2),
	 (17,'modelo_rop_lead_time_default','7',1801,NULL,'Lead time por defecto en días para cálculo de ROP',0,1000,2),
	 (18,'modelo_rop_stock_seguridad_default','10',1802,NULL,'Stock de seguridad por defecto para ROP',0,1000,2),
	 (19,'modelo_rop_nivel_confianza','0.95',1802,NULL,'Nivel de confianza para intervalos de predicción',0,1000,2),
	 (20,'alerta_dias_vencimiento_critico','15',1801,NULL,'Días para alerta CRÍTICA de vencimiento',1,1000,2),
	 (21,'alerta_dias_vencimiento_alta','30',1801,NULL,'Días para alerta ALTA de vencimiento',1,1000,2),
	 (22,'alerta_dias_vencimiento_media','60',1801,NULL,'Días para alerta MEDIA de vencimiento',1,1000,2),
	 (23,'alerta_stock_quiebre','5',1801,NULL,'Stock mínimo para alerta de quiebre',1,1000,2),
	 (24,'alerta_stock_reorden','20',1801,NULL,'Stock para alerta de reorden',1,1000,2),
	 (25,'alerta_dias_ventanas_dias','90',1801,NULL,'Ventana de días para entrenar modelos',1,1000,2),
	 (26,'entrenamiento_min_registros','30',1801,NULL,'Mínimo de registros para entrenar un modelo',1,1000,2),
	 (27,'entrenamiento_test_size','0.2',1802,NULL,'Porcentaje de datos para prueba (test)',1,1000,2),
	 (28,'longitud_numero_factura','7',1801,NULL,'Cantidad de dígitos para el número de factura (con ceros a la izquierda)',1,1000,2),
	 (29,'multa_dias_gracia','10',1801,NULL,'Días de tolerancia permitidos antes de aplicar cargos por retraso en cuotas',1,1000,2),
	 (30,'multa_tipo_calculo','PORCENTAJE',1800,NULL,'Tipo de cálculo para la multa: MONTO_FIJO o PORCENTAJE sobre la cuota vencida',1,1000,2),
	 (31,'multa_valor_diario','0.50',1802,NULL,'Valor diario de la multa (monto en moneda base o porcentaje según el tipo de cálculo)',1,1000,2),
	 (32,'gestion_activa','2026-01-01 00:00:00-04:00',1804,NULL,'Fecha y hora de inicio de la gestión activa del sistema (con timezone -04:00 Bolivia)',1,1000,2),
	 (33, 'logo_config', 'LOGO_CONFIG', 1805, '{"max_size": 358400, "max_width": 1500, "max_height": 600, "default_logo": null, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2),
	 (34, 'factores', 'FACTORES_CONFIG', 1805, '{"factor_venta": 1.50, "factor_facturacion": 1.19}', 'Configuración agrupada de factores para venta y facturación', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (35, 'foto_trabajador_config', 'default-foto-trabajador.jpg', 1805, '{"max_size": 512000, "max_width": 600, "max_height": 700, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de fotos de trabajadores en formato vertical (tamaño máximo: 500 KB, dimensiones: 600x700 px)', 1, 1000, 2),
     (36, 'qr_trabajador_config', 'QR_CONFIG', 1805, '{"width": 300, "height": 300, "margin": 2, "color_dark": "#000000", "color_light": "#FFFFFF", "format": "png", "error_correction_level": "M"}', 'Configuración para la autogeneración de códigos QR del trabajador (300x300 px, fondo blanco, PNG)', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (37, 'avatar_config', 'AVATAR_CONFIG', 1805, '{"max_size": 20480, "max_width": 48, "max_height": 48, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de avatares de usuarios (tamaño máximo: 20 KB, dimensiones: 48x48 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2);
	 
SELECT setval('parametros_globales_parametro_id_seq', COALESCE((SELECT MAX(parametro_id) FROM parametros_globales), 0), (SELECT COUNT(*) > 0 FROM parametros_globales));


Luego en el frontend que no deje subir uan imagen si no cumple 
{
  "data": [
    {
      "parametro_id": "33",
      "clave": "logo_config",
      "valor": "LOGO_CONFIG",
      "tipo_dato_id": 1805,
      "tipo_dato": {
        "abreviatura": "JSONB",
        "valor": 0,
        "prefijo": ""
      },
      "datos_json": {
        "max_size": 358400,
        "max_width": 1500,
        "max_height": 600,
        "default_logo": null,
        "retention_days": 1,
        "allowed_formats": [
          "png",
          "jpeg"
        ],
        "allowed_extensions": [
          "png",
          "jpg",
          "jpeg"
        ]
      },
      "descripcion": "Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)",
      "editable": 1,
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:46.605 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}

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
                    <CrudTableFilter
                        v-model:search-value="filters.global"
                        v-model:exact-match="filters.exactMatch"
                        search-placeholder="Buscar empresa, código, NIT..."
                        @search="onSearch"
                    />
                </template>

                <template #body-logo="{ data }">
                    <div class="flex justify-center">
                        <img
                            v-if="data.logo"
                            :src="data.logo"
                            class="h-9 w-9 object-contain rounded border border-slate-200"
                            @error="($event.target as HTMLImageElement).style.display = 'none'"
                        />
                        <div v-else class="h-9 w-9 flex items-center justify-center bg-slate-100 rounded border border-slate-200">
                            <i class="pi pi-image text-slate-300 text-xs"></i>
                        </div>
                    </div>
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
                    <div class="flex flex-col text-[10px] leading-tight">
                        <span v-if="data.telefono" class="text-slate-600">
                            <i class="pi pi-phone text-[9px] mr-1"></i>{{ data.telefono }}
                        </span>
                        <span v-if="data.email" class="text-slate-500 truncate max-w-[180px]">
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

                        <div class="grid grid-cols-12 gap-x-4 gap-y-3">
                            <div class="col-span-12">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
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

                            <div class="col-span-6">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1 uppercase">Representante Legal</label>
                                <BaseInput v-model="formObj.representante" :maxlength="100" size="sm" />
                            </div>

                            <div class="col-span-6">
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
                                        Peso máximo: <b>200 KB</b>
                                    </li>
                                    <li class="flex items-center gap-2">
                                        <i class="pi pi-check-circle text-emerald-500 text-xs"></i>
                                        Formatos: <b>JPG, JPEG, PNG</b>
                                    </li>
                                    <li class="flex items-center gap-2">
                                        <i class="pi pi-check-circle text-emerald-500 text-xs"></i>
                                        Dimensiones máximas: <b>1500 × 450 px</b>
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

                            <div class="flex gap-2">
                                <BaseButton
                                    v-if="logoPreview"
                                    label="Quitar"
                                    icon="pi pi-trash"
                                    variant="danger"
                                    size="sm"
                                    @click="quitarLogo"
                                />
                                <BaseButton
                                    :label="logoPreview ? 'Cambiar Logo' : 'Cargar Logo'"
                                    icon="pi pi-upload"
                                    variant="primary"
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

    const onLogoChange = (event: Event) => {
        const target = event.target as HTMLInputElement;
        const file = target.files?.[0];
        if (!file) return;

        const MAX_SIZE_KB = 200;
        const allowed = ['image/jpeg', 'image/jpg', 'image/png'];

        if (!allowed.includes(file.type)) {
            notify('warn', 'Formato no permitido', 'Solo JPG, JPEG o PNG.');
            target.value = '';
            return;
        }
        if (file.size > MAX_SIZE_KB * 1024) {
            notify('warn', 'Archivo muy pesado', `El logo no debe exceder ${MAX_SIZE_KB} KB.`);
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
        { field: 'logo', header: '', template: 'body-logo', bodyClass: '!text-center', class: 'w-14', sortable: false },
        { field: 'codigo', header: 'CÓDIGO', template: 'body-codigo', sortable: true, class: 'w-28' },
        { field: 'empresa', header: 'RAZÓN SOCIAL', template: 'body-empresa', sortable: true },
        { field: 'telefono', header: 'CONTACTO', template: 'body-contacto', sortable: false },
        { field: 'lugar', header: 'UBICACIÓN', sortable: true },
        { field: 'estado_registro', header: 'ESTADO', template: 'body-estado', bodyClass: '!text-center', class: 'w-24', sortable: false },
        { header: 'ACCIONES', template: 'body-acciones', class: '!text-center !w-28', sortable: false },
    ];
</script>
