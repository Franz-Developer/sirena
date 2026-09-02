<template>
    <div class="flex flex-col gap-0.5 w-full">
        <label v-if="label" class="text-[9px] font-bold text-slate-500 uppercase tracking-wider">{{ label }}</label>
        <div class="relative">
            <i v-if="icon" :class="icon" class="absolute left-3 top-1/2 -translate-y-1/2 z-10 pointer-events-none text-slate-400 text-xs"></i>
            <InputText 
                v-bind="$attrs"
                :class="[
                    'w-full bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] px-3 py-2 transition-all',
                    'focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100',
                    icon ? 'pl-9' : '',
                    size === 'sm' ? 'h-[38px] !text-xs !py-0' : 'h-10 text-sm'
                ]"
                :placeholder="placeholder"
                :disabled="disabled"
                @input="onInput"
            />
        </div>
        <small v-if="error" class="text-red-500 font-medium text-[10px]">{{ error }}</small>
    </div>
</template>

<script setup>
    const props = defineProps({
        label: { type: String, default: '' },
        placeholder: { type: String, default: '' },
        icon: { type: String, default: '' },
        size: { type: String, default: 'sm' },
        disabled: { type: Boolean, default: false },
        error: { type: String, default: '' },
        modelValue: { type: [String, Number], default: '' }
    });

    const emit = defineEmits(['update:modelValue']);

    const onInput = (event) => {
        emit('update:modelValue', event.target.value);
    };
</script>