// C:\sirena\sirena-backend\src\common\services\redis-cache.service.ts
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { ICacheService } from '../interfaces/cache.interface';
import { CacheService } from './cache.service'; // Respaldo en memoria

@Injectable()
export class RedisCacheService implements ICacheService, OnModuleDestroy {
    private readonly logger = new Logger(RedisCacheService.name);
    private readonly defaultTtl: number;
    private readonly redis: Redis | null = null;
    private readonly enabled: boolean;

    // Se inyecta CacheService como respaldo
    constructor(private readonly memoryCache: CacheService) {
        this.defaultTtl = parseInt(process.env['CACHE_TTL'] ?? '300000', 10);
        this.enabled = process.env['USE_REDIS_CACHE'] === 'true';

        if (this.enabled) {
            const redisUrl = process.env['REDIS_URL'] || 'redis://localhost:6379';
            this.redis = new Redis(redisUrl, {
                retryStrategy: (times) => Math.min(times * 50, 2000),
                maxRetriesPerRequest: 2,
                connectTimeout: 2000,
            });

            this.redis.on('error', (err) => this.logger.error('Redis Error:', err.message));
        }
    }

    async get<T>(key: string): Promise<T | undefined> {
        if (this.enabled && this.redis) {
            try {
                const value = await this.redis.get(key);
                if (value) return JSON.parse(value) as T;
            } catch (error) {
                this.logger.warn(`Redis GET falló para la clave "${key}". Usando respaldo en memoria. Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        return this.memoryCache.get<T>(key);
    }

    async set<T>(key: string, value: T, ttl?: number): Promise<void> {
        if (this.enabled && this.redis) {
            try {
                const ttlMs = ttl ?? this.defaultTtl;
                await this.redis.set(key, JSON.stringify(value), 'PX', ttlMs);
            } catch (error) {
                this.logger.error(`Redis SET falló para la clave "${key}". Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        // SIEMPRE guardar en memoria (fallback)
        this.memoryCache.set(key, value, ttl);
    }

    async delete(key: string): Promise<void> {
        if (this.enabled && this.redis) {
            try {
                await this.redis.del(key);
            } catch (error) {
                this.logger.warn(`Redis DELETE falló para la clave "${key}". Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        this.memoryCache.delete(key);
    }

    async deleteByPrefix(prefix: string): Promise<number> {
        let deletedCount = 0;
        if (this.enabled && this.redis) {
            try {
                let cursor = '0';
                const keysToDelete: string[] = [];
                do {
                    const result = await this.redis.scan(cursor, 'MATCH', `${prefix}*`, 'COUNT', 100);
                    cursor = result[0];
                    const keys = result[1];
                    if (keys && keys.length > 0) {
                        keysToDelete.push(...keys);
                    }
                } while (cursor !== '0');

                if (keysToDelete.length > 0) {
                    await this.redis.unlink(...keysToDelete); // No bloqueante
                    deletedCount = keysToDelete.length;
                }
            } catch (error) {
                this.logger.error(`Redis DELETE BY PREFIX falló para "${prefix}"`);
            }
        }
        const memoryDeleted = this.memoryCache.deleteByPrefix(prefix);
        return deletedCount + memoryDeleted;
    }

    async clear(): Promise<void> {
        if (this.enabled && this.redis) {
            try {
                await this.redis.flushdb();
            } catch (error) {
                this.logger.error(`Redis CLEAR (flushdb) falló. Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        this.memoryCache.clear();
    }

    async has(key: string): Promise<boolean> {
        if (this.enabled && this.redis) {
            try {
                return (await this.redis.exists(key)) === 1;
            } catch (error) {
                this.logger.warn(`Redis HAS falló para la clave "${key}", consultando memoria. Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        return this.memoryCache.has(key);
    }

    async size(): Promise<number> {
        if (this.enabled && this.redis) {
            try {
                return await this.redis.dbsize();
            } catch (error) {
                this.logger.warn(`Redis SIZE (dbsize) falló, consultando memoria. Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }
        return this.memoryCache.size();
    }

    async bumpVersion(namespace: string): Promise<number> {
        const versionKey = `cache:version:${namespace}`;
        if (this.enabled && this.redis) {
            try {
                const newVersion = await this.redis.incr(versionKey);
                // Mantener TTL de 30 días (2592000 segundos) para evitar llaves huérfanas
                await this.redis.expire(versionKey, 2592000);
                this.memoryCache.bumpVersion(namespace);
                return newVersion;
            } catch (error) {
                this.logger.warn(`Redis BUMP VERSION falló para "${namespace}", usando memoria.`);
            }
        }
        return this.memoryCache.bumpVersion(namespace);
    }

    async getVersion(namespace: string): Promise<number> {
        const versionKey = `cache:version:${namespace}`;
        if (this.enabled && this.redis) {
            try {
                const versionStr = await this.redis.get(versionKey);
                if (versionStr) {
                    return parseInt(versionStr, 10);
                }
                // Si no existe, inicializar en 1 con TTL de 30 días
                await this.redis.set(versionKey, 1, 'EX', 2592000);
                return 1;
            } catch (error) {
                this.logger.warn(`Redis GET VERSION falló para "${namespace}", usando memoria.`);
            }
        }
        return this.memoryCache.getVersion(namespace);
    }

    async invalidateNamespace(namespace: string): Promise<void> {
        await this.bumpVersion(namespace);
    }

    async getStats(): Promise<{
        totalEntries: number;
        expiredEntries?: number;
        activeEntries?: number;
        maxSize?: number;
        defaultTtl?: number;
        enabled: boolean;
    }> {
        if (this.enabled && this.redis) {
            try {
                const totalKeys = await this.redis.dbsize();
                return {
                    totalEntries: totalKeys,
                    defaultTtl: this.defaultTtl,
                    enabled: true,
                };
            } catch (error) {
                this.logger.warn(`Error obteniendo estadísticas de Redis, usando respaldo de memoria. Detalle: ${error instanceof Error ? error.message : error}`);
            }
        }

        // Si Redis está apagado o falló, obtenemos las stats de la memoria
        const memoryStats = await this.memoryCache.getStats();
        return {
            ...memoryStats,
            enabled: false,
        };
    }

    async onModuleDestroy(): Promise<void> {
        if (this.redis) await this.redis.quit();
    }
}
