// C:\sirena\sirena-frontend\app\composables\useNotify.ts
import { useToast } from "primevue/usetoast";

export const useNotify = () => {
    const toast = useToast();
    type NotificationType = 'success' | 'error' | 'warn';
    const config = {
        success: { severity: 'success', group: 'success', life: 1000 },
        error: { severity: 'error' as const, group: 'centered', life: 6500 },
        warn: { severity: 'warn' as const, group: 'centered', life: 6500 }
    };

    const extractMessage = (message: any): string => {
        if (Array.isArray(message)) { return message.join(', '); }
        if (typeof message === 'object' && message?.data?.message) {
            const msg = message.data.message;
            if (Array.isArray(msg)) return msg.join(', ');
            if (typeof msg === 'string') return msg;
        }
        if (typeof message === 'string') { return message; }
        return 'No se pudo completar la operación en el servidor';
    };

    const notify = (type: NotificationType, title: string, message: any) => {
        const sel = config[type] || config.error;
        const cleanMessage = type === 'error' ? extractMessage(message) : message;
        if (toast) { toast.add({ severity: sel.severity, group: sel.group, summary: title, detail: cleanMessage, life: sel.life }); }
    };
    return { notify };
};
