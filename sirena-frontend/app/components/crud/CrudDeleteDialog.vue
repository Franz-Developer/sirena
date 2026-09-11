<!-- C:\sirena\sirena-frontend\app\components\crud\CrudDeleteDialog.vue -->
<template>
    <Dialog
        v-model:visible="visible"
        :style="{ width: '480px' }"
        :modal="true"
        :draggable="false"
        :showHeader="false"
        :pt="{
            root: { class: '!p-0' },
            content: { class: '!p-0' },
        }"
    >
        <!-- Header personalizado -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h3 class="text-base font-bold text-slate-700 uppercase tracking-wide">
                {{ title }}
            </h3>
            <button
                type="button"
                class="ripple-btn w-8 h-8 flex items-center justify-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                @click="visible = false"
            >
                <i class="pi pi-times text-sm"></i>
            </button>
        </div>

        <!-- Body -->
        <div class="flex items-start gap-4 px-6 py-6">
            <div class="flex-1 pt-1">
                <p class="text-base font-bold text-slate-800 leading-tight">
                    ¿Eliminar permanentemente?
                </p>
                <p class="text-sm text-slate-600 mt-2 leading-relaxed">
                    Se eliminará <b class="text-slate-800">{{ itemName }}</b> de forma definitiva.
                    Esta acción no se puede deshacer.
                </p>
            </div>
        </div>

        <!-- Footer -->
        <template #footer>
            <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-100 min-h-[72px]">
                <BaseButton
                    label="Cancelar"
                    icon="pi pi-times"
                    variant="dialog-cancel"
                    @click="visible = false"
                />
                <BaseButton
                    label="Sí, eliminar"
                    icon="pi pi-trash"
                    variant="danger"
                    class="!px-4 !py-2"
                    @click="$emit('confirm')"
                />
            </div>
        </template>
    </Dialog>
</template>

<script setup lang="ts">
    const props = defineProps<{
        visible: boolean;
        title: string;
        itemName: string;
    }>();

    const emit = defineEmits<{
        'update:visible': [value: boolean];
        confirm: [];
    }>();

    const visible = computed({
        get: () => props.visible,
        set: (val) => emit('update:visible', val),
    });
</script>
