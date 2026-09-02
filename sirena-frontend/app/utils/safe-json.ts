// C:\sirena\sirena-frontend\app\utils\safe-json.ts
export function safeJSONParse<T>(value: string | null, fallback: T): T {
    try {
        if (!value) return fallback;
        return JSON.parse(value);
    } catch {
        return fallback;
    }
}
