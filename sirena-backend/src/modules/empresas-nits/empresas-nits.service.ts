// C:\sirena\sirena-backend\src\modules\empresas-nits\empresas-nits.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { formatOnlyDate } from '../../common/utils/date-formatter.util';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateEmpresaNitDto } from './dto/create-empresa-nit.dto';
import { EmpresaNitResponseDto } from './dto/empresa-nit-response.dto';
import { FindEmpresasNitsQueryDto } from './dto/find-empresas-nits-query.dto';
import { UpdateEmpresaNitDto } from './dto/update-empresa-nit.dto';
import { EmpresaNit } from './entities/empresa-nit.entity';

@Injectable()
export class EmpresasNitsService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'empresas_nits',
        nombreEntidad: 'NIT Fiscal',
        campoPK: 'empresa_nit_id',
        alias: 't',
        responseDto: EmpresaNitResponseDto,
        camposBusquedaEnQ: FindEmpresasNitsQueryDto.getCamposParaQ(),
        tablasDependientes: FindEmpresasNitsQueryDto.getDependencias(),
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
        configuracionFiltros: [
            {
                nombreCampo: 'empresa_id',
                nombreColumna: 'empresa_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'ambiente_id',
                nombreColumna: 'ambiente_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'modalidad_facturacion_id',
                nombreColumna: 'modalidad_facturacion_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'fecha_inicio_vigencia_desde',
                nombreColumna: 'fecha_inicio_vigencia',
                tipoDatoFiltro: 'date',
                operador: 'gte',
            },
            {
                nombreCampo: 'fecha_inicio_vigencia_hasta',
                nombreColumna: 'fecha_inicio_vigencia',
                tipoDatoFiltro: 'date',
                operador: 'lte',
            },
            {
                nombreCampo: 'fecha_fin_vigencia_desde',
                nombreColumna: 'fecha_fin_vigencia',
                tipoDatoFiltro: 'date',
                operador: 'gte',
            },
            {
                nombreCampo: 'fecha_fin_vigencia_hasta',
                nombreColumna: 'fecha_fin_vigencia',
                tipoDatoFiltro: 'date',
                operador: 'lte',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'empresa_nit_id',
            camposPermitidosParaOrdenar: FindEmpresasNitsQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindEmpresasNitsQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindEmpresasNitsQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        tablaValidador: TablaValidadorService,
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

    private validarReglasNegocio(dto: CreateEmpresaNitDto | UpdateEmpresaNitDto): void {
        if (dto.fecha_inicio_vigencia && dto.fecha_fin_vigencia) {
            if (dto.fecha_inicio_vigencia > dto.fecha_fin_vigencia) {
                throw new DomainException(
                    `La fecha inicio de vigencia ${formatOnlyDate(dto.fecha_inicio_vigencia)} no puede ser mayor a la fecha de fin de vigencia ${formatOnlyDate(dto.fecha_fin_vigencia)}.`,
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }
        }
    }

    async create(dto: CreateEmpresaNitDto, usuarioId: number): Promise<EmpresaNitResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            this.validarReglasNegocio(dto);

            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'nit', valor: dto.nit },
                        { nombre: 'etiqueta', valor: dto.etiqueta },
                        { nombre: 'empresa_id', valor: dto.empresa_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
            ]);

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
                dto.fecha_inicio_vigencia,
                dto.fecha_fin_vigencia,
                dto.email_fiscal,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];
            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] || 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al insertar el NIT de la empresa.',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

        async update(id: number, dto: UpdateEmpresaNitDto, usuarioId: number): Promise<EmpresaNitResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);
            this.validarReglasNegocio(dto);

            const nitActual = await manager.findOne(EmpresaNit, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!nitActual) {
                throw new DomainException(
                    `NIT no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            // Validar dependencias para bloquear campos protegidos si existen registros hijos
            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindEmpresasNitsQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindEmpresasNitsQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dto) {
                        delete (dto as any)[campo];
                    }
                });
            }

            const validaciones: Promise<any>[] = [];

            if (dto.empresa_id !== undefined && dto.empresa_id !== nitActual.empresa_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id)
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            const nuevoEmpresaId = dto.empresa_id ?? nitActual.empresa_id;
            const nuevoNit = dto.nit ?? nitActual.nit;
            const nuevoEtiqueta = dto.etiqueta ?? nitActual.etiqueta;

            if (
                dto.empresa_id !== undefined ||
                dto.nit !== undefined ||
                dto.etiqueta !== undefined
            ) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'nit', valor: nuevoNit },
                        { nombre: 'etiqueta', valor: nuevoEtiqueta },
                        { nombre: 'empresa_id', valor: nuevoEmpresaId }
                    ],
                    idExcluir: id,
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                });
            }

            Object.assign(nitActual, dto);
            nitActual.update(usuarioId);

            try {
                await manager.save(nitActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}
