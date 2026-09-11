// C:\sirena\sirena-frontend\app\composables\useNotify.ts
import { useToast } from 'primevue/usetoast';

/** Tipos de notificación soportados por el composable. */
export type NotificationType = 'success' | 'error' | 'warn';

/** Configuración interna de cada tipo de notificación. */
interface NotifyConfig {
    severity: NotificationType;
    group: string;
    life: number;
}

export const useNotify = () => {
    const toast = useToast();

    const config: Record<NotificationType, NotifyConfig> = {
        success: { severity: 'success', group: 'success',  life: 2500 },
        error:   { severity: 'error',   group: 'centered', life: 6500 },
        warn:    { severity: 'warn',    group: 'centered', life: 6500 },
    };

    /**
     * Extrae el mensaje legible de un error del backend.
     * Acepta strings, arrays de strings, o el formato NestJS { data: { message } }.
     */
    const extractMessage = (message: any): string => {
        if (Array.isArray(message)) return message.join(', ');

        if (typeof message === 'object' && message?.data?.message) {
            const msg = message.data.message;
            if (Array.isArray(msg)) return msg.join(', ');
            if (typeof msg === 'string') return msg;
        }

        if (typeof message === 'string') return message;

        return 'No se pudo completar la operación en el servidor';
    };

    /**
     * Muestra una notificación toast.
     *
     * @param type - 'success' | 'error' | 'warn'
     * @param title - Título corto (summary)
     * @param message - Detalle del mensaje (puede ser string, array o error de NestJS)
     */
    const notify = (type: NotificationType, title: string, message: any): void => {
        const sel = config[type] ?? config.error;
        const cleanMessage = type === 'error' ? extractMessage(message) : message;

        if (toast) {
            toast.add({
                severity: sel.severity,
                group: sel.group,
                summary: title,
                detail: cleanMessage,
                life: sel.life,
            });
        }
    };

    return { notify };
};
