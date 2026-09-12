<!-- C:\sirena\sirena-frontend\app\layouts\default.vue -->
<template>
    <div class="flex flex-col h-screen bg-white dark:bg-[#0b1220] font-sans">
        <header class="h-16 bg-[var(--primary-dark)] flex items-center justify-between px-4 shadow-md z-30 border-b-4 border-[#ff9800]">
            <div class="flex items-center gap-3">
                <button
                    @click="toggleSidebar"
                    class="relative text-white hover:bg-white/10 p-2 rounded-md transition-all group"
                    :class="{ 'rotate-90': !isSidebarOpen }"
                >
                    <i class="pi pi-bars text-xl"></i>
                    <span class="absolute bottom-1.5 right-1.5 w-2 h-2 bg-slate-400 rounded-full"></span>
                </button>
                <span class="text-white font-black tracking-tighter text-lg">SIRENA</span>
            </div>

            <div class="flex items-center gap-5">
                <NuxtLink to="/principal" class="w-10 h-10 flex items-center justify-center rounded-full bg-white/10 text-white hover:bg-[#ff9800] transition-all">
                    <i class="pi pi-home"></i>
                </NuxtLink>

                <div class="text-right hidden md:block leading-none">
                    <p class="text-white text-[12px] font-black uppercase">{{ authStore.user?.login || 'Invitado' }}</p>
                    <p class="text-emerald-400 text-[10px] font-bold italic">En línea</p>
                </div>

                <button @click="openUserMenu" class="rounded-full ring-2 ring-transparent hover:ring-amber-400 transition-all">
                    <img :src="avatarUrl" class="w-10 h-10 rounded-full border-2 border-white/20 object-cover" />
                </button>

                <Popover v-if="showUserMenu" ref="userMenu" @hide="showUserMenu = false">
                    <BaseCard class="w-80 shadow-2xl border-slate-200 rounded-xl">
                        <div class="flex items-center gap-4 p-4 bg-gradient-to-r from-blue-50 to-slate-50 border-b border-slate-200">
                            <div class="relative">
                                <img :src="avatarUrl" class="w-14 h-14 rounded-full border-2 border-amber-500 object-cover" />
                                <span class="absolute bottom-0 right-0 w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full"></span>
                            </div>
                            <div class="flex flex-col">
                                <span class="text-sm font-black text-slate-800 uppercase tracking-tight">{{ authStore.user?.login }}</span>
                                <span class="text-[10px] text-emerald-600 font-bold flex items-center gap-1 mt-0.5">
                                    <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span> En línea
                                </span>
                            </div>
                        </div>

                        <div class="p-3 space-y-2">
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">NOMBRES</span>
                                <span class="text-[11px] font-semibold text-slate-700">{{ authStore.user?.trabajador_nombres || '-' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">AP. PATERNO</span>
                                <span class="text-[11px] font-semibold text-slate-700">{{ authStore.user?.trabajador_paterno || '-' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">AP. MATERNO</span>
                                <span class="text-[11px] font-semibold text-slate-700">{{ authStore.user?.trabajador_materno || '-' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">EMPRESA</span>
                                <span class="text-[11px] font-semibold text-slate-700">{{ authStore.user?.empresa_nombre || 'Sin empresa' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">SUCURSAL</span>
                                <span class="text-[11px] font-semibold text-slate-700">{{ authStore.user?.sucursal_nombre || 'Sin sucursal' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">CARGO</span>
                                <span class="text-[11px] font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full">{{ authStore.user?.cargo_nombre || '-' }}</span>
                            </div>
                            <div class="flex justify-between items-center py-1.5 border-b border-slate-100 last:border-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">ROL</span>
                                <span class="text-[11px] font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full">{{ authStore.user?.rol_nombre || '-' }}</span>
                            </div>
                        </div>

                        <div class="flex justify-between px-4 py-2 border-t border-slate-200 text-[9px] text-slate-500">
                            <span><i class="pi pi-sign-in text-emerald-500 mr-1"></i>{{ loginTime }}</span>
                            <span><i class="pi pi-clock text-amber-500 mr-1"></i>{{ expirationTime }}</span>
                        </div>

                        <div class="p-2 border-t border-slate-100 dark:border-slate-800">
                            <button @click="showPasswordModal = true" class="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-amber-50 dark:hover:bg-amber-900/20 text-slate-600 dark:text-slate-300 transition-colors group" >
                                <div class="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-amber-500 group-hover:text-white transition-all">
                                    <i class="pi pi-lock text-xs"></i>
                                </div>
                                <span class="text-[11px] font-bold uppercase tracking-wider">Cambiar Contraseña</span>
                            </button>
                        </div>

                        <button @click="handleLogout"
                            class="w-full flex items-center gap-3 p-4 bg-slate-50 hover:bg-red-50 transition-colors border-t border-slate-200 group">
                            <div class="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm group-hover:bg-red-500 group-hover:text-white transition-all flex-shrink-0">
                                <i class="pi pi-power-off text-xs"></i>
                            </div>
                            <span class="text-[11px] font-bold text-red-500 uppercase tracking-widest">Cerrar sesión</span>
                        </button>
                    </BaseCard>
                </Popover>
            </div>
        </header>

        <div class="flex flex-1 overflow-hidden">
            <!-- Overlay: solo en móvil y solo cuando el sidebar está abierto -->
            <div
                v-if="isMobile && isSidebarOpen"
                class="fixed inset-0 bg-black/60 z-40 md:hidden"
                @click="isSidebarOpen = false"
            ></div>

            <!-- Sidebar -->
            <aside
                :class="[
                    'bg-slate-100 border-r transition-all duration-300 h-full z-50',
                    'fixed md:relative md:translate-x-0 top-0 left-0',
                    isSidebarOpen
                        ? 'translate-x-0 w-72'
                        : '-translate-x-full md:translate-x-0 md:w-0 md:opacity-0 md:invisible'
                ]"
            >
                <SidebarMenu />
            </aside>

            <main class="flex-1 overflow-y-auto bg-slate-50 flex flex-col">
                <div class="p-2 md:p-4 flex-1"><div class="card min-h-full"><slot /></div></div>
                <footer class="px-6 py-4 border-t bg-white flex justify-between items-center">
                    <div class="flex items-center gap-2">
                        <span class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
                        <span class="text-[10px] font-bold text-slate-500 uppercase">Sucursal: S-00{{ authStore.user?.sucursal_id }}</span>
                    </div>
                    <p class="text-slate-400 text-[10px] font-black uppercase">{{ config.public.appName }} v{{ config.public.appVersion }} • {{ new Date().getFullYear() }}</p>
                </footer>
            </main>
        </div>

        <Dialog v-if="showPasswordModal" v-model:visible="showPasswordModal" :modal="true" :draggable="false" :closable="!isUpdatingPassword" class="w-[90vw] md:w-[450px]">
            <template #header>
                <div class="flex items-center gap-3">
                    <div class="bg-[var(--primary-dark)] p-2 rounded-lg shadow-md"><i class="pi pi-lock text-white text-lg"></i></div>
                    <div>
                        <h3 class="text-sm font-black text-slate-800 uppercase tracking-tight">Actualizar Contraseña</h3>
                        <p class="text-[10px] text-slate-500">Asegura tu cuenta con una clave robusta</p>
                    </div>
                </div>
            </template>

            <div class="flex flex-col gap-y-4 pt-2">
                <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
                    <div class="flex justify-between items-center mb-4 text-blue-700 uppercase font-black text-[10px]">
                        <span>Seguridad de la Cuenta</span>
                    </div>
                    <div class="flex flex-col gap-5">
                        <div class="flex flex-col gap-1.5">
                            <label class="block text-[11px] font-bold text-slate-600 uppercase">Contraseña Actual <span class="text-red-500">*</span></label>
                            <BaseInput v-model="currentPassword" type="password" placeholder="Ingrese su clave actual" size="sm" />
                        </div>
                        <div class="border-t border-dashed border-slate-100 my-1"></div>
                        <div class="flex flex-col gap-1.5">
                            <label class="block text-[11px] font-bold text-slate-600 uppercase">Nueva Contraseña <span class="text-red-500">*</span></label>
                            <Password v-model="newPassword" toggleMask class="w-full" inputClass="w-full p-2.5 border !rounded-lg text-sm" placeholder="Nueva clave" />
                        </div>
                        <div class="flex flex-col gap-1.5">
                            <label class="block text-[11px] font-bold text-slate-600 uppercase">Confirmar Contraseña <span class="text-red-500">*</span></label>
                            <Password v-model="confirmPassword" toggleMask :feedback="false" class="w-full" inputClass="w-full p-2.5 border !rounded-lg text-sm" placeholder="Repita su nueva clave" />
                        </div>
                        <div v-if="passwordError" class="mt-4 flex items-start gap-3 text-red-600 bg-red-50 p-3 rounded-xl border border-red-200 animate-pulse">
                            <i class="pi pi-exclamation-triangle mt-1 text-sm"></i>
                            <div class="flex flex-col"><span class="text-[10px] font-black uppercase">Error de Seguridad</span><p class="text-[11px] font-semibold">{{ passwordError }}</p></div>
                        </div>
                    </div>
                </div>
            </div>
            <template #footer>
                <div class="flex justify-end gap-3 pb-2 pt-4">
                    <BaseButton label="Cancelar" icon="pi pi-times" :loading="isUpdatingPassword" variant="danger" @click="closePasswordModal" />
                    <BaseButton label="Guardar Cambios" icon="pi pi-check" :loading="isUpdatingPassword" variant="primary" @click="handlePasswordUpdate" />
                </div>
            </template>
        </Dialog>
    </div>
</template>

<script setup lang="ts">
    import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue';
    import { useRoute } from 'vue-router';
    import { useNotify } from '~/composables/useNotify';

    const { notify } = useNotify();
    const route = useRoute();
    const authStore = useAuthStore();
    const { $api } = useNuxtApp() as any;
    const config = useRuntimeConfig();

    const userMenu = ref();
    const showUserMenu = ref(false);
    const isSidebarOpen = ref<boolean>(true);
    const isMobile = ref<boolean>(false);
    const showPasswordModal = ref<boolean>(false);
    const currentPassword = ref<string>('');
    const newPassword = ref<string>('');
    const confirmPassword = ref<string>('');
    const passwordError = ref<string | null>(null);
    const isUpdatingPassword = ref<boolean>(false);

    const avatarUrl = computed(() => {
        const avatar = authStore.user?.avatar;
        if (!avatar) return `${config.public.apiBase}/avatars/0.png`;
        return avatar.toString().startsWith('http') ? avatar : `${config.public.apiBase}/avatars/${avatar}`;
    });

    const tokenData = computed(() => {
        const token = authStore.token;
        if (!token || typeof token !== 'string') return null;
        try {
            const parts = token.split('.');
            if (parts.length !== 3) return null;

            const base64Url = parts[1];
            if (!base64Url) return null;

            const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
            return JSON.parse(window.atob(base64));
        } catch (e) {
            return null;
        }
    });

    const formatUnixTime = (unixTimestamp?: number): string => {
        if (!unixTimestamp) return '--:--';
        const date = new Date(unixTimestamp * 1000);
        return new Intl.DateTimeFormat('es-ES', {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
        }).format(date);
    };

    const loginTime = computed(() => formatUnixTime(tokenData.value?.iat));
    const expirationTime = computed(() => formatUnixTime(tokenData.value?.exp));

    const openUserMenu = (event: Event): void => {
        showUserMenu.value = true;
        nextTick(() => {
            userMenu.value?.toggle(event);
        });
    };

    const toggleSidebar = (): void => {
        isSidebarOpen.value = !isSidebarOpen.value;
    };

    watch(showPasswordModal, (opened: boolean) => {
        if (opened) {
            currentPassword.value = '';
            newPassword.value = '';
            confirmPassword.value = '';
            passwordError.value = '';
        }
    });

    const handlePasswordUpdate = async (): Promise<void> => {
        isUpdatingPassword.value = true;
        passwordError.value = null;

        if (!authStore.user?.usuario_id) {
            notify('warn', 'Acceso Denegado', 'No se encontró usuario activo para actualizar la contraseña');
            isUpdatingPassword.value = false;
            return;
        }

        try {
            const userId = authStore.user.usuario_id;
            await $api(`/usuarios/${userId}/password`, {
                method: 'PATCH',
                body: {
                    contrasenaActual: currentPassword.value,
                    nuevaContrasena: newPassword.value,
                    confirmarContrasena: confirmPassword.value,
                },
            });

            notify('success', 'Éxito', 'Contraseña actualizada correctamente');
            closePasswordModal();
        } catch (e: any) {
            const mensajeServidor = e?.data?.message || 'Error inesperado';
            passwordError.value = Array.isArray(mensajeServidor)
                ? mensajeServidor.join(', ')
                : mensajeServidor;
            notify('error', 'Error de Actualización', passwordError.value);
        } finally {
            isUpdatingPassword.value = false;
        }
    };

    // Detectar móvil vía matchMedia (más robusto que resize)
    let mediaQuery: MediaQueryList | null = null;

    const handleMediaChange = (e: MediaQueryListEvent | MediaQueryList): void => {
        isMobile.value = e.matches;
        isSidebarOpen.value = !e.matches;
    };

    onMounted(() => {
        mediaQuery = window.matchMedia('(max-width: 767px)');
        handleMediaChange(mediaQuery);
        mediaQuery.addEventListener('change', handleMediaChange);
    });

    onBeforeUnmount(() => {
        mediaQuery?.removeEventListener('change', handleMediaChange);
    });

    // Cerrar sidebar al navegar (solo en móvil)
    watch(() => route.path, () => {
        if (isMobile.value) {
            isSidebarOpen.value = false;
        }
    });

    const handleLogout = (): void => {
        showUserMenu.value = false;
        authStore.logout();
    };

    const closePasswordModal = (): void => {
        showPasswordModal.value = false;
        currentPassword.value = '';
        newPassword.value = '';
        confirmPassword.value = '';
        passwordError.value = '';
    };
</script>
