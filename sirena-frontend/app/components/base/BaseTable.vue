<!-- C:\sirena\sirena-frontend\app\components\base\BaseTable.vue -->
<template>
    <div class="base-table h-full flex flex-col min-h-0">

        <!-- DESKTOP: tabla normal -->
        <DataTable
            v-if="viewportReady && isDesktop"
            v-bind="$attrs"
            lazy
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
            scrollable
            scrollHeight="flex"
            currentPageReportTemplate="{first} a {last} de {totalRecords}"
            paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
            :rowsPerPageOptions="[10, 20, 50]"
        >
            <template #header>
                <slot name="header" />
            </template>

            <template
                v-for="column in columns"
                :key="column.field || column.template"
            >
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
                        <BaseDynamicSlot
                            v-if="column.template && slots[column.template]"
                            :name="column.template"
                            :data="slotProps.data"
                            :slots="slots as any"
                        />
                        <template v-else>
                            {{ getFieldValue(slotProps.data, column.field) }}
                        </template>
                    </template>
                </Column>
            </template>
        </DataTable>

        <!-- MÓVIL: tarjetas generadas con v-for -->
        <div
            v-else-if="viewportReady"
            class="flex flex-col w-full h-full min-h-0"
        >
            <!-- Filtros (slot header) -->
            <slot name="header" />

            <!-- Estado de carga -->
            <div
                v-if="loading"
                class="rounded-2xl border border-slate-200 bg-white px-4 py-8 text-center"
            >
                <p class="text-xs font-semibold text-slate-500">
                    Cargando registros...
                </p>
            </div>

            <!-- Estado vacío -->
            <div
                v-else-if="value.length === 0"
                class="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-8 text-center"
            >
                <p class="text-xs font-semibold text-slate-500">
                    No se encontraron registros.
                </p>
            </div>

                        <!-- Tarjetas + paginador (con scroll propio) -->
            <template v-else>
                <div
                    class="flex flex-col gap-3 overflow-y-auto flex-1 min-h-0 pb-1
                        [&::-webkit-scrollbar]:w-1.5
                        [&::-webkit-scrollbar-thumb]:bg-slate-300
                        [&::-webkit-scrollbar-thumb]:rounded-full
                        [&::-webkit-scrollbar-track]:bg-transparent"
                >
                    <div
                        v-for="(item, idx) in value"
                        :key="rowKey ? item[rowKey] : idx"
                        class="flex-shrink-0 bg-white rounded-2xl border border-slate-300 shadow-sm overflow-hidden"
                    >
                        <div
                            v-for="column in columns"
                            :key="column.field || column.template"
                            class="flex justify-between items-start gap-4 px-4 py-3 border-b border-dashed border-slate-200 last:border-b-0"
                        >
                            <span class="text-[10px] font-bold uppercase tracking-wider text-[var(--primary-dark)] flex-shrink-0 pt-0.5">
                                {{ column.header }}
                            </span>
                            <div class="text-[11px] text-right flex-1">
                                <BaseDynamicSlot
                                    v-if="resolveSlotName(column.template)"
                                    :name="resolveSlotName(column.template)!"
                                    :data="item"
                                    :slots="slots as any"
                                />
                                <template v-else-if="column.field">
                                    {{ getFieldValue(item, column.field) }}
                                </template>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Paginador móvil (fijo debajo, no scrollea) -->
                <div
                    v-if="paginator && totalRecords > 0"
                    class="flex items-center justify-between bg-white border border-slate-200 rounded-2xl px-3 py-2 mt-2 flex-shrink-0"
                >
                    <BaseButton
                        icon="pi pi-angle-left"
                        variant="secondary-light"
                        size="sm"
                        :disabled="first === 0"
                        @click="onPage({ first: Math.max(0, first - rows), rows })"
                    />
                    <span class="text-[10px] font-bold text-slate-600">
                        {{ first + 1 }} – {{ Math.min(first + rows, totalRecords) }} de {{ totalRecords }}
                    </span>
                        <select
                            :value="rows"
                            @change="onRowsChange"
                            class="text-[10px] font-bold border border-slate-300 rounded px-1 py-0.5 bg-white"
                        >
                            <option :value="10">10</option>
                            <option :value="20">20</option>
                            <option :value="50">50</option>
                        </select>
                    <BaseButton
                        icon="pi pi-angle-right"
                        variant="secondary-light"
                        size="sm"
                        :disabled="first + rows >= totalRecords"
                        @click="onPage({ first: first + rows, rows })"
                    />
                </div>
            </template>
        </div>

        <!-- Placeholder mientras se determina el viewport   -->
        <div
            v-else
            class="rounded-2xl border border-slate-200 bg-white px-4 py-8 text-center"
        >
            <p class="text-xs font-semibold text-slate-400">
                Cargando vista...
            </p>
        </div>
    </div>
</template>

<script setup lang="ts" generic="T extends Record<string, any>">
    import { ref, onMounted, onBeforeUnmount } from 'vue';
    import { useSlots } from 'vue';
    const slots = useSlots();

    type BaseSlots<T> = {
        header?: () => any;
    } & {
        [K in `body-${string}`]?: (props: { data: T }) => any;
    };

    interface TableColumn<T> {
        field?: (keyof T & string) | string;
        header: string;
        sortable?: boolean;
        template?: string;
        headerClass?: string;
        bodyClass?: string;
        class?: string;
        style?: string;
    }

    const props = withDefaults(defineProps<{
        value: T[];
        loading?: boolean;
        paginator?: boolean;
        rows?: number;
        totalRecords?: number;
        first?: number;
        sortField?: string;
        sortOrder?: number;
        columns: TableColumn<T>[];
        rowKey?: string;
        tableClass?: string;
    }>(), {
        loading: false,
        paginator: true,
        rows: 10,
        totalRecords: 0,
        first: 0,
        sortField: '',
        sortOrder: 1,
        rowKey: '',
        tableClass: '',
    });

    const emit = defineEmits<{
        (e: 'page', event: any): void;
        (e: 'sort', event: any): void;
    }>();

    // 3) Declaramos los slots con el mismo tipo
    defineSlots<BaseSlots<T>>();

    const onPage = (event: any) => emit('page', event);
    const onSort = (event: any) => emit('sort', event);

    const emitPage = (newFirst: number) => {
        emit('page', {
            first: newFirst,
            rows: props.rows,
            page: Math.floor(newFirst / props.rows),
            sortField: props.sortField,
            sortOrder: props.sortOrder,
        });
    };

    const onRowsChange = (event: Event) => {
        const newRows = Number((event.target as HTMLSelectElement).value);
        emit('page', {
            first: 0,
            rows: newRows,
            page: 0,
            sortField: props.sortField,
            sortOrder: props.sortOrder,
        });
    };

    // 4) Acceso tipado al campo con soporte para notación de puntos
    function getFieldValue(item: T, field?: string | keyof T): unknown {
        if (!field) return '';
        const fieldStr = String(field);
        if (fieldStr.includes('.')) {
            const keys = fieldStr.split('.');
            let result: any = item;
            for (const key of keys) {
                if (result == null) return '';
                result = result[key];
            }
            return result ?? '';
        }
        const value = item[field as keyof T];
        return value ?? '';
    }

    function resolveSlotName(template?: string): string | null {
        if (!template) return null;

        // 1. Nombre tal cual (ej. 'body-nit')
        if (slots[template]) return template;

        // 2. Con prefijo body- (ej. 'body-body-nit' → no, pero 'nit' → 'body-nit')
        const conPrefijo = `body-${template}`;
        if (slots[conPrefijo]) return conPrefijo;

        // 3. Sin prefijo (por si template viene como 'body-nit' y el slot es 'nit')
        if (template.startsWith('body-')) {
            const sinPrefijo = template.slice(5);
            if (slots[sinPrefijo]) return sinPrefijo;
        }

        return null;
    }

    // Detección reactiva del viewport
    const viewportReady = ref(false);
    const isDesktop = ref(false);
    let mediaQuery: MediaQueryList | null = null;

    const updateIsDesktop = (event: MediaQueryListEvent) => {
        isDesktop.value = !event.matches;
    };

    onMounted(() => {
        mediaQuery = window.matchMedia('(max-width: 960px)');
        isDesktop.value = !mediaQuery.matches;
        viewportReady.value = true;
        mediaQuery.addEventListener('change', updateIsDesktop);
    });

    onBeforeUnmount(() => {
        mediaQuery?.removeEventListener('change', updateIsDesktop);
    });
</script>
