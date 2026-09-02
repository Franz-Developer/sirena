<template>
    <div class="custom-table">
        <DataTable 
            v-bind="$attrs"
            :class="[
                'text-[11px]',
                tableClass
            ]"
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
        >
            <template #header>
                <slot name="header">
                    <div class="px-4 py-2 flex justify-between items-center bg-white border-b border-slate-200">
                        <slot name="header-actions" />
                    </div>
                </slot>
            </template>
            
            <!-- Columnas con cabecera azul -->
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
                    <template #body="slotProps" v-if="column.template">
                        <slot :name="column.template" :data="slotProps.data" />
                    </template>
                    <template #body="slotProps" v-else>
                        {{ slotProps.data[column.field] }}
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
    /* ESTILOS PROPIOS DEL COMPONENTE */
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
    }

    .custom-table .p-datatable .p-datatable-tbody > tr > td {
        font-size: 11px !important;
        padding-top: 0.5rem !important;
        padding-bottom: 0.5rem !important;
        padding-left: 0.75rem !important;
        padding-right: 0.75rem !important;
    }

    .custom-table .p-datatable .p-datatable-tbody > tr:hover {
        background-color: rgba(59, 130, 246, 0.08) !important;
    }

    .custom-table .p-datatable .p-paginator {
        background-color: white !important;
        border-top: 1px solid #e2e8f0 !important;
        font-size: 11px !important;
        padding-top: 0.5rem !important;
        padding-bottom: 0.5rem !important;
    }

    .custom-table .p-paginator .p-paginator-element {
        font-size: 11px !important;
        min-width: 2rem !important;
        height: 2rem !important;
    }

    /* Esquinas redondeadas */
    .custom-table .p-datatable .p-datatable-thead > tr:first-child > th:first-child {
        border-top-left-radius: 0.5rem !important;
    }

    .custom-table .p-datatable .p-datatable-thead > tr:first-child > th:last-child {
        border-top-right-radius: 0.5rem !important;
    }

    /* Scroll suave para la tabla */
    .custom-table .p-datatable-wrapper {
        border-radius: 0.5rem;
        overflow: hidden;
    }
</style>
