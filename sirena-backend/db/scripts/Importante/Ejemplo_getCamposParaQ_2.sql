-- EJEMPLO  static getCamposParaQ_2(): string[] { 
// C:\sirena\sirena-backend\src\modules\empresas-nits\dto\find-empresas-nits-query.dto.ts
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { IsOptional, IsInt, IsIn, IsString, IsDateString, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ESTADOS_COMPLETO, ESTADOS_VIVOS, Ambiente, ModalidadFacturacion } from '../../../common/constants/estados.constant';

export class FindEmpresasNitsQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 (flexible) o 1 (exacta).' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_COMPLETO, {
        message: `estado_id debe ser uno de: ${ESTADOS_COMPLETO.join(', ')}`
    })
    estado_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'empresa_id debe ser un número entero.' })
    @Min(1, { message: 'empresa_id debe ser mayor a 0.' })
    empresa_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'ambiente_id debe ser un número entero.' })
    @IsIn(Object.values(Ambiente), {
        message: `ambiente_id debe ser: ${Object.values(Ambiente).join(', ')}`
    })
    ambiente_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'modalidad_facturacion_id debe ser un número entero.' })
    @IsIn(Object.values(ModalidadFacturacion), {
        message: `modalidad_facturacion_id debe ser: ${Object.values(ModalidadFacturacion).join(', ')}`
    })
    modalidad_facturacion_id?: number;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_inicio_vigencia_desde debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_inicio_vigencia_desde?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_inicio_vigencia_hasta debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_inicio_vigencia_hasta?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_fin_vigencia_desde debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_fin_vigencia_desde?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_fin_vigencia_hasta debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_fin_vigencia_hasta?: string;

    getEstados(): number[] {
        if (this.estado_id !== undefined) {
            return [this.estado_id];
        }
        return [...ESTADOS_VIVOS];
    }

    // Todos los campos de la tabla principal (con soporte para join opcional a empresas).
    static getCampos(): string[] {
        const alias = 't';
        const aliasEmpresa = 'e';
        return [
            `${alias}.empresa_nit_id`,
            `${alias}.empresa_id`,
            `${aliasEmpresa}.empresa AS empresa_nombre`,
            `${aliasEmpresa}.codigo AS empresa_codigo`,
            `${alias}.ambiente_id`,
            `${alias}.nit`,
            `${alias}.razon_social`,
            `${alias}.etiqueta`,
            `${alias}.actividad_economica_principal`,
            `${alias}.modalidad_facturacion_id`,
            `${alias}.certificado_digital`,
            `${alias}.certificado_password`,
            `${alias}.token_siat`,
            `${alias}.fecha_inicio_vigencia`,
            `${alias}.fecha_fin_vigencia`,
            `${alias}.email_fiscal`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['nit', 'razon_social', 'etiqueta', 'actividad_economica_principal', 'email_fiscal'];
    }

    /**
     * Campos para búsqueda global 'q' incluyendo todas las tablas relacionadas
     * Esta es la versión extensible que incluye todas las relaciones
     */
    static getCamposParaQ_2(): string[] {
        const aliasEmpresa = 'e';

        return [
            // 1. Campos de la tabla principal (empresas_nits).
            ...this.getCamposParaQ(),

            // 2. Campos de la tabla empresas.
            `${aliasEmpresa}.empresa`,
            `${aliasEmpresa}.codigo`,
         ];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'empresa_nit_id',
            'empresa_id',
            'nit',
            'razon_social',
            'etiqueta',
            'actividad_economica_principal',
            'email_fiscal',
            'fecha_inicio_vigencia',
            'fecha_fin_vigencia'
        ];
    }

    // Equivalencias de mapeo para consultas avanzadas y filtros.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasEmpresa = 'e';
        return {
            'empresa_nit_id': `${alias}.empresa_nit_id`,
            'empresa_id': `${alias}.empresa_id`,
            'empresa_nombre': `${aliasEmpresa}.empresa`,
            'empresa_codigo': `${aliasEmpresa}.codigo`,
            'ambiente_id': `${alias}.ambiente_id`,
            'nit': `${alias}.nit`,
            'razon_social': `${alias}.razon_social`,
            'etiqueta': `${alias}.etiqueta`,
            'actividad_economica_principal': `${alias}.actividad_economica_principal`,
            'modalidad_facturacion_id': `${alias}.modalidad_facturacion_id`,
            'email_fiscal': `${alias}.email_fiscal`,
            'fecha_inicio_vigencia': `${alias}.fecha_inicio_vigencia`,
            'fecha_fin_vigencia': `${alias}.fecha_fin_vigencia`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`
        };
    }
}

export { PaginatedResult };

-- *****************************************************************************
// C:\sirena\sirena-backend\src\modules\empresas-nits\empresas-nits.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DomainException } from '../../common/exceptions/domain.exception';
import { DataSource } from 'typeorm';
import { EmpresaNit } from './entities/empresa-nit.entity';
import { validateSafeText } from '../../common/utils/string.util';
import { CreateEmpresaNitDto } from './dto/create-empresa-nit.dto';
import { UpdateEmpresaNitDto } from './dto/update-empresa-nit.dto';
import { FindEmpresasNitsQueryDto } from './dto/find-empresas-nits-query.dto';
import { ESTADO_ACTIVO, ESTADO_BORRADO, ESTADOS_VIVOS, Estado } from '../../common/constants/estados.constant';
import { EmpresaNitResponseDto } from './dto/empresa-nit-response.dto';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class EmpresasNitsService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'empresas_nits',
        campoPK: 'empresa_nit_id',
        alias: 't',
        responseDto: EmpresaNitResponseDto,
        camposBusquedaEnQ: FindEmpresasNitsQueryDto.getCamposParaQ_2(),
        joins: [
            {
                table: 'empresas',
                alias: 'e',
                onCondition: 'e.empresa_id = t.empresa_id',
                selectColumns: [
                    'e.empresa AS empresa_nombre',
                    'e.codigo AS empresa_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'empresa_nit_id',
            camposPermitidosParaOrdenar: FindEmpresasNitsQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindEmpresasNitsQueryDto.getEquivalenciasMapeo(),
        },
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        override readonly tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    private validarCamposTexto(dto: CreateEmpresaNitDto | UpdateEmpresaNitDto): void {
        if (dto.nit) { validateSafeText(dto.nit, 'NIT'); }
        if (dto.razon_social) { validateSafeText(dto.razon_social, 'Razón Social'); }
        if (dto.actividad_economica_principal) {
            validateSafeText(dto.actividad_economica_principal, 'Actividad Económica Principal');
        }
        if (dto.etiqueta) { validateSafeText(dto.etiqueta, 'Etiqueta'); }
        if (dto.email_fiscal) { validateSafeText(dto.email_fiscal, 'Email Fiscal'); }
        if (dto.certificado_digital) { validateSafeText(dto.certificado_digital, 'Certificado Digital'); }
        if (dto.token_siat) { validateSafeText(dto.token_siat, 'Token SIAT'); }
    }

    private validarReglasNegocio(dto: CreateEmpresaNitDto | UpdateEmpresaNitDto): void {
        if (dto.fecha_inicio_vigencia && dto.fecha_fin_vigencia) {
            if (dto.fecha_inicio_vigencia > dto.fecha_fin_vigencia) {
                throw new DomainException(
                    'La fecha de inicio de vigencia no puede ser mayor a la fecha de fin de vigencia.',
                    'FECHAS_VIGENCIA_INVALIDAS',
                    {
                        fecha_inicio_vigencia: dto.fecha_inicio_vigencia,
                        fecha_fin_vigencia: dto.fecha_fin_vigencia,
                        httpStatus: HttpStatus.BAD_REQUEST
                    }
                );
            }
        }
    }

    async create(dto: CreateEmpresaNitDto, usuarioId: number): Promise<EmpresaNitResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            this.validarReglasNegocio(dto);
            this.validarCamposTexto(dto);

            await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id);
            await this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear');

            await this.unicidadValidador.validarUnicidad({
                tabla: this.nombreTabla,
                campos: [{ nombre: 'nit', valor: dto.nit }],
                estadosValidos: [...ESTADOS_VIVOS],
                campoPk: this.campoPK,
            });

            await this.unicidadValidador.validarUnicidad({
                tabla: this.nombreTabla,
                campos: [
                    { nombre: 'etiqueta', valor: dto.etiqueta },
                    { nombre: 'empresa_id', valor: dto.empresa_id }
                ],
                estadosValidos: [...ESTADOS_VIVOS],
                campoPk: this.campoPK,
            });

            await this.validarUnicidadHistorico(dto.nit, dto.fecha_inicio_vigencia, dto.fecha_fin_vigencia, manager);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    empresa_id,
                    ambiente_id,
                    nit,
                    razon_social,
                    actividad_economica_principal,
                    etiqueta,
                    modalidad_facturacion_id,
                    certificado_digital,
                    certificado_password,
                    token_siat,
                    fecha_inicio_vigencia,
                    fecha_fin_vigencia,
                    email_fiscal,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.empresa_id,
                dto.ambiente_id,
                dto.nit,
                dto.razon_social,
                dto.actividad_economica_principal,
                dto.etiqueta,
                dto.modalidad_facturacion_id,
                dto.certificado_digital || null,
                dto.certificado_password || null,
                dto.token_siat || null,
                dto.fecha_inicio_vigencia || null,
                dto.fecha_fin_vigencia || null,
                dto.email_fiscal,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];

            try {
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] || 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al insertar el NIT de la empresa.',
                        'EMPRESA_NIT_INSERT_ERROR',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                throw new DomainException(
                    `Ocurrió un error inesperado al crear: ${getErrorMessage(error)}`,
                    'EMPRESA_NIT_UNEXPECTED_ERROR',
                    {
                        details: getErrorMessage(error),
                        stack: getErrorStack(error),
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }
        });
    }

    private async validarUnicidadHistorico(
        nit: string,
        fechaInicio: Date | undefined,
        fechaFin: Date | undefined,
        manager: any
    ): Promise<void> {
        let query = `
            SELECT COUNT(*) as total
            FROM ${this.nombreTabla}
            WHERE nit = $1
            AND estado_id = $2
        `;

        const params: any[] = [nit, Estado.HISTORICO];
        let paramIdx = 3;

        if (fechaInicio === null || fechaInicio === undefined) {
            query += ` AND fecha_inicio_vigencia IS NOT DISTINCT FROM NULL`;
        } else {
            query += ` AND fecha_inicio_vigencia = $${paramIdx}`;
            params.push(fechaInicio);
            paramIdx++;
        }

        if (fechaFin === null || fechaFin === undefined) {
            query += ` AND fecha_fin_vigencia IS NOT DISTINCT FROM NULL`;
        } else {
            query += ` AND fecha_fin_vigencia = $${paramIdx}`;
            params.push(fechaFin);
            paramIdx++;
        }

        const result = await manager.query(query, params);

        if (result && result.length > 0 && Number(result[0].total) > 0) {
            throw new DomainException(
                `Ya existe un registro HISTÓRICO con el mismo NIT y el mismo rango de vigencia (incluyendo NULL).`,
                'REGISTRO_HISTORICO_DUPLICADO',
                {
                    nit,
                    fecha_inicio_vigencia: fechaInicio || null,
                    fecha_fin_vigencia: fechaFin || null,
                    httpStatus: HttpStatus.CONFLICT
                }
            );
        }
    }

    async update(id: number, dto: UpdateEmpresaNitDto, usuarioId: number): Promise<EmpresaNitResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            this.validarReglasNegocio(dto);
            this.validarCamposTexto(dto);

            const nitActual = await manager.findOne(EmpresaNit, {
                where: { [this.campoPK]: id } as any
            });

            if (!nitActual) {
                throw new DomainException(
                    `NIT de empresa con ID #${id} no encontrado.`,
                    'EMPRESA_NIT_NOT_FOUND',
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            if (dto.empresa_id !== undefined && dto.empresa_id !== nitActual.empresa_id) {
                await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id);
            }

            if (dto.nit !== undefined && dto.nit !== nitActual.nit) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'nit', valor: dto.nit }],
                    idExcluir: id,
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                });
            }

            if (dto.etiqueta !== undefined && dto.etiqueta !== nitActual.etiqueta ||
                dto.empresa_id !== undefined && dto.empresa_id !== nitActual.empresa_id) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'etiqueta', valor: dto.etiqueta ?? nitActual.etiqueta },
                        { nombre: 'empresa_id', valor: dto.empresa_id ?? nitActual.empresa_id }
                    ],
                    idExcluir: id,
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                });
            }

            const nuevoNit = dto.nit ?? nitActual.nit;
            const nuevaFechaInicio = dto.fecha_inicio_vigencia !== undefined ? dto.fecha_inicio_vigencia : nitActual.fecha_inicio_vigencia;
            const nuevaFechaFin = dto.fecha_fin_vigencia !== undefined ? dto.fecha_fin_vigencia : nitActual.fecha_fin_vigencia;

            if (dto.nit !== undefined || dto.fecha_inicio_vigencia !== undefined || dto.fecha_fin_vigencia !== undefined) {
                await this.validarUnicidadHistoricoExcluyendo(
                    nuevoNit,
                    nuevaFechaInicio,
                    nuevaFechaFin,
                    id,
                    manager
                );
            }

            Object.assign(nitActual, dto);
            nitActual.usuario_id_actualizacion = usuarioId;

            try {
                await manager.save(nitActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                throw new DomainException(
                    `Ocurrió un error inesperado al actualizar: ${getErrorMessage(error)}`,
                    'EMPRESA_NIT_UNEXPECTED_ERROR',
                    {
                        details: getErrorMessage(error),
                        stack: getErrorStack(error),
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }
        });
    }

    private async validarUnicidadHistoricoExcluyendo(
        nit: string,
        fechaInicio: Date | null | undefined,
        fechaFin: Date | null | undefined,
        idExcluir: number,
        manager: any
    ): Promise<void> {
        let query = `
            SELECT COUNT(*) as total
            FROM ${this.nombreTabla}
            WHERE nit = $1
            AND estado_id = $2
            AND ${this.campoPK} != $3
        `;

        const params: any[] = [nit, Estado.HISTORICO, idExcluir];
        let paramIdx = 4;

        if (fechaInicio === null || fechaInicio === undefined) {
            query += ` AND fecha_inicio_vigencia IS NOT DISTINCT FROM NULL`;
        } else {
            query += ` AND fecha_inicio_vigencia = $${paramIdx}`;
            params.push(fechaInicio);
            paramIdx++;
        }

        if (fechaFin === null || fechaFin === undefined) {
            query += ` AND fecha_fin_vigencia IS NOT DISTINCT FROM NULL`;
        } else {
            query += ` AND fecha_fin_vigencia = $${paramIdx}`;
            params.push(fechaFin);
            paramIdx++;
        }

        const result = await manager.query(query, params);

        if (result && result.length > 0 && Number(result[0].total) > 0) {
            throw new DomainException(
                `Ya existe otro registro HISTÓRICO con el mismo NIT y el mismo rango de vigencia (incluyendo NULL).`,
                'REGISTRO_HISTORICO_DUPLICADO',
                {
                    nit,
                    fecha_inicio_vigencia: fechaInicio || null,
                    fecha_fin_vigencia: fechaFin || null,
                    idExcluido: idExcluir,
                    httpStatus: HttpStatus.CONFLICT
                }
            );
        }
    }

    async remove(id: number, usuarioIdBaja: number): Promise<EmpresaNitResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreDelete(
                this.nombreTabla,
                id,
                [],
                this.campoPK,
                usuarioIdBaja
            );

            const query = `
                UPDATE ${this.nombreTabla}
                SET
                    estado_id = $1,
                    usuario_id_baja = $2,
                    fecha_baja = CURRENT_TIMESTAMP,
                    usuario_id_actualizacion = NULL,
                    fecha_actualizacion = NULL
                WHERE ${this.campoPK} = $3
            `;
            const params = [ESTADO_BORRADO, Number(usuarioIdBaja), Number(id)];

            try {
                await manager.query(query, params);
                return this.findOne(id, usuarioIdBaja, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                throw new DomainException(
                    `Ocurrió un error inesperado al eliminar: ${getErrorMessage(error)}`,
                    'EMPRESA_NIT_UNEXPECTED_ERROR',
                    {
                        details: getErrorMessage(error),
                        stack: getErrorStack(error),
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }
        });
    }
}

