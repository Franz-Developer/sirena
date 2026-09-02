// C:\sirena\sirena-backend\src\common\validators\unicidad-validador.service.ts
import { Injectable, HttpStatus, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS } from '../constants/estados.constant';
import { DomainException } from '../exceptions/domain.exception';
import { getErrorMessage, getErrorStack, isDomainException } from '../utils/error.util';

export interface UnicidadConfig {
    tabla: string;                      // Nombre de la tabla
    campos: {                           // Array de campos a validar
        nombre: string;                 // Nombre de la columna
        valor: any;                     // Valor a validar
    }[];
    idExcluir?: number;                 // ID a excluir (para updates)
    campoPk?: string;                   // Nombre del campo PK (por defecto 'id')
    incluirEstado?: boolean;            // Incluir filtro de estado
    estadosValidos?: number[];          // Estados a considerar
    caseInsensitive?: boolean;          // Case insensitive
    permitirNull?: boolean;             // Permitir NULL
    condicionesExtra?: {                // Para filtros adicionales (ej. estado_contrato_id = 4750)
        nombre: string;
        valor: any;
    }[];
}

@Injectable()
export class UnicidadValidadorService {
    private readonly logger = new Logger(UnicidadValidadorService.name);

    constructor(
        private readonly dataSource: DataSource,
    ) {}

    async validarUnicidad(config: UnicidadConfig): Promise<void> {
        const defaults = {
            campoPk: 'id',
            incluirEstado: true,
            estadosValidos: ESTADOS_VIVOS as unknown as number[],
            caseInsensitive: false,
            permitirNull: false,
        };

        const opts = { ...defaults, ...config };

        if (!opts.campos || opts.campos.length === 0) {
            this.logger.debug(`No hay campos para validar unicidad en ${opts.tabla}`);
            return;
        }

        const tablaSanitizada = this.dataSource.driver.escape(opts.tabla);
        const campoPkSanitizado = this.dataSource.driver.escape(opts.campoPk);

        const whereClauses: string[] = [];
        const params: any[] = [];
        let paramIndex = 1;

        // 1. Campos principales de unicidad
        for (const campo of opts.campos) {
            const columnaSanitizada = this.dataSource.driver.escape(campo.nombre);

            if (!opts.permitirNull && (campo.valor === null || campo.valor === undefined)) {
                continue;
            }

            if (campo.valor === null) {
                whereClauses.push(`${columnaSanitizada} IS NULL`);
                continue;
            }

            if (opts.caseInsensitive && typeof campo.valor === 'string') {
                whereClauses.push(`LOWER(${columnaSanitizada}) = LOWER($${paramIndex})`);
                params.push(campo.valor);
                paramIndex++;
                continue;
            }

            whereClauses.push(`${columnaSanitizada} = $${paramIndex}`);
            params.push(campo.valor);
            paramIndex++;
        }

        if (whereClauses.length === 0) {
            this.logger.debug(`No hay campos válidos para validar unicidad en ${opts.tabla}`);
            return;
        }

        // 2. ID a excluir (Updates)
        if (opts.idExcluir !== undefined && opts.idExcluir !== null) {
            whereClauses.push(`${campoPkSanitizado} != $${paramIndex}`);
            params.push(opts.idExcluir);
            paramIndex++;
        }

        // 3. Condiciones extra (ej. estado_contrato_id = 4750)
        if (opts.condicionesExtra && opts.condicionesExtra.length > 0) {
            for (const cond of opts.condicionesExtra) {
                const colExtraSanitizada = this.dataSource.driver.escape(cond.nombre);
                if (cond.valor === null) {
                    whereClauses.push(`${colExtraSanitizada} IS NULL`);
                } else {
                    whereClauses.push(`${colExtraSanitizada} = $${paramIndex}`);
                    params.push(cond.valor);
                    paramIndex++;
                }
            }
        }

        // 4. Filtro de estado principal
        if (opts.incluirEstado && opts.estadosValidos && opts.estadosValidos.length > 0) {
            const estadoPlaceholders = opts.estadosValidos
                .map(() => `$${paramIndex++}`)
                .join(', ');

            whereClauses.push(`estado_id IN (${estadoPlaceholders})`);
            params.push(...opts.estadosValidos);
        }

        const query = `
            SELECT ${campoPkSanitizado} AS id
            FROM ${tablaSanitizada}
            WHERE ${whereClauses.join(' AND ')}
            LIMIT 1
        `;

        try {
            const duplicados = (await this.dataSource.query(query, params)) as { id: number }[];

            if (duplicados && duplicados.length > 0) {
                const duplicado = duplicados[0];
                const detalleCampos = opts.campos
                    .map((campo) => `${campo.nombre.replace(/_/g, ' ')} "${campo.valor ?? 'NULL'}"`)
                    .join(', con ');

                throw new DomainException(
                    `Ya existe un registro con ${detalleCampos}.`,
                    {
                        tabla: opts.tabla,
                        campos: opts.campos,
                        idDuplicado: duplicado?.id,
                        idExcluido: opts.idExcluir,
                        httpStatus: HttpStatus.CONFLICT,
                    }
                );
            }
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
            throw error;
        }
    }
}
