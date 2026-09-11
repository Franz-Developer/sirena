// C:\sirena\sirena-frontend\app\composables\useChart.ts
let chartRegistered = false;

export const useChart = () => {
    const loadChart = async () => {
        const { Chart, registerables } = await import('chart.js');
        if (!chartRegistered) {
            Chart.register(...registerables);
            chartRegistered = true;
        }
        return Chart;
    };
    return { loadChart };
};
