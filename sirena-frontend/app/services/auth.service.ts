export const useAuthService = () => {
    const config = useRuntimeConfig();
    const apiBase = config.public.apiBase;

    const login = async (username: string, password: string) => {
        try {
            const data = await $fetch<any>(`${apiBase}/auth/login`, {
                method: 'POST',
                body: { username, password }
            });
            return data;
        } catch (error: any) {
            throw error.data?.message || 'Error de conexión con el servidor';
        }
    };

    return { login };
};
