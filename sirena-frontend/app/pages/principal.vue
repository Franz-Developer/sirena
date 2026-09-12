<!-- C:\sirena\sirena-frontend\app\pages\principal.vue -->
<template>
    <div class="min-h-screen bg-slate-100 dark:bg-slate-900 flex flex-col transition-colors duration-300">
        <main class="flex-1 p-6 md:p-12">
            <div class="max-w-5xl mx-auto space-y-8">
                <div v-if="authStore.user" class="border-b border-slate-300 dark:border-slate-700 pb-6">
                    <h1 class="text-3xl font-black text-slate-800 dark:text-white tracking-tight">Bienvenido, {{ authStore.user.personaNombres }} {{ authStore.user.personaApellidoPaterno }}</h1>
                    <div class="flex flex-wrap items-center gap-4 mt-2">
                        <div class="flex items-center gap-2 bg-blue-50 dark:bg-blue-900/30 px-3 py-1 rounded-full border border-blue-200 dark:border-blue-700">
                            <i class="pi pi-shield text-blue-600 text-sm"></i>
                            <span class="text-xs font-bold text-blue-800 dark:text-blue-300 uppercase tracking-wider">{{ authStore.user.rol }} ({{ authStore.user.rolCodigo }})</span>
                        </div>
                        <p class="text-sm font-medium text-slate-600 dark:text-slate-400 flex items-center gap-1"><i class="pi pi-id-card"></i> Documento: {{ authStore.user.personaDNI }}</p>
                        <p class="text-sm font-medium text-slate-600 dark:text-slate-400 flex items-center gap-1"><i class="pi pi-building"></i> {{ authStore.user.empresaNombre }}</p>
                    </div>
                </div>
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    <BaseCard class="lg:col-span-2 overflow-hidden">
                        <div class="h-24 bg-gradient-to-r from-slate-800 to-slate-700 flex items-center px-8 relative overflow-hidden">
                            <h2 class="text-white text-xl font-bold flex items-center gap-2"><i class="pi pi-desktop"></i> Panel de Control PRISMA</h2>
                        </div>
                        <div class="p-6 bg-white dark:bg-slate-800">
                            <p class="text-slate-700 dark:text-slate-300 leading-relaxed text-lg">Has iniciado sesión como <span class="font-bold text-blue-600">{{ authStore.user?.login }}</span>. Actualmente te encuentras en la sucursal: <span class="px-2 py-1 bg-slate-100 dark:bg-slate-700 rounded font-bold">{{ authStore.user?.sucursalNombre }}</span>.</p>
                        </div>
                    </BaseCard>
                    <BaseCard>
                        <div class="p-6 bg-white dark:bg-slate-800">
                            <h3 class="text-lg font-bold flex items-center gap-2 text-slate-800 dark:text-white mb-4"><i class="pi pi-server text-blue-600"></i> Info de Sesión</h3>
                            <ul class="space-y-4">
                                <li class="flex justify-between items-center border-b border-slate-200 dark:border-slate-700 pb-2">
                                    <span class="text-slate-500 dark:text-slate-400 text-[10px] font-bold uppercase">Cod. Sucursal</span>
                                    <span class="font-bold text-slate-800 dark:text-slate-200">{{ authStore.user?.sucursalCodigo }}</span>
                                </li>
                                <li class="flex justify-between items-center pt-1">
                                    <span class="text-slate-500 dark:text-slate-400 text-[10px] font-bold uppercase">Estado</span>
                                    <Tag severity="success" value="CONECTADO" class="!text-[9px]" rounded />
                                </li>
                            </ul>
                        </div>
                    </BaseCard>
                </div>
            </div>
        </main>
    </div>
</template>

<script setup>
    import { useAuthStore } from '@/stores/auth';

    const authStore = useAuthStore();

    onMounted(() => {
        const navStart = sessionStorage.getItem('login_start');

        if (navStart) {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const totalRender = performance.now() - Number(navStart);
                    console.log(
                        `%c🎨 /principal renderizado: ${totalRender.toFixed(2)}ms`,
                        'background: #8b5cf6; color: white; padding: 2px 6px; border-radius: 4px'
                    );

                    const totalStart = sessionStorage.getItem('login_total_start');
                    if (totalStart) {
                        const totalAbsoluto = performance.now() - Number(totalStart);
                        console.log(
                            `%c🏆 TOTAL LOGIN → RENDER: ${totalAbsoluto.toFixed(2)}ms`,
                            'background: #22c55e; color: white; padding: 3px 8px; border-radius: 4px; font-weight: bold'
                        );
                    }

                    sessionStorage.removeItem('login_start');
                    sessionStorage.removeItem('login_total_start');
                });
            });
        }
    });
</script>
