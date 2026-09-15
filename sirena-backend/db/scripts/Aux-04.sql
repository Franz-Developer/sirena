1. chart.js (el más probable)

Tu useChart.ts lo carga dinámicamente, pero si algún componente que se renderiza en principal.vue lo importa de forma estática, se incluye en el bundle inicial.

Cómo verificar: En Firefox, presiona Ctrl+Shift+E, recarga, y busca chart en la lista de peticiones. Si ves un archivo .js grande con "chart" en el nombre, ahí está.

2. estados.constant.ts (el archivo gigante)

Ese archivo tiene más de 3000 líneas. Si principal.vue o algún componente que renderiza importa algo de ahí de forma estática (incluso una sola constante), todo el archivo se incluye en el bundle.

Cómo verificar: Busca en tu principal.vue y en los componentes que usa (Dashboard, Cards, etc.) si hay algún import ... from '~/constants/estados.constant'. Si lo hay, ese es el problema.
3. Componentes de PrimeVue registrados globalmente

Tienes 12 componentes de PrimeVue registrados globalmente en plugins/primevue.ts. Si principal.vue usa varios de ellos en el primer render, todos se incluyen en el bundle inicial.