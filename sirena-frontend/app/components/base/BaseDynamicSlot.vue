<!-- C:\sirena\sirena-frontend\app\components\base\BaseDynamicSlot.vue -->
<script setup lang="ts" generic="T extends Record<string, any>">
    import { h, type VNode } from 'vue';

    const props = defineProps<{
        name: string;
        data: T;
        slots: Record<string, (props: { data: T }) => VNode[]>;
    }>();

    const renderSlot = (): VNode[] | null => {
        const slotFn = props.slots[props.name];
        if (!slotFn) return null;
        return slotFn({ data: props.data });
    };
</script>

<template>
    <component :is="renderSlot" v-if="props.slots[props.name]" />
</template>
