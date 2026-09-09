// C:\sirena\sirena-frontend\app\plugins\chartjs.client.ts
import { Chart, registerables } from 'chart.js'

export default defineNuxtPlugin(() => {
    Chart.register(...registerables)
})
