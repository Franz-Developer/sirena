<!-- C:\sirena\sirena-frontend\app\components\crud\CrudDeleteDialog.vue -->
<template>
    <Dialog
        v-model:visible="visible"
        :style="{ width: '450px' }"
        :header="title"
        :modal="true"
    >
        <div class="flex items-center gap-3">
            <i class="pi pi-exclamation-triangle text-red-500 text-3xl" />
            <span>¿Eliminar permanentemente a <b>{{ itemName }}</b>?</span>
        </div>
        <template #footer>
            <BaseButton
                label="NO"
                variant="secondary-light"
                @click="visible = false"
            />
            <BaseButton
                label="SÍ, ELIMINAR"
                variant="danger"
                @click="$emit('confirm')"
            />
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