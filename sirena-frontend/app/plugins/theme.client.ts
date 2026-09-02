import { defineNuxtPlugin } from '#app'

export default defineNuxtPlugin(() => {
    const saved = localStorage.getItem('theme') || 'light';

    if (saved === 'dark') {
        document.documentElement.classList.add('dark');
    } else {
        document.documentElement.classList.remove('dark');
    }
})
