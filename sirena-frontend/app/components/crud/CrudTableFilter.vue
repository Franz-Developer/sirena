<!-- C:\sirena\sirena-frontend\app\components\crud\CrudTableFilter.vue -->
<template>
    <div class="px-4 py-3 flex flex-col md:flex-row md:items-center md:justify-between gap-3 bg-white">
        <!-- Zona izquierda: filtros personalizados (slot) -->
        <div class="flex flex-1 flex-wrap items-center gap-3">
            <slot name="filters" />
        </div>

        <!-- Zona derecha: buscador + exactMatch (Responsivo en móviles y pantallas grandes) -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full md:w-auto">
            <slot name="actions" />

            <!-- Buscador (BaseSearch) -->
            <div v-if="showSearch" class="flex-1 w-full md:w-96">
                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                    Buscar
                </label>
                <BaseSearch
                    :model-value="searchValue"
                    :placeholder="searchPlaceholder"
                    :debounce="debounce"
                    class="w-full"
                    @update:model-value="$emit('update:searchValue', $event)"
                    @search="$emit('search')"
                />
            </div>

            <!-- Selector exactMatch -->
            <div v-if="showExactMatch && showSearch" class="w-full sm:w-40 shrink-0">
                <label class="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                    Coincidencia
                </label>
                <BaseSelect
                    :model-value="exactMatch"
                    :options="opcionesExactMatch"
                    option-label="label"
                    option-value="value"
                    placeholder="Tipo"
                    size="sm"
                    class="w-full"
                    @update:model-value="$emit('update:exactMatch', $event)"
                    @change="$emit('search')"
                />
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
    withDefaults(defineProps<{
        searchValue?: string;
        searchPlaceholder?: string;
        showSearch?: boolean;
        exactMatch?: number;
        showExactMatch?: boolean;
        debounce?: number;
    }>(), {
        searchValue: '',
        searchPlaceholder: 'Buscar...',
        showSearch: true,
        exactMatch: 0,
        showExactMatch: true,
        debounce: 400,
    });

    defineEmits<{
        'update:searchValue': [value: string];
        'update:exactMatch': [value: number];
        search: [];
    }>();

    const opcionesExactMatch = [
        { label: 'Parecido', value: 0 },
        { label: 'Exacto',   value: 1 },
    ];
</script>
