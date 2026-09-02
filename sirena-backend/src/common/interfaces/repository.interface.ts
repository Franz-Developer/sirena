// C:\sirena\sirena-backend\src\common\interfaces\repository.interface.ts

/**
 * Interfaz genérica para operaciones básicas de repositorio.
 * Facilita el mocking en pruebas unitarias.
 */
export interface IRepository<T = any> {
    findOne(options: any): Promise<T | null>;
    find(options?: any): Promise<T[]>;
    save(entity: T): Promise<T>;
    update(criteria: any, partialEntity: any): Promise<any>;
    delete(criteria: any): Promise<any>;
    query(query: string, parameters?: any[]): Promise<any>;
    create(entity: any): T;
}

/**
 * Interfaz específica para DataSource.
 * Permite inyectar un DataSource mockeado en pruebas.
 */
export interface IDataSource {
    query(query: string, parameters?: any[]): Promise<any>;
    createQueryRunner(): IQueryRunner;
    /** Escapa identificadores SQL (tablas, columnas) */
    escapeIdentifier(identifier: string): string; // 👈 NUEVO
}

/**
 * Interfaz para QueryRunner (transacciones).
 */
export interface IQueryRunner {
    connect(): Promise<void>;
    query(query: string, parameters?: any[]): Promise<any>;
    release(): Promise<void>;
    startTransaction(): Promise<void>;
    commitTransaction(): Promise<void>;
    rollbackTransaction(): Promise<void>;
}