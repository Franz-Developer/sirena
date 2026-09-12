
<!-- C:\sirena\sirena-frontend\app\components\crud\CrudDeleteDialog.vue -->
<template>
    <Dialog
        v-model:visible="visible"
        :style="{ width: '480px' }"
        :modal="true"
        :draggable="false"
        :showHeader="false"
        :pt="{
            root: { class: '!p-0', autofocus: false },
            content: { class: '!p-0' },
        }"
        @show="focusCancelButton"
    >
        <!-- Header personalizado -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h3 class="text-base font-bold text-slate-700 uppercase tracking-wide">
                {{ title }}
            </h3>
            <button
                type="button"
                tabindex="-1"
                class="ripple-btn w-8 h-8 flex items-center justify-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                @click="visible = false"
            >
                <i class="pi pi-times text-sm"></i>
            </button>
        </div>

        <!-- Body -->
        <div class="flex items-start gap-4 px-6 py-6">
            <div class="flex-1 pt-1">
                <p class="text-base font-bold text-slate-800 leading-tight">
                    ¿Eliminar permanentemente?
                </p>
                <p class="text-sm text-slate-600 mt-2 leading-relaxed">
                    Se eliminará <b class="text-slate-800">{{ itemName }}</b> de forma definitiva.
                    Esta acción no se puede deshacer.
                </p>
            </div>
        </div>

        <!-- Footer -->
        <template #footer>
            <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-100 min-h-[72px]">
                <BaseButton
                    ref="cancelBtnRef"
                    label="Cancelar"
                    icon="pi pi-times"
                    variant="dialog-cancel"
                    @click="visible = false"
                />
                <BaseButton
                    label="Sí, eliminar"
                    icon="pi pi-trash"
                    variant="danger"
                    class="!px-4 !py-2"
                    @click="$emit('confirm')"
                />
            </div>
        </template>
    </Dialog>
</template>

<script setup lang="ts">
    import { ref, nextTick, computed } from 'vue';

    const props = defineProps<{
        visible: boolean;
        title: string;
        itemName: string;
    }>();

    const emit = defineEmits<{
        'update:visible': [value: boolean];
        confirm: [];
    }>();

    const visible = computed({
        get: () => props.visible,
        set: (val) => emit('update:visible', val),
    });

    const cancelBtnRef = ref<any>(null);

    const focusCancelButton = async () => {
        await nextTick();
        setTimeout(() => {
            requestAnimationFrame(() => {
                cancelBtnRef.value?.focus();
            });
        }, 50);
    };
</script>

<!-- C:\sirena\sirena-frontend\app\components\base\BaseButton.vue -->
<template>
    <button
        ref="buttonRef"
        v-bind="$attrs"
        type="button"
        :class="buttonClass"
        :disabled="loading || disabled"
    >
        <i v-if="loading" class="pi pi-spin pi-spinner"></i>
        <i v-else-if="icon" :class="icon"></i>
        <slot>{{ label }}</slot>
    </button>
</template>

<script setup lang="ts">
    import { computed, ref, type Ref } from 'vue';

    const props = defineProps({
        variant: {
            type: String,
            default: 'primary',
            validator: (value: string) => [
                'primary', 'secondary', 'danger', 'cancel', 'dialog-cancel',
                'success', 'warning', 'ghost', 'ghost-orange', 'ghost-green',
                'ghost-red', 'ghost-purple', 'ghost-amber', 'ghost-sky',
                'secondary-light', 'menu-amber', 'menu-danger'
            ].includes(value)
        },
        loading: { type: Boolean, default: false },
        disabled: { type: Boolean, default: false },
        label: { type: String, default: '' },
        icon: { type: String, default: '' },
        size: {
            type: String,
            default: 'default',
            validator: (value: string) => ['sm', 'default', 'lg'].includes(value)
        }
    });

    const buttonClass = computed(() => {
        const base = 'inline-flex items-center justify-center gap-2 font-bold border-0 cursor-pointer transition-colors duration-150 disabled:opacity-50 disabled:cursor-not-allowed';

        const sizeClasses: Record<string, string> = {
            sm: 'text-[10px] px-2 py-1 rounded-lg min-h-[28px]',
            default: 'text-xs px-4 py-2 rounded-[var(--radius-std)]',
            lg: 'text-sm px-6 py-3 rounded-[var(--radius-std)]'
        };

        const variantClasses: Record<string, string> = {
            primary: 'bg-[var(--primary-dark)] text-white hover:bg-[var(--primary-dark-hover)]',
            secondary: 'bg-[var(--secondary-color)] text-white hover:bg-[var(--secondary-hover)]',
            danger: 'bg-[var(--danger-color)] text-white hover:bg-[var(--danger-hover)]',
            cancel: 'bg-[var(--bg-disabled)] text-slate-700 border border-[var(--border-color)] hover:bg-slate-300',
            'dialog-cancel': 'bg-slate-600 text-white hover:bg-slate-800',
            success: 'bg-emerald-600 text-white hover:bg-emerald-800',
            warning: 'bg-amber-600 text-white hover:bg-amber-700',

            // Ghost: sin fondo → hover con fondo de color notorio.
            ghost: 'bg-transparent text-slate-600 hover:bg-slate-200 hover:text-slate-900',
            'ghost-orange': 'bg-transparent text-orange-500 hover:bg-orange-200 hover:text-orange-700',
            'ghost-green': 'bg-transparent text-emerald-600 hover:bg-emerald-200 hover:text-emerald-800',
            'ghost-red': 'bg-transparent text-red-500 hover:bg-red-200 hover:text-red-700',
            'ghost-purple': 'bg-transparent text-purple-600 hover:bg-purple-200 hover:text-purple-800',
            'ghost-amber': 'bg-transparent text-amber-600 hover:bg-amber-200 hover:text-amber-800',
            'ghost-sky': 'bg-transparent text-sky-600 hover:bg-sky-200 hover:text-sky-800',

            'secondary-light': 'bg-slate-500 text-white border-transparent hover:bg-slate-800',
            'menu-amber': 'bg-transparent text-slate-600 hover:bg-amber-200 hover:text-amber-700',
            'menu-danger': 'bg-transparent text-red-500 hover:bg-red-200 hover:text-red-700',
        };

        return [
            base,
            sizeClasses[props.size] || sizeClasses.default,
            variantClasses[props.variant] || variantClasses.primary
        ];
    });

    const buttonRef: Ref<HTMLButtonElement | null> = ref(null);

    defineExpose({
        focus: () => buttonRef.value?.focus(),
        blur: () => buttonRef.value?.blur(),
    });
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

/* 8. NEUTRALIZAR HOVER/ACTIVE/FOCUS DE PRIMEVUE EN BOTONES */
.p-button,
.p-button:not(:disabled):hover,
.p-button:not(:disabled):active,
.p-button:not(:disabled):focus {
    box-shadow: none !important;
    transform: none !important;
    transition: none !important;
    outline: none !important;
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

/* 👇 Animación al hacer :active */
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

/* 12. BASE TABLE — Layout, scroll y cabecera fija. Solo aplica a <BaseTable> (marcado con .base-table) */
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

como puedo hacer que los botones se note si tiene o no tiene el foco 

