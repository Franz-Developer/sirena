// C:\sirena\sirena-frontend\app\plugins\primevue-directives.ts
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple';
import FocusTrap from 'primevue/focustrap';
import StyleClass from 'primevue/styleclass';

/**
 * Registra las directivas de PrimeVue que NO se auto-registran
 * con el módulo @primevue/nuxt-module.
 *
 * Directivas registradas:
 *  - v-tooltip     → Tooltip (usado en CrudRowActions, BaseButton, etc.)
 *  - v-ripple      → Efecto ripple en botones
 *  - v-focustrap   → Focus trap en dialogs
 *  - v-styleclass  → Manipulación dinámica de clases
 */
export default defineNuxtPlugin((nuxtApp) => {
    nuxtApp.vueApp.directive('tooltip', Tooltip);
    nuxtApp.vueApp.directive('ripple', Ripple);
    nuxtApp.vueApp.directive('focustrap', FocusTrap);
    nuxtApp.vueApp.directive('styleclass', StyleClass);
});
