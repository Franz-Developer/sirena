// C:\sirena\sirena-backend\src\modules\sucursales\sucursales.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
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
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const sucursal = manager.create(Sucursal, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(sucursal);
                return this.findOne<SucursalResponseDto>(saved.sucursal_id, usuarioId, manager);
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
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const sucursalActual = await manager.findOne(Sucursal, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!sucursalActual) {
                throw new DomainException(
                    'Sucursal no encontrada.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindSucursalesQueryDto.getDependencias(),
                FindSucursalesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (dtoProcesado.empresa_id !== undefined && dtoProcesado.empresa_id !== sucursalActual.empresa_id) {
                await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dtoProcesado.empresa_id);
            }

            const validaciones: Promise<any>[] = [];
            const empresaIdEval = dtoProcesado.empresa_id ?? sucursalActual.empresa_id;

            if (dtoProcesado.sucursal !== undefined || dtoProcesado.empresa_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal', valor: dtoProcesado.sucursal ?? sucursalActual.sucursal }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoProcesado.sucursal_largo !== undefined || dtoProcesado.empresa_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal_largo', valor: dtoProcesado.sucursal_largo ?? sucursalActual.sucursal_largo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoProcesado.codigo !== undefined || dtoProcesado.empresa_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo', valor: dtoProcesado.codigo ?? sucursalActual.codigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoProcesado.codigo_sin !== undefined || dtoProcesado.empresa_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo_sin', valor: dtoProcesado.codigo_sin ?? sucursalActual.codigo_sin }
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

            Object.assign(sucursalActual, dtoProcesado);
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
