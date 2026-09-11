<!-- C:\sirena\sirena-frontend\app\components\base\BaseSearch.vue -->
<template>
    <div class="relative w-full">
        <!-- Icono de búsqueda a la izquierda -->
        <i class="pi pi-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xs pointer-events-none z-10"></i>

        <!-- Input -->
        <input
            type="text"
            :value="modelValue"
            :placeholder="placeholder"
            :disabled="disabled"
            class="w-full h-[38px] pl-9 pr-3 text-xs bg-white border border-[var(--border-color)] rounded-[var(--radius-std)] transition-all focus:outline-none focus:border-[var(--primary-color)] focus:ring-2 focus:ring-blue-100 disabled:bg-slate-50 disabled:text-slate-400"
            @input="onInput"
            @keydown.enter="onEnter"
        />

        <!-- Botón limpiar (solo si hay texto) -->
        <button
            v-if="modelValue && showClear"
            type="button"
            class="absolute right-2 top-1/2 -translate-y-1/2 w-5 h-5 flex items-center justify-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors"
            @click="onClear"
            tabindex="-1"
        >
            <i class="pi pi-times text-[10px]"></i>
        </button>
    </div>
</template>

<script setup lang="ts">
    const props = withDefaults(defineProps<{
        modelValue?: string;
        placeholder?: string;
        disabled?: boolean;
        showClear?: boolean;
        debounce?: number;   // ms; 0 = sin debounce
    }>(), {
        modelValue: '',
        placeholder: 'Buscar...',
        disabled: false,
        showClear: true,
        debounce: 400,
    });

    const emit = defineEmits<{
        'update:modelValue': [value: string];
        search: [value: string];
        clear: [];
    }>();

    let timer: ReturnType<typeof setTimeout> | null = null;

    const onInput = (event: Event) => {
        const value = (event.target as HTMLInputElement).value;
        emit('update:modelValue', value);

        if (timer) clearTimeout(timer);
        if (props.debounce > 0) {
            timer = setTimeout(() => emit('search', value), props.debounce);
        } else {
            emit('search', value);
        }
    };

    const onEnter = () => {
        if (timer) clearTimeout(timer);
        emit('search', props.modelValue);
    };

    const onClear = () => {
        emit('update:modelValue', '');
        emit('search', '');
        emit('clear');
    };
</script>