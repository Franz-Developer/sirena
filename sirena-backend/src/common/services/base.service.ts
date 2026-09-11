// C:\sirena\sirena-backend\src\common\services\base.service.ts
import { Injectable, Logger, HttpStatus, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { DataSource, EntityManager } from 'typeorm';
import { ESTADO_METADATA, ESTADOS_CONSULTA, ESTADOS_PERMITIDOS, Estado } from '../constants/estados.constant';
import { BasePaginationQueryDto } from '../dto/base-pagination-query.dto';
import { DomainException } from '../exceptions/domain.exception';
import { PaginatedResult } from '../interfaces/pagination.interface';
import { getErrorMessage, getErrorStack, isDomainException } from '../utils/error.util';
import { logSqlQuery } from '../utils/sql-logger.util';
import { SQL_NORMALIZE_SEARCH } from '../utils/string.util';
import { runInTransaction } from '../utils/transaction.helper';
import { FileUrlService } from './file-url.service';
import { TablaValidadorService } from '../validators/tabla-validador.service';

export interface BaseJoinConfig {
    table: string;
    alias: string;
    onCondition: string;
    selectColumns: string[];
    type: 'INNER' | 'LEFT';
}

export interface BaseServiceConfig {
    nombreTabla: string;
    nombreEntidad: string;
    campoPK: string;
    alias: string;
    responseDto: new (...args: any[]) => any;
    camposBusquedaEnQ: string[];
    tablasDependientes: Array<string | { tabla: string; campoFk: string }>;
    joins: BaseJoinConfig[];
    configuracionFiltros: Array<{
        nombreCampo: string;      // Nombre del campo en el DTO
        nombreColumna: string;     // Nombre de la columna en la tabla
        tipoDatoFiltro: 'number' | 'string' | 'date' | 'boolean' | 'array';
        operador?: 'eq' | 'neq' | 'gt' | 'gte' | 'lt' | 'lte' | 'like' | 'in' | 'ieq';
        valoresPermitidos?: any[];
        requerido?: boolean;
    }>;
    configuracionOrden: {
        campoOrdenPorDefecto?: string;
        camposPermitidosParaOrdenar?: string[];
        equivalenciasMapeo?: Record<string, string>;
    };
    getCamposProtegidosConDependencias: () => string[];
}

@Injectable()
export abstract class BaseService {
    protected readonly logger = new Logger(this.constructor.name);
    protected abstract config: BaseServiceConfig;

    constructor(
        protected readonly dataSource: DataSource,
        protected readonly tablaValidador: TablaValidadorService,
        protected readonly fileUrlService?: FileUrlService,
    ) {}

    async findAll<T>(
        queryDto: BasePaginationQueryDto,
        usuarioId: number,
        customWhere?: string,
        customParams?: any[]
    ): Promise<PaginatedResult<T>> {
        await this.tablaValidador.validarPermisoTabla(usuarioId, this.config.nombreTabla, 'leer');

        const { nombreTabla, campoPK, responseDto, joins, camposBusquedaEnQ, alias } = this.config;

        let dataQuery = '';
        let dataQueryParams: any[] = [];

        try {
            const fechaInicioGestion = await this.tablaValidador.obtenerFechaInicioGestion();
            const { whereClause, params } = this.buildBaseWhereClause(
                queryDto, alias,
                fechaInicioGestion,
                camposBusquedaEnQ,
                customWhere,
                customParams
            );

            let dynamicJoins = '';
            let dynamicSelects = '';

            if (joins && joins.length > 0) {
                for (const j of joins) {
                    const joinType = j.type || 'LEFT';
                    const estadosPermitidos = ESTADOS_CONSULTA.map(s => s).join(', ');
                    const onCondition = `${j.onCondition} AND ${j.alias}.estado_id IN (${estadosPermitidos})`;
                    dynamicJoins += ` ${joinType} JOIN ${j.table} ${j.alias} ON ${onCondition}`;
                    if (j.selectColumns && j.selectColumns.length > 0) {
                        dynamicSelects += `, ${j.selectColumns.join(', ')}`;
                    }
                }
            }

            const countQuery = `
                SELECT COUNT(*) AS total
                FROM ${nombreTabla} ${alias}
                ${dynamicJoins}
                ${whereClause}
            `;
            logSqlQuery(countQuery, params, `count de findAll - ${nombreTabla}`);

            const executor = this.dataSource;
            const countResult = await executor.query(countQuery, params);
            const total = Number(countResult[0]?.total || 0);

            if (total === 0) {
                return {
                    data: [],
                    total: 0,
                    limit: queryDto.getLimit ? queryDto.getLimit() : (queryDto.limit || 10),
                    offset: queryDto.getOffset ? queryDto.getOffset() : (queryDto.offset || 0)
                };
            }

            const orderByClause = this.getResolvedOrderBy(queryDto, alias);
            const paginationClause = queryDto.getPaginationClause ? queryDto.getPaginationClause() : `LIMIT ${queryDto.limit || 10} OFFSET ${queryDto.offset || 0}`;

            const stateSelects = `
                , CASE ${alias}.estado_id
                    ${Object.values(ESTADO_METADATA).map(meta => `WHEN ${meta.id} THEN '${meta.abreviatura}'`).join('\n')}
                  END AS estado_registro
            `;

            dataQuery = `
                SELECT
                    ${alias}.*
                    ${stateSelects}
                    ${dynamicSelects},
                    fn_obtener_login_para_operacion($${params.length + 1}, $${params.length + 2}, ${alias}.${campoPK}) AS usuario_operacion
                FROM ${nombreTabla} ${alias}
                ${dynamicJoins}
                ${whereClause}
                ${orderByClause}
                ${paginationClause}
            `;

            dataQueryParams = [...params, nombreTabla, campoPK];

            logSqlQuery(dataQuery, dataQueryParams, `findAll - ${nombreTabla}`);

            const rows = await executor.query(dataQuery, dataQueryParams);
            const data = plainToInstance(responseDto, rows, { excludeExtraneousValues: true });

            return {
                data: Array.isArray(data) ? data : [],
                total,
                limit: queryDto.getLimit ? queryDto.getLimit() : (queryDto.limit || 10),
                offset: queryDto.getOffset ? queryDto.getOffset() : (queryDto.offset || 0)
            };
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            const errorMessage = getErrorMessage(error);
            this.logger.error(`Error en findAll - ${this.config.nombreTabla}: ${errorMessage}`, getErrorStack(error));
            throw new DomainException(
                `Error al obtener los ${this.config.nombreEntidad?.toLowerCase() ?? 'registros'}`,
                {
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                    tabla: this.config.nombreTabla,
                    usuarioId,
                    queryDto,
                    originalError: errorMessage
                }
            );
        }
    }

    protected buildBaseWhereClause(
        queryDto: any,
        alias: string,
        fechaInicioGestion: Date,
        camposBusquedaEnQ?: string[],
        customWhere?: string,
        customParams?: any[]
    ): { whereClause: string; params: any[] } {
        const estadosPermitidos = [...ESTADOS_CONSULTA];
        const estados = queryDto.estado_id !== undefined ? [queryDto.estado_id] : estadosPermitidos;

        let whereClause = `
            WHERE 1=1
            AND ${alias}.${this.config.campoPK} > 1
            AND ${alias}.estado_id IN (
                ${estados.map((_, i) => `$${i + 1}`).join(', ')}
            )
        `;

        const params: any[] = [...estados];
        let pIdx = params.length + 1;

        whereClause += `
            AND (
                ${alias}.fecha_registro >= $${pIdx}
                OR (
                    ${alias}.fecha_actualizacion IS NOT NULL
                    AND ${alias}.fecha_actualizacion >= $${pIdx}
                )
            )
        `;

        params.push(fechaInicioGestion);
        pIdx++;

        // PROCESAR FILTROS DINÁMICOS DESDE LA CONFIGURACIÓN
        if (this.config.configuracionFiltros && this.config.configuracionFiltros.length > 0) {
            for (const filter of this.config.configuracionFiltros) {
                const value = queryDto[filter.nombreCampo];

                if (value === undefined || value === null) {
                    continue;
                }

                // Validar valores permitidos
                if (filter.valoresPermitidos && !filter.valoresPermitidos.includes(value)) {
                    throw new DomainException(
                        `Valor inválido para ${filter.nombreCampo}. Permitidos: ${filter.valoresPermitidos.join(', ')}`,
                        { httpStatus: HttpStatus.BAD_REQUEST }
                    );
                }

                const column = `${alias}.${filter.nombreColumna}`;
                const operador = filter.operador || 'eq';

                // Construir condición WHERE según el tipo y operador
                switch (operador) {
                    case 'eq':
                        whereClause += ` AND ${column} = $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'neq':
                        whereClause += ` AND ${column} != $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'gt':
                        whereClause += ` AND ${column} > $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'gte':
                        whereClause += ` AND ${column} >= $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'lt':
                        whereClause += ` AND ${column} < $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'lte':
                        whereClause += ` AND ${column} <= $${pIdx}`;
                        params.push(value);
                        pIdx++;
                        break;

                    case 'like':
                        whereClause += ` AND ${column} ILIKE $${pIdx}`;
                        params.push(`%${value}%`);
                        pIdx++;
                        break;

                    case 'in':
                        if (Array.isArray(value) && value.length > 0) {
                            const placeholders = value.map((_, i) => `$${pIdx + i}`).join(', ');
                            whereClause += ` AND ${column} IN (${placeholders})`;
                            params.push(...value);
                            pIdx += value.length;
                        }
                        break;

                    case 'ieq':
                        whereClause += ` AND LOWER(${column}) = LOWER($${pIdx})`;
                        params.push(value);
                        pIdx++;
                        break;

                    default:
                        whereClause += ` AND ${column} = $${pIdx}`;
                        params.push(value);
                        pIdx++;
                }
            }
        }

        if (queryDto.usuario_id !== undefined) {
            whereClause += `
                AND ${alias}.usuario_id_registro = $${pIdx}
            `;

            params.push(queryDto.usuario_id);
            pIdx++;
        }

        if (queryDto.q?.trim() && camposBusquedaEnQ && camposBusquedaEnQ.length > 0) {
            const searchTerm = queryDto.q.trim();
            if (queryDto.exactMatch === 1) {
                const escapeRegex = (value: string): string => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const escapedPhrase = escapeRegex(searchTerm);
                const exactPattern = `(^|[[:space:]])${escapedPhrase}($|[[:space:]])`;

                const conditions = camposBusquedaEnQ
                    .map(col => {
                        if (col.includes('.')) {
                            return `${col} ~ $${pIdx}`;
                        }
                        return `${alias}.${col} ~ $${pIdx}`;
                    })
                    .join(' OR ');
                whereClause += `
                    AND (
                        ${conditions}
                    )
                `;

                params.push(exactPattern);
                pIdx++;
            } else {
                const words = searchTerm
                    .split(/\s+/)
                    .map((word: string) => word.trim())
                    .filter(Boolean);

                for (const word of words) {
                    if (!word) {
                        continue;
                    }

                    const search = `%${word}%`;
                    const conditions = camposBusquedaEnQ
                        .map(col => {
                            if (col.includes('.')) {
                                return `${SQL_NORMALIZE_SEARCH(col)} LIKE ${SQL_NORMALIZE_SEARCH(`$${pIdx}`)}`;
                            }
                            return `${SQL_NORMALIZE_SEARCH(`${alias}.${col}`)} LIKE ${SQL_NORMALIZE_SEARCH(`$${pIdx}`)}`;
                        })
                        .join(' OR ');
                    whereClause += `
                        AND (
                            ${conditions}
                        )
                    `;

                    params.push(search);
                    pIdx++;
                }
            }
        }

        if (customWhere) {
            whereClause += ` AND (${customWhere})`;
            if (customParams && customParams.length > 0) {
                params.push(...customParams);
            }
        }

        return { whereClause, params };
    }

    protected getResolvedOrderBy(queryDto: BasePaginationQueryDto, alias: string): string {
        const { campoPK, configuracionOrden } = this.config;

        const defaultField = configuracionOrden?.campoOrdenPorDefecto || campoPK;
        const camposPermitidosParaOrdenar = configuracionOrden?.camposPermitidosParaOrdenar || [campoPK];
        const equivalenciasMapeo = configuracionOrden?.equivalenciasMapeo || {};

        const rawField = queryDto.sortField || defaultField;
        const mappedField = equivalenciasMapeo[rawField] ?? rawField;
        const finalField = camposPermitidosParaOrdenar.includes(rawField) ? mappedField : defaultField;

        const direction = queryDto.getOrderDirection();

        queryDto.validateAlias(alias);

        if (finalField.includes('.')) {
            const parts = finalField.split('.');
            const relAlias = parts[0];
            const relCol = parts[1];

            if (!relAlias || !relCol) {
                throw new DomainException(
                    `Campo de ordenamiento mapeado inválido: ${finalField}`,
                    { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                );
            }

            queryDto.validateAlias(relAlias);
            const safeCol = queryDto.escapeSqlIdentifier(relCol);
            return `ORDER BY "${relAlias}".${safeCol} ${direction}`;
        }

        const safeAlias = queryDto.escapeSqlIdentifier(alias);
        const safeField = queryDto.escapeSqlIdentifier(finalField);

        return `ORDER BY ${safeAlias}.${safeField} ${direction}`;
    }

    async findOne<T>(id: number, usuarioId: number, manager?: EntityManager): Promise<T> {
        await this.tablaValidador.validarPermisoTabla(usuarioId, this.config.nombreTabla, 'leer');

        const { nombreTabla, campoPK, responseDto, joins } = this.config;
        const estadoIds = [...ESTADOS_PERMITIDOS];

        const caseSql = Object.values(ESTADO_METADATA)
            .map(meta => `WHEN ${meta.id} THEN '${meta.abreviatura}'`)
            .join('\n');

        let dynamicSelects = '';
        let dynamicJoins = '';

        if (joins && joins.length > 0) {
            for (const j of joins) {
                const joinType = j.type || 'LEFT';
                dynamicJoins += ` ${joinType} JOIN ${j.table} ${j.alias} ON ${j.onCondition}`;
                if (j.selectColumns && j.selectColumns.length > 0) {
                    dynamicSelects += `, ${j.selectColumns.join(', ')}`;
                }
            }
        }

        const query = `
            SELECT
                t.*,
                CASE t.estado_id
                    ${caseSql}
                END AS estado_registro,
                fn_obtener_login_para_operacion($2, $3, t.${campoPK}) AS usuario_operacion
                ${dynamicSelects}
            FROM ${nombreTabla} t
            ${dynamicJoins}
            WHERE t.${campoPK} = $1
            AND t.estado_id IN (${estadoIds.join(',')})
            LIMIT 1;
        `;

        const params = [id, nombreTabla, campoPK];
        logSqlQuery(query, params, `findOne - ${nombreTabla}`);

        try {
            const executor = manager || this.dataSource;

            const rows = await executor.query(query, params);

            if (!rows || rows.length === 0) {
                throw new DomainException(
                    `El ${this.config.nombreEntidad?.toLowerCase() ?? 'registro'} no fue encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            let tieneDependencias = false;
            if (this.config.tablasDependientes && this.config.tablasDependientes.length > 0) {
                tieneDependencias = await this.tablaValidador.validarDependencias(
                    this.config.nombreTabla,
                    id,
                    this.config.tablasDependientes,
                    this.config.campoPK
                );
            }

            const camposProtegidos = typeof this.config.getCamposProtegidosConDependencias === 'function'
                ? this.config.getCamposProtegidosConDependencias()
                : [];

            const registroConDependencias = {
                ...rows[0],
                tiene_dependencias: tieneDependencias,
                campos_protegidos: camposProtegidos,
            };

            return plainToInstance(responseDto, registroConDependencias, { excludeExtraneousValues: true });
        } catch (error) {
            if (isDomainException(error) || error instanceof NotFoundException) {
                throw error;
            }

            const errorMessage = getErrorMessage(error);
            const entityName = this.constructor.name.replace('Service', '');

            this.logger.error(`Error en findOne - ${this.config.nombreTabla} ID:${id}: ${errorMessage}`, getErrorStack(error));

            throw new DomainException(
                `Error al obtener ${entityName} con ID ${id}`,
                {
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                    tabla: this.config.nombreTabla,
                    id,
                    usuarioId,
                    originalError: errorMessage
                }
            );
        }
    }

    async archivar<T>(id: number, usuarioId: number): Promise<T> {
        return runInTransaction(this.dataSource, async (manager) => {
            const { nombreTabla, campoPK } = this.config;

            if (this.tablaValidador) {
                await this.tablaValidador.validarPreArchivar(nombreTabla, id, usuarioId, campoPK);
            }

            const query = `
                UPDATE ${nombreTabla}
                SET
                    estado_id = $1,
                    usuario_id_actualizacion = $2,
                    fecha_actualizacion = CURRENT_TIMESTAMP,
                    usuario_id_baja = NULL,
                    fecha_baja = NULL
                WHERE ${campoPK} = $3
                RETURNING *
            `;
            const params = [Estado.HISTORICO, Number(usuarioId), Number(id)];
            logSqlQuery(query, params, `archivar - ${nombreTabla}`);

            try {
                const result = await manager.query(query, params);

                if (!result || result.length === 0) {
                    throw new DomainException(
                        `No se pudo archivar el ${this.config.nombreEntidad?.toLowerCase() ?? 'registro'}.`,
                        { httpStatus: HttpStatus.NOT_FOUND }
                    );
                }

                return await this.findOne<T>(id, usuarioId, manager);
            } catch (error) {
                if (isDomainException(error)) throw error;

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error en archivar - ${this.config.nombreTabla} ID:${id}: ${errorMessage}`, getErrorStack(error));

                throw new DomainException(
                    `Error al archivar el registro con ID ${id}`,
                    {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                        tabla: this.config.nombreTabla,
                        id,
                        usuarioId,
                        originalError: errorMessage
                    }
                );
            }
        });
    }

    async desarchivar<T>(id: number, usuarioId: number): Promise<T> {
        return runInTransaction(this.dataSource, async (manager) => {
            const { nombreTabla, campoPK } = this.config;

            if (this.tablaValidador) {
                await this.tablaValidador.validarPreDesarchivar(nombreTabla, id, usuarioId, campoPK);
            }

            const query = `
                UPDATE ${nombreTabla}
                SET
                    estado_id = $1,
                    usuario_id_actualizacion = $2,
                    fecha_actualizacion = CURRENT_TIMESTAMP,
                    usuario_id_baja = NULL,
                    fecha_baja = NULL
                WHERE ${campoPK} = $3
                RETURNING *
            `;
            const params = [Estado.ACTIVO, Number(usuarioId), Number(id)];
            logSqlQuery(query, params, `desarchivar - ${nombreTabla}`);

            try {
                const result = await manager.query(query, params);

                if (!result || result.length === 0) {
                    throw new DomainException(
                        `No se pudo desarchivar el ${this.config.nombreEntidad?.toLowerCase() ?? 'registro'}.`,
                        { httpStatus: HttpStatus.NOT_FOUND }
                    );
                }

                return await this.findOne<T>(id, usuarioId, manager);
            } catch (error) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error en desarchivar - ${this.config.nombreTabla} ID:${id}: ${errorMessage}`, getErrorStack(error));

                throw new DomainException(
                    `Error al desarchivar el registro con ID ${id}`,
                    {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                        tabla: this.config.nombreTabla,
                        id,
                        usuarioId,
                        originalError: errorMessage
                    }
                );
            }
        });
    }

    async remove<T>(
        id: number,
        usuarioIdBaja: number,
        tablasDependientes?: string[],
    ): Promise<T> {
        return runInTransaction(this.dataSource, async (manager) => {
            const { nombreTabla, campoPK } = this.config;
            const dependencias = tablasDependientes || this.config.tablasDependientes || [];


            if (this.tablaValidador && typeof this.tablaValidador.validarPreDelete === 'function') {
                await this.tablaValidador.validarPreDelete(
                    nombreTabla,
                    id,
                    dependencias,
                    campoPK,
                    usuarioIdBaja
                );
            }

            const query = `
                UPDATE ${nombreTabla}
                SET
                    estado_id = $1,
                    usuario_id_baja = $2,
                    fecha_baja = CURRENT_TIMESTAMP,
                    usuario_id_actualizacion = NULL,
                    fecha_actualizacion = NULL
                WHERE ${campoPK} = $3
            `;
            const params = [Estado.BORRADO, Number(usuarioIdBaja), Number(id)];
            logSqlQuery(query, params, `remove - ${nombreTabla}`);

            try {
                await manager.query(query, params);
                return await this.findOne<T>(id, usuarioIdBaja, manager);
            } catch (error) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error en remove - ${this.config.nombreTabla} ID:${id}: ${errorMessage}`, getErrorStack(error));

                throw new DomainException(
                    `Error al eliminar el ${this.config.nombreEntidad?.toLowerCase() ?? 'registro'} con ID ${id}`,
                    {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                        tabla: this.config.nombreTabla,
                        id,
                        usuarioIdBaja,
                        tablasDependientes,
                        originalError: errorMessage
                    }
                );
            }
        });
    }

    protected async sincronizarSecuencia(
        manager: EntityManager,
        nombreTabla: string,
        campoPk: string
    ): Promise<void> {
        try {
            const tablaValida = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(nombreTabla);
            const campoValido = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(campoPk);

            if (!tablaValida || !campoValido) {
                this.logger.warn(`Nombres inválidos: tabla=${nombreTabla}, campo=${campoPk}`);
                return;
            }

            const seqResult = await manager.query(
                `SELECT pg_get_serial_sequence($1, $2) as seq`,
                [nombreTabla, campoPk]
            );

            const secuencia = seqResult[0]?.seq || `${nombreTabla}_${campoPk}_seq`;

            const query = `
                SELECT setval(
                    $1,
                    COALESCE((SELECT MAX(${campoPk}) FROM ${nombreTabla}), 0),
                    (SELECT COUNT(*) > 0 FROM ${nombreTabla})
                )
            `;

            await manager.query(query, [secuencia]);

            this.logger.debug(`Secuencia ${secuencia} sincronizada`);
        } catch (error) {
            this.logger.warn(
                `Error al sincronizar secuencia ${nombreTabla}_${campoPk}_seq: ${getErrorMessage(error)}`
            );
        }
    }
}
