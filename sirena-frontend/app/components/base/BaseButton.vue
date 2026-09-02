<template>
    <Button 
        v-bind="$attrs"
        :class="buttonClass"
        :loading="loading"
        :disabled="loading || disabled"
    >
        <slot />
    </Button>
</template>

<script setup>
    import { computed } from 'vue';

    const props = defineProps({
        variant: {
            type: String,
            default: 'primary',
            validator: (value) => ['primary', 'secondary', 'danger', 'cancel', 'success', 'warning', 'ghost', 'ghost-orange', 'ghost-green', 'ghost-red', 'secondary-light', 'menu-amber', 'menu-danger'].includes(value)
        },
        loading: {
            type: Boolean,
            default: false
        },
        disabled: {
            type: Boolean,
            default: false
        },
        size: {
            type: String,
            default: 'default',
            validator: (value) => ['sm', 'default', 'lg'].includes(value)
        }
    });

    const buttonClass = computed(() => {
        const base = 'font-bold border-none transition-all active:scale-[0.97]';
        const sizeClasses = {
             sm: 'text-[10px] px-2 py-1 rounded-lg min-h-[28px]',
            default: 'text-xs px-4 py-2 rounded-[var(--radius-std)]',
            lg: 'text-sm px-6 py-3 rounded-[var(--radius-std)]'
        };

        const variantClasses = {
            primary: 'bg-[var(--primary-dark)] text-white hover:bg-[var(--primary-dark-hover)] shadow-sm hover:shadow-md',
            secondary: 'bg-[var(--secondary-color)] text-white hover:bg-[var(--secondary-hover)] shadow-sm hover:shadow-md',
            danger: 'bg-[var(--danger-color)] text-white hover:bg-[var(--danger-hover)] shadow-sm hover:shadow-md',
            cancel: 'bg-[var(--bg-disabled)] text-slate-700 border border-[var(--border-color)] hover:bg-slate-200',
            success: 'bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm hover:shadow-md',
            warning: 'bg-amber-600 text-white hover:bg-amber-700 shadow-sm hover:shadow-md',
            ghost: 'bg-transparent hover:bg-slate-100 text-slate-600',
            'ghost-orange': 'bg-transparent hover:bg-orange-50 text-orange-500',
            'ghost-green': 'bg-transparent hover:bg-emerald-50 text-emerald-600',
            'ghost-red': 'bg-transparent hover:bg-red-50 text-red-500',
            'secondary-light': 'bg-slate-500 text-white hover:bg-slate-800 border-transparent',
            'ghost-sky': 'bg-transparent text-sky-600 hover:bg-sky-50 dark:text-sky-400 dark:hover:bg-sky-900/20',
            'ghost-red': 'bg-transparent text-red-600 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/20',
            'menu-amber': 'bg-transparent text-slate-600 dark:text-slate-300 hover:bg-amber-50 dark:hover:bg-amber-900/20 hover:text-amber-600 transition-colors',
            'menu-danger': 'bg-transparent text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors',
        };

        return [
            base,
            sizeClasses[props.size] || sizeClasses.default,
            variantClasses[props.variant] || variantClasses.primary
        ];
    });
</script>
