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
        // Añadimos clases de focus visibles (outline, ring y offset)
        const base = 'inline-flex items-center justify-center gap-2 font-bold border-0 cursor-pointer transition-colors duration-150 disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2';

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
