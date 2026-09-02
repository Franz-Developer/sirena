// C:\sirena\sirena-backend\src\common\interfaces\cache.interface.ts
export interface ICacheService {
    get<T>(key: string): Promise<T | undefined> | T | undefined;
    set<T>(key: string, value: T, ttl?: number): Promise<void> | void;
    delete(key: string): Promise<void> | void;
    clear(): Promise<void> | void;
    has?(key: string): Promise<boolean> | boolean;
    getStats?(): Promise<{
        totalEntries: number;
        maxSize?: number;
        defaultTtl?: number;
    }>;

    bumpVersion(namespace: string): Promise<number> | number;
    getVersion(namespace: string): Promise<number> | number;

    invalidateNamespace(namespace: string): Promise<void> | void;

    deleteByPrefix?(prefix: string): Promise<number> | number;
}
