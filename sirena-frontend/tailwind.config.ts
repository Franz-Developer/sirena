// C:\sirena\sirena-frontend\tailwind.config.ts
import type { Config } from 'tailwindcss'
// @ts-ignore
import PrimeUI from 'tailwindcss-primeui';

const config: Config = {
    darkMode: 'class',
    content: [
        "./app/**/*.{vue,js,ts,jsx,tsx}",
        "./components/**/*.{vue,js,ts,jsx,tsx}",
        "./layouts/**/*.{vue,js,ts,jsx,tsx}",
        "./pages/**/*.{vue,js,ts,jsx,tsx}",
        "./composables/**/*.{js,ts}",
        "./plugins/**/*.{js,ts}",
        "./app.vue",
        "./error.vue",
    ],
    theme: {
        extend: {},
    },
    plugins: [PrimeUI],
    safelist: [{ pattern: /p-.*/ }]
}

export default config