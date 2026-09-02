// C:\sirena\sirena-backend\src\common\services\data-source-adapter.service.ts
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { IDataSource, IQueryRunner } from '../interfaces/repository.interface';

@Injectable()
export class DataSourceAdapter implements IDataSource {
    constructor(private readonly dataSource: DataSource) {}

    async query(query: string, parameters?: any[]): Promise<any> {
        return this.dataSource.query(query, parameters);
    }

    createQueryRunner(): IQueryRunner {
        const runner = this.dataSource.createQueryRunner();
        return {
            connect: () => runner.connect(),
            query: (query: string, parameters?: any[]) => runner.query(query, parameters),
            release: () => runner.release(),
            startTransaction: () => runner.startTransaction(),
            commitTransaction: () => runner.commitTransaction(),
            rollbackTransaction: () => runner.rollbackTransaction(),
        };
    }

    /**
     * Escapa identificadores SQL (tablas, columnas) usando el driver nativo de TypeORM.
     */
    escapeIdentifier(identifier: string): string {
        return this.dataSource.driver.escape(identifier);
    }
}