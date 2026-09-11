<!-- C:\sirena\sirena-frontend\app\components\base\BaseTable.vue -->
<template>
    <div class="custom-table h-full flex flex-col">
        <DataTable
            v-bind="$attrs"
            :class="['text-[11px]', tableClass, 'h-full flex flex-col']"
            :value="value"
            :loading="loading"
            :paginator="paginator"
            :rows="rows"
            :totalRecords="totalRecords"
            :first="first"
            :sortField="sortField"
            :sortOrder="sortOrder"
            @page="onPage"
            @sort="onSort"
            size="small"
            responsiveLayout="stack"
            currentPageReportTemplate="{first} a {last} de {totalRecords}"
            paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
            :rowsPerPageOptions="[10, 20, 50]"
            scrollable
            scrollHeight="flex"
        >
            <template #header>
                <slot name="header">
                    <div class="px-4 py-2 flex justify-between items-center bg-white border-b border-slate-200">
                        <slot name="header-actions" />
                    </div>
                </slot>
            </template>

            <template v-for="(column, index) in columns" :key="index">
                <Column
                    :field="column.field"
                    :header="column.header"
                    :sortable="column.sortable !== undefined ? column.sortable : true"
                    :headerClass="'bg-[var(--primary-dark)] text-white text-[10px] uppercase tracking-wider font-bold ' + (column.headerClass || '')"
                    :bodyClass="'text-[11px] ' + (column.bodyClass || '')"
                    :class="column.class"
                    :style="column.style"
                >
                    <template #body="slotProps">
                        <slot
                            v-if="column.template"
                            :name="column.template"
                            :data="slotProps.data"
                        />
                        <template v-else>
                            {{ slotProps.data[column.field] }}
                        </template>
                    </template>
                </Column>
            </template>
        </DataTable>
    </div>
</template>

<script setup>
    const props = defineProps({
        value: { type: Array, default: () => [] },
        loading: { type: Boolean, default: false },
        paginator: { type: Boolean, default: true },
        rows: { type: Number, default: 10 },
        totalRecords: { type: Number, default: 0 },
        first: { type: Number, default: 0 },
        sortField: { type: String, default: '' },
        sortOrder: { type: Number, default: 1 },
        columns: { type: Array, required: true },
        title: { type: String, default: '' },
        tableClass: { type: String, default: '' }
    });

    const emit = defineEmits(['page', 'sort']);

    const onPage = (event) => emit('page', event);
    const onSort = (event) => emit('sort', event);
</script>

<style>
    /* Contenedor principal: columna flex con altura completa */
    .custom-table {
        display: flex;
        flex-direction: column;
        height: 100%;
        min-height: 0;
    }

    /* El DataTable ocupa todo el alto del padre */
    .custom-table > .p-datatable {
        display: flex;
        flex-direction: column;
        flex: 1 1 auto;
        min-height: 0;
    }

    /* El header (CrudTableFilter) se queda arriba */
    .custom-table > .p-datatable > .p-datatable-header {
        flex: 0 0 auto;
    }

    /* El wrapper de filas ocupa el espacio disponible y hace scroll */
    .custom-table > .p-datatable > .p-datatable-wrapper {
        flex: 1 1 auto;
        min-height: 0;
        overflow-y: auto !important;
        overflow-x: auto !important;
    }

    /* El paginador se queda abajo, siempre visible */
    .custom-table > .p-datatable > .p-paginator {
        flex: 0 0 auto;
        background-color: white !important;
        border-top: 1px solid #e2e8f0 !important;
        font-size: 11px !important;
        padding-top: 0.5rem !important;
        padding-bottom: 0.5rem !important;
    }

    /* Cabecera azul */
    .custom-table .p-datatable .p-datatable-thead > tr > th {
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
    .custom-table .p-datatable .p-datatable-tbody > tr > td {
        font-size: 11px !important;
        padding-top: 0.5rem !important;
        padding-bottom: 0.5rem !important;
        padding-left: 0.75rem !important;
        padding-right: 0.75rem !important;
    }

    /* Hover de fila */
    .custom-table .p-datatable .p-datatable-tbody > tr:hover {
        background-color: rgba(59, 130, 246, 0.08) !important;
    }

    /* Elementos del paginador */
    .custom-table .p-paginator .p-paginator-element {
        font-size: 11px !important;
        min-width: 2rem !important;
        height: 2rem !important;
    }

    /* Esquinas redondeadas en cabecera */
    .custom-table .p-datatable .p-datatable-thead > tr:first-child > th:first-child {
        border-top-left-radius: 0.5rem !important;
    }
    .custom-table .p-datatable .p-datatable-thead > tr:first-child > th:last-child {
        border-top-right-radius: 0.5rem !important;
    }
</style>
