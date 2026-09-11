<!-- C:\sirena\sirena-frontend\app\components\charts\ChartCanvas.vue -->
<template>
    <div class="relative" :style="{ height: height + 'px' }">
        <canvas ref="canvasRef" />
    </div>
</template>

<script setup>
    const props = defineProps({
        type: { type: String, default: 'bar' },       // 'bar' | 'line' | 'pie' | 'doughnut' | ...
        data: { type: Object, required: true },       // { labels: [], datasets: [] }
        options: { type: Object, default: () => ({}) },
        height: { type: Number, default: 300 },
    });

    const canvasRef = ref(null);
    const { loadChart } = useChart();
    let chartInstance = null;

    onMounted(async () => {
        const Chart = await loadChart();
        if (!canvasRef.value) return;

        chartInstance = new Chart(canvasRef.value, {
            type: props.type,
            data: props.data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                ...props.options,
            },
        });
    });

    onBeforeUnmount(() => {
        chartInstance?.destroy();
        chartInstance = null;
    });

    watch(() => props.data, (newData) => {
        if (!chartInstance) return;
        chartInstance.data = newData;
        chartInstance.update();
    }, { deep: true });
</script>
