// C:\rutas\rutas-frontend\app\pages\transporte\paradas.vue
<template>
    <div class="p-4">
        <div class="bg-white rounded-xl shadow-sm p-6">
            <h1 class="text-2xl font-bold mb-4">📍 Paradas</h1>
            <p class="text-slate-500 mb-4">Todas las paradas del sistema</p>

            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="bg-slate-100">
                        <th class="text-left p-2">Nombre</th>
                        <th class="text-left p-2">ID</th>
                        <th class="text-left p-2">Coordenadas</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="stop in stops" :key="stop.stopId" class="border-b">
                        <td class="p-2">{{ stop.stopName }}</td>
                        <td class="p-2 text-xs text-slate-500">{{ stop.stopId }}</td>
                        <td class="p-2 text-xs text-slate-500">{{ stop.stopLat }}, {{ stop.stopLon }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script setup>
    import { ref, onMounted } from 'vue'

    const stops = ref([])
    const { $api } = useNuxtApp()

    onMounted(async () => {
        try {
            stops.value = await $api('/stops')
            console.log('Paradas cargadas:', stops.value.length)
        } catch (error) {
            console.error('Error al cargar paradas:', error)
        }
    })
</script>