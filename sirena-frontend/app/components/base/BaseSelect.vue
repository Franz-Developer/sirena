<!-- C:\sirena\sirena-frontend\app\components\base\BaseSelect.vue -->
<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label
            v-if="label"
            class="text-[9px] font-bold text-slate-500 uppercase tracking-wider"
        >
            {{ label }}
        </label>

        <Select
            v-bind="$attrs"
            :class="[selectClasses, 'base-select']"
            :panelClass="panelClass"
            :placeholder="placeholder"
            :disabled="disabled"
            :options="options"
            :optionLabel="optionLabel"
            :optionValue="optionValue"
            :optionDisabled="optionDisabled"
            :filter="filter"
            :filterPlaceholder="filterPlaceholder"
            :showClear="showClear"
            :modelValue="modelValue"
            @update:modelValue="onUpdate"
        />

        <small v-if="error" class="text-red-500 font-medium text-[10px]">
            {{ error }}
        </small>
    </div>
</template>

<script setup lang="ts">
    const props = withDefaults(defineProps<{
        label?: string;
        placeholder?: string;
        size?: 'sm' | 'default';
        disabled?: boolean;
        error?: string;
        options: any[];
        optionLabel?: string;
        optionValue?: string;
        optionDisabled?: string;
        modelValue?: string | number | boolean | object | null | any[];
        panelClass?: string;
        filter?: boolean;
        filterPlaceholder?: string;
        showClear?: boolean;
    }>(), {
        label: '',
        placeholder: 'Seleccionar...',
        size: 'sm',
        disabled: false,
        error: '',
        optionLabel: 'label',
        optionValue: 'value',
        optionDisabled: undefined,
        modelValue: null,
        panelClass: 'min-w-[320px] max-w-[600px]',
        filter: false,
        filterPlaceholder: 'Buscar...',
        showClear: false,
    });

    const emit = defineEmits<{
        'update:modelValue': [value: any];
    }>();

    // ⬇️ 3. Computed para las clases del trigger (más limpio que en el template)
    const selectClasses = computed(() => [
        'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] transition-all',
        'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
        props.size === 'sm' ? 'min-h-[38px] h-[38px] !text-xs !py-0 flex items-center' : 'min-h-[40px] text-sm',
    ]);

    const onUpdate = (value: any) => {
        emit('update:modelValue', value);
    };
</script>

<style scoped>
    /* Forzar que el texto seleccionado dentro del Select use text-xs (12px) y se alinee */
    :deep(.p-select-label) {
        font-size: 0.75rem !important;
        line-height: 1rem !important;
        padding-top: 0 !important;
        padding-bottom: 0 !important;
    }

    /* Forzar el tamaño de las opciones del desplegable */
    :deep(.p-select-option) {
        font-size: 0.75rem !important;
    }
</style>
