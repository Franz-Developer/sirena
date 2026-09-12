// C:\sirena\sirena-frontend\app\plugins\primevue.ts
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Select from 'primevue/select';
import Dialog from 'primevue/dialog';
import Tag from 'primevue/tag';
import Popover from 'primevue/popover';
import PanelMenu from 'primevue/panelmenu';
import Password from 'primevue/password';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Toast from 'primevue/toast';
import Badge from 'primevue/badge';

export default defineNuxtPlugin((nuxtApp) => {
    nuxtApp.vueApp.component('Button', Button);
    nuxtApp.vueApp.component('InputText', InputText);
    nuxtApp.vueApp.component('Select', Select);
    nuxtApp.vueApp.component('Dialog', Dialog);
    nuxtApp.vueApp.component('Tag', Tag);
    nuxtApp.vueApp.component('Popover', Popover);
    nuxtApp.vueApp.component('PanelMenu', PanelMenu);
    nuxtApp.vueApp.component('Password', Password);
    nuxtApp.vueApp.component('DataTable', DataTable);
    nuxtApp.vueApp.component('Column', Column);
    nuxtApp.vueApp.component('Toast', Toast);
    nuxtApp.vueApp.component('Badge', Badge);
});
