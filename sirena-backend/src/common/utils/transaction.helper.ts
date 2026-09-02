// C:\sirena\sirena-backend\src\common\utils\transaction.helper.ts
import { Logger } from '@nestjs/common';
import { DataSource, EntityManager, QueryRunner } from 'typeorm';

const logger = new Logger('TransactionHelper');

/**
 * Ejecuta una función dentro de una transacción.
 * Utiliza el método oficial de TypeORM `dataSource.transaction()`
 * que maneja automáticamente el ciclo de vida completo.
 *
 * ✅ Ventajas:
 * - Código más limpio y conciso
 * - Manejo automático de connect, start, commit, rollback y release
 * - Sin riesgo de fugas de conexión
 * - Estandarización en todos los servicios
 *
 * @param dataSource - DataSource de TypeORM
 * @param fn - Función que recibe un EntityManager transaccional
 * @param options - Opciones de transacción (opcional)
 * @returns El resultado de la función
 *
 * @example
 * const resultado = await runInTransaction(dataSource, async (manager) => {
 *     const user = await manager.save(User, { name: 'Juan' });
 *     const profile = await manager.save(Profile, { userId: user.id });
 *     return { user, profile };
 * });
 *
 * @example
 * // Con opciones de transacción
 * const resultado = await runInTransaction(
 *     dataSource,
 *     async (manager) => {
 *         // ... operaciones transaccionales ...
 *     },
 *     { isolationLevel: 'SERIALIZABLE' }
 * );
 */
export async function runInTransaction<T>(
    dataSource: DataSource,
    fn: (manager: EntityManager) => Promise<T>,
    options?: {
        isolationLevel?:
            | 'READ UNCOMMITTED'
            | 'READ COMMITTED'
            | 'REPEATABLE READ'
            | 'SERIALIZABLE';
    }
): Promise<T> {
    const startTime = Date.now();

    try {
        // 🔥 dataSource.transaction() es el método oficial de TypeORM
        // Maneja automáticamente: connect, startTransaction, commit, rollback y release
        const result = await dataSource.transaction(async (manager) => {
            // Si se especifica isolationLevel, se aplica
            if (options?.isolationLevel) {
                await manager.query(`SET TRANSACTION ISOLATION LEVEL ${options.isolationLevel}`);
            }

            return await fn(manager);
        });

        const elapsed = Date.now() - startTime;
        logger.debug(`✅ Transacción completada en ${elapsed}ms`);

        return result;
    } catch (error) {
        const elapsed = Date.now() - startTime;
        logger.error(
            `❌ Transacción fallida después de ${elapsed}ms:`,
            error instanceof Error ? error.message : error
        );
        throw error;
    }
}

/**
 * Ejecuta una función dentro de una transacción con control manual de QueryRunner.
 * Útil cuando se necesita un control más fino sobre el QueryRunner.
 *
 * ⚠️ Preferir `runInTransaction()` a menos que se necesite control específico.
 *
 * @param dataSource - DataSource de TypeORM
 * @param fn - Función que recibe un QueryRunner transaccional
 * @returns El resultado de la función
 *
 * @example
 * const resultado = await runInTransactionWithQueryRunner(dataSource, async (queryRunner) => {
 *     const entidad = await queryRunner.manager.findOne(User, { where: { id: 1 } });
 *     // ... más operaciones ...
 *     return entidad;
 * });
 */
export async function runInTransactionWithQueryRunner<T>(
    dataSource: DataSource,
    fn: (queryRunner: QueryRunner) => Promise<T>
): Promise<T> {
    const queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();

    const startTime = Date.now();

    try {
        await queryRunner.startTransaction();

        const result = await fn(queryRunner);

        await queryRunner.commitTransaction();

        const elapsed = Date.now() - startTime;
        logger.debug(`✅ Transacción QueryRunner completada en ${elapsed}ms`);

        return result;
    } catch (error) {
        await queryRunner.rollbackTransaction();

        const elapsed = Date.now() - startTime;
        logger.error(
            `❌ Transacción QueryRunner fallida después de ${elapsed}ms:`,
            error instanceof Error ? error.message : error
        );
        throw error;
    } finally {
        await queryRunner.release();
    }
}

/**
 * Ejecuta múltiples funciones en una sola transacción.
 * Todas las funciones comparten el mismo EntityManager transaccional.
 *
 * @param dataSource - DataSource de TypeORM
 * @param fns - Lista de funciones a ejecutar en la transacción
 * @returns Los resultados de todas las funciones en un arreglo
 *
 * @example
 * const [user, profile, settings] = await runInTransactionAll(dataSource, [
 *     (manager) => manager.save(User, { name: 'Juan' }),
 *     (manager) => manager.save(Profile, { bio: 'Desarrollador' }),
 *     (manager) => manager.save(Settings, { theme: 'dark' }),
 * ]);
 */
export async function runInTransactionAll<T extends any[]>(
    dataSource: DataSource,
    fns: {
        [K in keyof T]: (manager: EntityManager) => Promise<T[K]>;
    }
): Promise<T> {
    return runInTransaction(dataSource, async (manager) => {
        const results = await Promise.all(fns.map((fn) => fn(manager)));
        return results as T;
    });
}

/**
 * Ejecuta una función dentro de una transacción con reintentos automáticos.
 * Útil para operaciones que pueden fallar por deadlocks o conflictos de concurrencia.
 *
 * @param dataSource - DataSource de TypeORM
 * @param fn - Función que recibe un EntityManager transaccional
 * @param maxRetries - Número máximo de reintentos (por defecto: 3)
 * @param retryDelay - Delay entre reintentos en milisegundos (por defecto: 100)
 * @returns El resultado de la función
 *
 * @example
 * const resultado = await runInTransactionWithRetry(
 *     dataSource,
 *     async (manager) => {
 *         const count = await manager.count(User);
 *         if (count > 0) {
 *             throw new Error('Simulando deadlock');
 *         }
 *         return await manager.save(User, { name: 'Juan' });
 *     },
 *     5, // 5 reintentos
 *     200 // 200ms entre reintentos
 * );
 */
export async function runInTransactionWithRetry<T>(
    dataSource: DataSource,
    fn: (manager: EntityManager) => Promise<T>,
    maxRetries: number = 3,
    retryDelay: number = 100
): Promise<T> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await runInTransaction(dataSource, fn);
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(String(error));

            // Si es un deadlock o error de serialización, reintentar
            const isRetryable =
                lastError.message?.includes('deadlock') ||
                lastError.message?.includes('serialization') ||
                lastError.message?.includes('could not serialize access');

            if (!isRetryable) {
                throw lastError;
            }

            if (attempt < maxRetries) {
                logger.warn(
                    `⚠️ Reintento ${attempt}/${maxRetries} después de error: ${lastError.message}`
                );
                await sleep(retryDelay * attempt); // Delay incremental
            }
        }
    }

    throw lastError || new Error('Todos los reintentos fallaron');
}

/**
 * Helper para pausar la ejecución.
 */
function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
