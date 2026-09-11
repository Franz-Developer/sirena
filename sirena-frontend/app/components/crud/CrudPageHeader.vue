<!-- C:\sirena\sirena-frontend\app\components\crud\CrudPageHeader.vue -->
<template>
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div class="flex items-center gap-3">
            <div class="bg-[var(--primary-dark)] p-2.5 rounded-xl shadow-lg shadow-blue-900/20">
                <i :class="[icon, 'text-white text-xl']"></i>
            </div>
            <div>
                <h1 class="text-xl font-black text-slate-800 dark:text-white uppercase tracking-tight">{{ title }}</h1>
                <p class="text-slate-500 dark:text-slate-400 text-xs font-medium">{{ subtitle }}</p>
            </div>
        </div>
        <BaseButton
            v-if="showAction"
            :label="actionLabel"
            :icon="actionIcon"
            variant="primary"
            size="lg"
            @click="$emit('action')"
        />
    </div>
</template>

<script setup lang="ts">
    defineProps<{
        icon: string;
        title: string;
        subtitle?: string;
        showAction?: boolean;
        actionLabel?: string;
        actionIcon?: string;
    }>();

    defineEmits<{ action: [] }>();
</script>