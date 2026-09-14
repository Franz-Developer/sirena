// C:\sirena\sirena-backend\src\modules\sucursales\sucursales.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, In } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateSucursalDto } from './dto/create-sucursal.dto';
import { SucursalResponseDto } from './dto/sucursal-response.dto';
import { FindSucursalesQueryDto } from './dto/find-sucursales-query.dto';
import { UpdateSucursalDto } from './dto/update-sucursal.dto';
import { Sucursal } from './entities/sucursal.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

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
            const nombreEmpresa = await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id, 't.empresa');

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal', valor: dto.sucursal }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe una sucursal con el nombre '${dto.sucursal}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal_largo', valor: dto.sucursal_largo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe una sucursal con el nombre largo '${dto.sucursal_largo}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo', valor: dto.codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un registro con el código '${dto.codigo}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo_sin', valor: dto.codigo_sin }
                    ],
                    estadosValidos: [ESTADO_ACTIVO],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un registro con código sin '${dto.codigo_sin}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId, undefined, 'El usuario del sistema no se encuentra activo o no existe.')
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

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la sucursal', 'crear');
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

            const empresaIdEval = dtoProcesado.empresa_id ?? sucursalActual.empresa_id;
            const nombreEmpresa = await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', empresaIdEval, 't.empresa');

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.sucursal !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorSucursal = dtoProcesado.sucursal ?? sucursalActual.sucursal;
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
                        mensajePersonalizado: `Ya existe una sucursal con el nombre '${valorSucursal}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.sucursal_largo !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorSucursalLargo = dtoProcesado.sucursal_largo ?? sucursalActual.sucursal_largo;
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
                        mensajePersonalizado: `Ya existe una sucursal con el nombre largo '${valorSucursalLargo}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.codigo !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorCodigo = dtoProcesado.codigo ?? sucursalActual.codigo;
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
                        mensajePersonalizado: `Ya existe un registro con el código '${valorCodigo}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.codigo_sin !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorCodigoSin = dtoProcesado.codigo_sin ?? sucursalActual.codigo_sin;
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
                        mensajePersonalizado: `Ya existe un registro con código sin '${valorCodigoSin}' para la empresa '${nombreEmpresa}'.`,
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

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la sucursal', 'actualizar');
            }
        });
    }

    async siguienteCodigoSin(
        empresaId: number,
        usuarioId: number
    ): Promise<{ codigo_sin: number }> {
        await Promise.all([
            this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'leer'),
            this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', empresaId),
        ]);

        try {
            const max = await this.dataSource
                .getRepository(Sucursal)
                .maximum('codigo_sin', {
                    empresa_id: empresaId,
                    estado_id: In([...ESTADOS_VIVOS]),
                });

            const siguiente = (max ?? -1) + 1;

            return {
                codigo_sin: Number.isFinite(siguiente) && siguiente >= 0 ? siguiente : 0,
            };
        } catch (error: unknown) {
            if (isDomainException(error)) {
                throw error;
            }

            const errorMessage = getErrorMessage(error);
            this.logger.error(
                `Error inesperado en siguienteCodigoSin: ${errorMessage}`,
                getErrorStack(error)
            );

            throw new DomainException(
                'No se pudo obtener el siguiente código SIN.',
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR, causa: errorMessage }
            );
        }
    }
}
