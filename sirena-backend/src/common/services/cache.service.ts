// C:\sirena\sirena-backend\src\common\services\cache.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ICacheService } from '../interfaces/cache.interface';

export interface CacheEntry<T = any> {
    data: T;
    timestamp: number;
}

@Injectable()
export class CacheService implements ICacheService {
    private readonly logger = new Logger(CacheService.name);
    private readonly cache = new Map<string, CacheEntry>();
    private readonly versions = new Map<string, number>();
    private readonly defaultTtl: number;
    private readonly maxSize: number;

    constructor() {
        this.defaultTtl = parseInt(process.env['CACHE_TTL'] ?? '300000', 10);
        this.maxSize = parseInt(process.env['CACHE_MAX_SIZE'] ?? '1000', 10);
    }

    get<T>(key: string): T | undefined {
        const entry = this.cache.get(key);
        if (!entry) return undefined;

        const isExpired = Date.now() - entry.timestamp > this.defaultTtl;
        if (isExpired) {
            this.cache.delete(key);
            return undefined;
        }

        return entry.data as T;
    }

    set<T>(key: string, value: T, ttl?: number): void {
        if (this.cache.size >= this.maxSize) {
            this.evictOldest();
        }

        const ttlMs = ttl ?? this.defaultTtl;

        this.cache.set(key, {
            data: value,
            timestamp: Date.now(),
        });

        if (ttlMs !== this.defaultTtl) {
            setTimeout(() => {
                if (this.cache.has(key)) {
                    const entry = this.cache.get(key);
                    if (entry && Date.now() - entry.timestamp > ttlMs) {
                        this.cache.delete(key);
                    }
                }
            }, ttlMs);
        }
    }

    delete(key: string): void {
        this.cache.delete(key);
    }

    deleteByPrefix(prefix: string): number {
        let deletedCount = 0;
        for (const key of this.cache.keys()) {
            if (key.startsWith(prefix)) {
                this.cache.delete(key);
                deletedCount++;
            }
        }
        if (deletedCount > 0) {
            this.logger.debug(`🗑️ [Memoria] Eliminadas ${deletedCount} claves con prefijo: ${prefix}`);
        }
        return deletedCount;
    }

    clear(): void {
        this.cache.clear();
        this.versions.clear();
        this.logger.debug('Caché y versiones limpiadas completamente.');
    }

    has(key: string): boolean {
        return this.cache.has(key);
    }

    size(): number {
        return this.cache.size;
    }

    bumpVersion(namespace: string): number {
        const currentVersion = this.versions.get(namespace) ?? 1;
        const nextVersion = currentVersion + 1;
        this.versions.set(namespace, nextVersion);
        this.logger.debug(`🔄 [Memoria] Versión incrementada para "${namespace}" -> v${nextVersion}`);
        return nextVersion;
    }

    getVersion(namespace: string): number {
        if (!this.versions.has(namespace)) {
            this.versions.set(namespace, 1);
        }
        return this.versions.get(namespace)!;
    }

    invalidateNamespace(namespace: string): void {
        this.bumpVersion(namespace);
    }

    getStats(): Promise<{
        totalEntries: number;
        maxSize?: number;
        defaultTtl?: number;
    }> {
        const entries = Array.from(this.cache.entries());
        const totalEntries = entries.length;
        const expiredEntries = entries.filter(
            ([, entry]) => Date.now() - entry.timestamp > this.defaultTtl
        ).length;

        return Promise.resolve({
            totalEntries,
            expiredEntries,
            activeEntries: totalEntries - expiredEntries,
            maxSize: this.maxSize,
            defaultTtl: this.defaultTtl,
        });
    }

    private evictOldest(): void {
        let oldestKey: string | null = null;
        let oldestTimestamp = Infinity;

        for (const [key, entry] of this.cache.entries()) {
            if (entry.timestamp < oldestTimestamp) {
                oldestTimestamp = entry.timestamp;
                oldestKey = key;
            }
        }

        if (oldestKey) {
            this.cache.delete(oldestKey);
            this.logger.debug(`Entrada eliminada por límite de tamaño: ${oldestKey}.`);
        }
    }
}
