// C:\sirena\sirena-frontend\app\services\auth.service.ts
export const useAuthService = () => {
    const config = useRuntimeConfig();
    const apiBase = config.public.apiBase;

    const login = async (username: string, password: string) => {
        try {
            const data = await $fetch<any>(`${apiBase}/auth/validar`, {
                method: 'POST',
                body: {
                    username: username.toUpperCase(),
                    password
                }
            });
            return data;
        } catch (error: any) {
            const message = error?.data?.message;

            if (Array.isArray(message)) {
                throw message.join(', ');
            }
            if (typeof message === 'string') {
                throw message;
            }
            if (error?.data?.error) {
                throw error.data.error;
            }

            throw 'Error de conexión con el servidor';
        }
    };

    return { login };
};
