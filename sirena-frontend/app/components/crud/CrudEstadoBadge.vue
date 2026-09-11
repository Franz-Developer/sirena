<!-- C:\sirena\sirena-frontend\app\components\crud\CrudEstadoBadge.vue -->
<template>
    <Tag
        :value="estado"
        :severity="severity"
        class="text-[10px] font-bold uppercase px-2"
    />
</template>

<script setup lang="ts">
import { ESTADO_ACTIVO, ESTADO_HISTORICO, ESTADO_ANULADO } from '~/constants/estados.constant';

const props = defineProps<{
    estado: string;
    estadoId: number;
}>();

/**
 * Mapeo de estado → severidad del Tag de PrimeVue:
 *   ACTIVO     (1000) → success (verde)
 *   HISTORICO  (1002) → info    (azul)
 *   ANULADO    (1003) → danger  (rojo)
 */
const severity = computed(() => {
    switch (props.estadoId) {
        case ESTADO_ACTIVO:
            return 'success';
        case ESTADO_HISTORICO:
            return 'info';
        case ESTADO_ANULADO:
            return 'danger';
        default:
            return 'secondary';
    }
});
</script>
