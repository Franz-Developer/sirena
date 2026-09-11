// C:\sirena\sirena-frontend\nuxt.config.ts
import Aura from '@primeuix/themes/aura';

export default defineNuxtConfig({
    future: {
        compatibilityVersion: 4,
    },
    compatibilityDate: '2025-07-15',
    css: [
        'primeicons/primeicons.css',
        '@/assets/css/main.postcss'
    ],
    devtools: { enabled: false },
    components: [
        { path: '~/components', pathPrefix: false },
    ],
    routeRules: {
        '/**': { ssr: false }
    },
    app: {
        head: {
            title: 'SIRENA',
            meta: [{ name: 'description', content: 'Sistema de Control PRO' }],
            link: [{ rel: 'icon', type: 'image/x-icon', href: '/nave.ico' }]
        }
    },
    runtimeConfig: {
        public: {
            apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:3010',
            apiPredict: process.env.NUXT_PUBLIC_API_PREDICT || 'http://localhost:8000',
            appName: process.env.NUXT_PUBLIC_APP_NAME || 'SIRENA',
            appVersion: process.env.NUXT_PUBLIC_APP_VERSION || '1.0',
        },
    },
    devServer: {
        port: 3012,
    },
    modules: [
        '@pinia/nuxt',
        '@primevue/nuxt-module',
        '@nuxtjs/tailwindcss',
        '@vueuse/nuxt',
    ],
    primevue: {
        autoImport: true,
        options: {
            ripple: true,
            locale: {
                firstDayOfWeek: 1,
                dayNames: ["domingo","lunes","martes","miércoles","jueves","viernes","sábado"],
                dayNamesShort: ["dom","lun","mar","mié","jue","vie","sáb"],
                dayNamesMin: ["D","L","M","X","J","V","S"],
                monthNames: ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"],
                monthNamesShort: ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"],
                today: 'Hoy',
                clear: 'Limpiar',
                dateFormat: 'yy-mm-dd',
                weekHeader: 'Sm',
                pending: 'Pendiente',
                chooseYear: 'Elegir Año',
                chooseMonth: 'Elegir Mes',
                chooseDate: 'Elegir Fecha',
                prevDecade: 'Década Anterior',
                nextDecade: 'Década Siguiente',
                prevYear: 'Año Anterior',
                nextYear: 'Año Siguiente',
                prevMonth: 'Mes Anterior',
                nextMonth: 'Mes Siguiente',
                prevHour: 'Hora Anterior',
                nextHour: 'Hora Siguiente',
                prevMinute: 'Minuto Anterior',
                nextMinute: 'Minuto Siguiente',
                prevSecond: 'Segundo Anterior',
                nextSecond: 'Segundo Siguiente',
                am: 'am',
                pm: 'pm',
                fileSizeTypes: ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
            },
            theme: {
                preset: Aura,
                options: {
                    darkModeSelector: 'html.dark'
                }
            }
        }
    }
});
