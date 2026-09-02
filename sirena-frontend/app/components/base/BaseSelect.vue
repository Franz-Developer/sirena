<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label v-if="label" class="text-[9px] font-bold text-slate-500 uppercase tracking-wider">{{ label }}</label>
        <Select 
            v-bind="$attrs"
            :class="[
                'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] transition-all',
                'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
                size === 'sm' ? 'min-h-[38px] text-xs' : 'min-h-[40px] text-sm'
            ]"
            panelClass="min-w-[320px] max-w-[600px]"
            :placeholder="placeholder"
            :disabled="disabled"
            :options="options"
            :optionLabel="optionLabel"
            :optionValue="optionValue"
            :modelValue="modelValue"
            @update:modelValue="onUpdate"
        />
        <small v-if="error" class="text-red-500 font-medium text-[10px]">{{ error }}</small>
    </div>
</template>

<script setup>
    const props = defineProps({
        label: { type: String, default: '' },
        placeholder: { type: String, default: 'Seleccionar...' },
        size: { type: String, default: 'sm' },
        disabled: { type: Boolean, default: false },
        error: { type: String, default: '' },
        options: { type: Array, required: true },
        optionLabel: { type: String, default: 'label' },
        optionValue: { type: String, default: 'value' },
        modelValue: { type: [String, Number, Boolean, Object], default: null }
    });

    const emit = defineEmits(['update:modelValue']);

    const onUpdate = (value) => {
        emit('update:modelValue', value);
    };
</script>

<style scoped>
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
</style>
