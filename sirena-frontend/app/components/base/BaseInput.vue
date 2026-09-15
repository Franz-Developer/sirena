<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label v-if="label" class="text-[9px] font-bold text-slate-500 uppercase tracking-wider">{{ label }}</label>
        <div class="relative">
            <i v-if="icon" :class="icon" class="absolute left-3 top-1/2 -translate-y-1/2 z-10 pointer-events-none text-slate-400 text-xs"></i>

            <!-- Input nativo para type=date -->
            <input
                v-if="type === 'date'"
                :value="modelValue"
                type="date"
                :disabled="disabled"
                :class="inputClasses"
                @input="onDateInput"
            />

            <!-- InputText de PrimeVue para el resto -->
            <InputText
                v-else
                v-bind="$attrs"
                :type="type"
                :model-value="String(modelValue ?? '')"
                :class="inputClasses"
                :placeholder="placeholder"
                :disabled="disabled"
                @update:model-value="onInput"
            />
        </div>
        <small v-if="error" class="text-red-500 font-medium text-[10px]">{{ error }}</small>
    </div>
</template>

<script setup lang="ts">
    import { computed } from 'vue';

    const props = withDefaults(defineProps<{
        label?: string;
        placeholder?: string;
        icon?: string;
        size?: 'sm' | 'default';
        disabled?: boolean;
        error?: string;
        type?: string;
        modelValue?: string | number;
    }>(), {
        label: '',
        placeholder: '',
        icon: '',
        size: 'sm',
        disabled: false,
        error: '',
        type: 'text',
        modelValue: '',
    });

    const emit = defineEmits<{
        'update:modelValue': [value: string | number];
    }>();

    const inputClasses = computed(() => [
        'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] px-3 py-2 transition-all',
        'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
        props.icon ? 'pl-9' : '',
        props.size === 'sm' ? 'h-[38px] !text-xs !py-0' : 'h-10 text-sm',
    ]);

    const onInput = (value: string | number | undefined) => {
        emit('update:modelValue', value ?? '');
    };

    const onDateInput = (event: Event) => {
        const target = event.target as HTMLInputElement;
        emit('update:modelValue', target.value);
    };
</script>
