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
            :class="selectClasses"
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
    // ⬇️ 1. Props con tipado fuerte
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
        // ⬇️ 2. panelClass con valor por defecto pero PERSONALIZABLE desde fuera
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
        props.size === 'sm' ? 'min-h-[38px] text-xs' : 'min-h-[40px] text-sm',
    ]);

    const onUpdate = (value: any) => {
        emit('update:modelValue', value);
    };
</script>

<style scoped>
    /*
     * ⚠️ IMPORTANTE: `:deep()` aplica a elementos DENTRO del scope del componente.
     * El `.p-select-label` está dentro del trigger del Select (scope OK).
     * El panel flotante `.p-select-panel` está en `body` (fuera del scope) → NO
     * se puede estilizar con `:deep()` desde aquí. Para eso, usa `panelClass`
     * (que ya se aplica al panel) o estilos globales.
     */

    /* Permitir que el texto seleccionado se muestre completo */
    :deep(.p-select-label) {
        white-space: normal !important;
        overflow: visible !important;
        text-overflow: clip !important;
        word-break: break-word !important;
        line-height: 1.3 !important;
        padding-right: 2rem !important;
        min-height: 1.5rem !important;
    }

    /* El panel flotante se estiliza vía `panelClass`, no vía `:deep()` */
</style>
