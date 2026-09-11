<!-- C:\sirena\sirena-frontend\app\components\layout\SidebarMenu.vue -->
<template>
    <div class="modern-sidebar">
        <div class="menu-container custom-scrollbar pr-2">
            <PanelMenu
                :model="primeMenu"
                v-model:expandedKeys="expandedKeys"
                class="sismo-menu"
            >
                <template #item="{ item }">
                    <NuxtLink
                        v-if="item.to"
                        :to="item.to"
                        class="p-panelmenu-header-action"
                        exact-active-class="active-link"
                        @click="closeOnMobile"
                    >
                        <span :class="item.icon" class="p-menuitem-icon" />
                        <span class="p-menuitem-text">{{ item.label }}</span>
                    </NuxtLink>

                    <a v-else class="p-panelmenu-header-action">
                        <span :class="item.icon" class="p-menuitem-icon" />
                        <span class="p-menuitem-text">{{ item.label }}</span>
                        <i v-if="item.items" class="pi pi-angle-down ml-auto" />
                    </a>
                </template>
            </PanelMenu>
            <div class="h-20 w-full"></div>
        </div>
    </div>
</template>

<script setup>
    import { useAuthStore } from '@/stores/auth';
    import { computed, ref, onMounted, watch, onBeforeUnmount } from 'vue';
    import { useRoute } from 'vue-router';

    const authStore = useAuthStore();
    const route = useRoute();
    const expandedKeys = ref({});

    const formatMenu = (items) => {
        if (!items || !items.length) return undefined;

        return items.map(item => ({
            label: item.titulo || item.label,
            icon: item.icono || item.icon,
            to: item.url || item.to,
            key: item.titulo || item.label,
            items: formatMenu(item.items)
        }));
    };

    const primeMenu = computed(() => {
        return formatMenu(authStore.menu) || [];
    });

    const updateActiveMenu = () => {
        const findAndExpand = (items, targetPath) => {
            for (const item of items) {
                if (item.items) {
                    if (findAndExpand(item.items, targetPath)) {
                        expandedKeys.value[item.key] = true;
                        return true;
                    }
                }
                if (item.to === targetPath) {
                    return true;
                }
            }
            return false;
        };
        expandedKeys.value = {};
        findAndExpand(primeMenu.value, route.path);
    };

    const closeOnMobile = () => {
        if (window.innerWidth < 768) {
            window.dispatchEvent(new CustomEvent('close-sidebar'));
        }
    };

    const handleResize = () => {
        if (window.innerWidth >= 768) {
        }
    };

    watch(() => route.path, () => {
        updateActiveMenu();
        if (window.innerWidth < 768) {
            window.dispatchEvent(new CustomEvent('close-sidebar'));
        }
    }, { immediate: true });

    onMounted(() => {
        updateActiveMenu();
        window.addEventListener('resize', handleResize);
    });

    onBeforeUnmount(() => {
        window.removeEventListener('resize', handleResize);
    });
</script>

<style lang="scss" scoped>
    $azul-fuerte: #113f67;
    $azul-sub: #334155;
    $celeste-fondo: #e0f2fe;
    $celeste-border: #bae6fd;
    $hover-link: #1d4ed8;
    $naranja-sis: #ff9800;

    .modern-sidebar {
        height: 100vh;
        display: flex;
        flex-direction: column;
        padding: 1rem 0.75rem;
        background: linear-gradient(180deg, #e2e8f0 0%, #cbd5e1 100%);
        transition: background 0.3s ease;
        overflow: hidden;
    }

    .menu-container {
        flex: 1;
        overflow-y: auto;
        overflow-x: hidden;
        padding-right: 8px;
        padding-bottom: 5rem;

        &::-webkit-scrollbar {
            width: 6px;
        }
        &::-webkit-scrollbar-track {
            background: transparent;
            margin: 10px 0;
        }
        &::-webkit-scrollbar-thumb {
            background: rgba($azul-fuerte, 0.15);
            border-radius: 20px;
            transition: all 0.3s ease;

            &:hover {
                background: rgba($azul-fuerte, 0.4);
            }
        }

        scrollbar-width: thin;
        scrollbar-color: rgba($azul-fuerte, 0.15) transparent;
    }

    :deep(.p-panelmenu) {
        .p-panelmenu-panel {
            margin-bottom: 0.75rem;
            border: none !important;
        }

        .p-panelmenu-header-content {
            background: white !important;
            border: 1px solid $celeste-border !important;
            border-radius: 10px !important;
            transition: all 0.2s ease;
            &:hover { transform: translateX(4px); }
        }

        .p-panelmenu-header-action {
            display: flex;
            align-items: center;
            padding: 0.85rem 1rem !important;
            color: $azul-fuerte !important;
            font-weight: 800 !important;
            text-decoration: none;
            cursor: pointer;

            .p-menuitem-icon {
                color: #51adcf !important;
                margin-right: 0.5rem;
                font-size: 1.1rem;
            }
        }

        .p-panelmenu-content {
            background: $celeste-fondo !important;
            border: 1px dashed $celeste-border !important;
            border-radius: 0 0 10px 10px !important;
            padding: 0.3rem 0;

            .p-panelmenu-header-action {
                padding: 0.6rem 1.2rem !important;
                .p-menuitem-text {
                    color: $azul-sub !important;
                    font-weight: 600 !important;
                    font-size: 0.8rem;
                }
                &:hover { background: rgba(255,255,255, 0.5) !important; }
            }

            .router-link-active {
                background: white !important;
                border-left: 4px solid $naranja-sis !important;

                .p-menuitem-text { color: $hover-link !important; font-weight: 800 !important; }
                .p-menuitem-icon { color: $hover-link !important; }

                &::after {
                    content: "\e901";
                    font-family: 'primeicons';
                    margin-left: auto;
                    font-size: 0.7rem;
                    color: $naranja-sis;
                }
            }
        }
    }

    html.dark {
        .modern-sidebar {
            background: #0f172a !important;
        }

        .menu-container {
            &::-webkit-scrollbar-thumb {
                background: rgba(255, 255, 255, 0.1);
                &:hover {
                    background: rgba(255, 255, 255, 0.25);
                }
            }
            scrollbar-color: rgba(255, 255, 255, 0.1) transparent;
        }

        :deep(.p-panelmenu) {
            .p-panelmenu-header-content {
                background-color: #1e293b !important;
                border-color: #334155 !important;

                .p-panelmenu-header-action {
                    color: #f1f5f9 !important;
                    .p-menuitem-icon { color: #38bdf8 !important; }
                }
            }

            .p-panelmenu-content {
                background-color: #0b1220 !important;
                border-color: #334155 !important;

                .p-panelmenu-header-action {
                    color: #94a3b8 !important;
                    &:hover { background-color: #1e293b !important; }

                    &.router-link-active {
                        background-color: #1e293b !important;
                        .p-menuitem-text { color: #38bdf8 !important; }
                    }
                }
            }
        }
    }

    @media (max-width: 767px) {
        .modern-sidebar {
            padding: 0.75rem 0.5rem;
        }

        :deep(.p-panelmenu) {
            .p-panelmenu-header-action {
                padding: 0.65rem 0.75rem !important;
                font-size: 0.85rem;

                .p-menuitem-icon {
                    font-size: 0.95rem !important;
                }
            }

            .p-panelmenu-content {
                .p-panelmenu-header-action {
                    padding: 0.5rem 0.75rem !important;
                    .p-menuitem-text {
                        font-size: 0.75rem !important;
                    }
                }
            }
        }
    }
</style>