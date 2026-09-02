// C:\sirena\sirena-backend\src\modules\sucursales\sucursales.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateSucursalDto } from './dto/create-sucursal.dto';
import { SucursalResponseDto } from './dto/sucursal-response.dto';
import { FindSucursalesQueryDto } from './dto/find-sucursales-query.dto';
import { UpdateSucursalDto } from './dto/update-sucursal.dto';
import { Sucursal } from './entities/sucursal.entity';

@Injectable()
export class SucursalesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'sucursales',
        nombreEntidad: 'Sucursal',
        campoPK: 'sucursal_id',
        alias: 't',
        responseDto: SucursalResponseDto,
        camposBusquedaEnQ: FindSucursalesQueryDto.getCamposParaQ(),
        tablasDependientes: FindSucursalesQueryDto.getDependencias(),
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
                nombreCampo: 'codigo_sin',
                nombreColumna: 'codigo_sin',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'sucursal_id',
            camposPermitidosParaOrdenar: FindSucursalesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindSucursalesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindSucursalesQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateSucursalDto, usuarioId: number): Promise<SucursalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal', valor: dto.sucursal }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal_largo', valor: dto.sucursal_largo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo', valor: dto.codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo_sin', valor: dto.codigo_sin }
                    ],
                    estadosValidos: [ESTADO_ACTIVO],
                    campoPk: this.campoPK
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    empresa_id,
                    sucursal,
                    sucursal_largo,
                    codigo,
                    codigo_sin,
                    telefono,
                    ubicacion,
                    horario_atencion,
                    factor_venta,
                    factor_facturacion,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.empresa_id,
                dto.sucursal,
                dto.sucursal_largo,
                dto.codigo,
                dto.codigo_sin,
                dto.telefono || null,
                dto.ubicacion || null,
                dto.horario_atencion || null,
                dto.factor_venta ?? 1.50,
                dto.factor_facturacion ?? 1.19,
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
                        'Error al insertar la sucursal.',
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

    async update(id: number, dto: UpdateSucursalDto, usuarioId: number): Promise<SucursalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const sucursalActual = await manager.findOne(Sucursal, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!sucursalActual) {
                throw new DomainException(
                    `Sucursal no encontrada.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindSucursalesQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindSucursalesQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dtoNormalizado) {
                        delete (dtoNormalizado as any)[campo];
                    }
                });
            }

            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.empresa_id !== undefined && dtoNormalizado.empresa_id !== sucursalActual.empresa_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dtoNormalizado.empresa_id)
                );
            }

            const empresaIdEval = dtoNormalizado.empresa_id ?? sucursalActual.empresa_id;

            if (dtoNormalizado.sucursal !== undefined && dtoNormalizado.sucursal !== sucursalActual.sucursal ||
                dtoNormalizado.empresa_id !== undefined && dtoNormalizado.empresa_id !== sucursalActual.empresa_id) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal', valor: dtoNormalizado.sucursal ?? sucursalActual.sucursal }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoNormalizado.sucursal_largo !== undefined && dtoNormalizado.sucursal_largo !== sucursalActual.sucursal_largo ||
                dtoNormalizado.empresa_id !== undefined && dtoNormalizado.empresa_id !== sucursalActual.empresa_id) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal_largo', valor: dtoNormalizado.sucursal_largo ?? sucursalActual.sucursal_largo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoNormalizado.codigo !== undefined && dtoNormalizado.codigo !== sucursalActual.codigo ||
                dtoNormalizado.empresa_id !== undefined && dtoNormalizado.empresa_id !== sucursalActual.empresa_id) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo', valor: dtoNormalizado.codigo ?? sucursalActual.codigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoNormalizado.codigo_sin !== undefined && dtoNormalizado.codigo_sin !== sucursalActual.codigo_sin ||
                dtoNormalizado.empresa_id !== undefined && dtoNormalizado.empresa_id !== sucursalActual.empresa_id) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo_sin', valor: dtoNormalizado.codigo_sin ?? sucursalActual.codigo_sin }
                        ],
                        idExcluir: id,
                        estadosValidos: [ESTADO_ACTIVO],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(sucursalActual, dtoNormalizado);
            sucursalActual.update(usuarioId);

            try {
                await manager.save(sucursalActual);
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
