<!-- C:\sirena\sirena-frontend\app\pages\index.vue -->
<template>
    <main class="min-h-screen flex items-center justify-center bg-slate-100 p-4">
        <div class="w-full max-w-md">
            <BaseCard class="p-8">
                <div class="text-center mb-8">
                    <h1 class="text-3xl font-black text-slate-800 tracking-tighter">{{ config.public.appName }}</h1>
                    <p class="text-xs font-medium text-slate-400 tracking-[0.2em] mt-1">Versión {{ config.public.appVersion }}</p>
                </div>

                <form @submit.prevent="login" class="space-y-4">
                    <BaseInput v-model="username" label="Usuario" placeholder="Ingrese su usuario" icon="pi pi-user" required />
                    <BaseInput v-model="password" label="Contraseña" placeholder="Ingrese su contraseña" icon="pi pi-lock" type="password" required />
                    <div class="pt-2">
                        <BaseButton type="submit" variant="primary" size="default" icon="pi pi-sign-in" :loading="loading" :disabled="loading" class="w-full" label="Ingresar" />
                    </div>
                </form>

                <Transition name="fade">
                    <div v-if="error" class="mt-4 flex items-center gap-3 p-3 bg-red-50 border-l-4 border-red-500 rounded-r-xl">
                        <i class="pi pi-exclamation-circle text-red-500"></i>
                        <p class="text-xs font-semibold text-red-700">{{ error }}</p>
                    </div>
                </Transition>
            </BaseCard>

            <p class="text-center mt-6 text-slate-400 text-xs font-medium">&copy; {{ new Date().getFullYear() }} {{ config.public.appName }} v{{ config.public.appVersion }} | Soporte Técnico</p>
        </div>
    </main>
</template>

<script setup>
    const config = useRuntimeConfig();
    const router = useRouter();
    const authStore = useAuthStore();
    const username = ref('');
    const password = ref('');
    const error = ref('');
    const loading = ref(false);

    definePageMeta({ layout: false });
    useHead({ title: `${config.public.appName} | Login` });

    const login = async () => {
        error.value = '';
        loading.value = true;

        const tInicio = performance.now();
        sessionStorage.setItem('login_total_start', String(tInicio));
        performance.mark('login:inicio');
        console.log('%cIniciando proceso de Login...', 'color: #3b82f6; font-weight: bold');

        try {
            performance.mark('login:api:inicio');
            const tApiInicio = performance.now();
            const tPeticionInicio = performance.now();
            const response = await $fetch(`${config.public.apiBase}/auth/validar`, {
                method: 'POST',
                body: {
                    username: username.value.toUpperCase(),
                    password: password.value
                },
            });
            const tPeticionFin = performance.now();
            console.log(`API: ${(tPeticionFin - tPeticionInicio).toFixed(2)}ms`);

            const tApiFin = performance.now();
            performance.mark('login:api:fin');
            performance.measure('login:api', 'login:api:inicio', 'login:api:fin');

            const serverMs = response?._timing?.server_ms ?? null;
            const apiTotal = tApiFin - tApiInicio;
            if (serverMs !== null) {
                console.log(`API total: ${apiTotal.toFixed(2)}ms  (Servidor: ${serverMs.toFixed(2)}ms | Red: ${(apiTotal - serverMs).toFixed(2)}ms)`);
            } else {
                console.log(`API: ${apiTotal.toFixed(2)}ms`);
            }

            performance.mark('login:store:inicio');
            const tStoreInicio = performance.now();
            authStore.startSession(response.usuario, response.token, response.menu, response.permisos);
            const tStoreFin = performance.now();
            performance.mark('login:store:fin');
            performance.measure('login:store', 'login:store:inicio', 'login:store:fin');
            console.log(`Store/Persistencia: ${(tStoreFin - tStoreInicio).toFixed(2)}ms`);

            performance.mark('login:nav:inicio');
            const tNavInicio = performance.now();
            sessionStorage.setItem('login_start', String(tNavInicio));
            console.log('%cRedireccionando a /principal...', 'color: #eab308');
            await navigateTo('/principal');

            const tNavFin = performance.now();
            performance.mark('login:nav:fin');
            performance.measure('login:nav', 'login:nav:inicio', 'login:nav:fin');
            console.log(`Navegación: ${(tNavFin - tNavInicio).toFixed(2)}ms`);

            performance.mark('login:fin');
            performance.measure('login:total', 'login:inicio', 'login:fin');
            const tTotal = performance.now();
            console.log(`%cTOTAL FRONTEND (hasta cambio de ruta): ${(tTotal - tInicio).toFixed(2)}ms`, 'background: #22c55e; color: white; padding: 2px 5px; border-radius: 4px');

            const measures = performance.getEntriesByType('measure').filter(m => m.name.startsWith('login:'));
            console.table(measures.map(m => ({ fase: m.name.replace('login:', ''), ms: Number(m.duration.toFixed(2)) })));

        } catch (err) {
            error.value = err?.data?.message || 'Error de conexión con el servidor';
            console.error('Error en Login:', err);
            sessionStorage.removeItem('login_start');
            sessionStorage.removeItem('login_total_start');
        } finally {
            loading.value = false;
        }
    };
</script>