// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\trabajadores-cargos.service.ts
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
import { CreateTrabajadorCargoDto } from './dto/create-trabajador-cargo.dto';
import { TrabajadorCargoResponseDto } from './dto/trabajador-cargo-response.dto';
import { FindTrabajadoresCargosQueryDto } from './dto/find-trabajadores-cargos-query.dto';
import { UpdateTrabajadorCargoDto } from './dto/update-trabajador-cargo.dto';
import { TrabajadorCargo } from './entities/trabajador-cargo.entity';

@Injectable()
export class TrabajadoresCargosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'trabajadores_cargos',
        nombreEntidad: 'TrabajadorCargo',
        campoPK: 'trabajador_cargo_id',
        alias: 't',
        responseDto: TrabajadorCargoResponseDto,
        camposBusquedaEnQ: FindTrabajadoresCargosQueryDto.getCamposParaQ(),
        tablasDependientes: FindTrabajadoresCargosQueryDto.getDependencias(),
        joins: [
            {
                table: 'trabajadores',
                alias: 'tr',
                onCondition: 'tr.trabajador_id = t.trabajador_id',
                selectColumns: [
                    'tr.nombres AS trabajador_nombres',
                    'tr.paterno AS trabajador_paterno',
                    'tr.materno AS trabajador_materno',
                    'tr.dni AS trabajador_dni'
                ],
                type: 'INNER'
            },
            {
                table: 'cargos',
                alias: 'c',
                onCondition: 'c.cargo_id = t.cargo_id',
                selectColumns: [
                    'c.cargo AS cargo_nombre',
                    'c.codigo AS cargo_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'trabajador_id',
                nombreColumna: 'trabajador_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'cargo_id',
                nombreColumna: 'cargo_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_moneda_id',
                nombreColumna: 'tipo_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'trabajador_cargo_id',
            camposPermitidosParaOrdenar: FindTrabajadoresCargosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindTrabajadoresCargosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindTrabajadoresCargosQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateTrabajadorCargoDto, usuarioId: number): Promise<TrabajadorCargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_id),
                this.tablaValidador.validarRegistrosActivos('cargos', 'cargo_id', dto.cargo_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'trabajador_id', valor: dto.trabajador_id },
                        { nombre: 'cargo_id', valor: dto.cargo_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const asignacion = manager.create(TrabajadorCargo, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(asignacion);
                return this.findOne<TrabajadorCargoResponseDto>(saved.trabajador_cargo_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateTrabajadorCargoDto, usuarioId: number): Promise<TrabajadorCargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const asignacionActual = await manager.findOne(TrabajadorCargo, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!asignacionActual) {
                throw new DomainException(
                    `Asignación de trabajador y cargo no encontrada.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindTrabajadoresCargosQueryDto.getDependencias(),
                FindTrabajadoresCargosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.trabajador_id !== undefined && dtoProcesado.trabajador_id !== asignacionActual.trabajador_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dtoProcesado.trabajador_id)
                );
            }

            if (dtoProcesado.cargo_id !== undefined && dtoProcesado.cargo_id !== asignacionActual.cargo_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('cargos', 'cargo_id', dtoProcesado.cargo_id)
                );
            }

            if (
                (dtoProcesado.trabajador_id !== undefined && dtoProcesado.trabajador_id !== asignacionActual.trabajador_id) ||
                (dtoProcesado.cargo_id !== undefined && dtoProcesado.cargo_id !== asignacionActual.cargo_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'trabajador_id', valor: dtoProcesado.trabajador_id ?? asignacionActual.trabajador_id },
                            { nombre: 'cargo_id', valor: dtoProcesado.cargo_id ?? asignacionActual.cargo_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(asignacionActual, dtoProcesado);
            asignacionActual.update(usuarioId);

            try {
                await manager.save(asignacionActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error al actualizar asignación: ${getErrorMessage(error)}`, getErrorStack(error));
                throw new DomainException(
                    'Error inesperado al actualizar la asignación de trabajador y cargo.',
                    { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                );
            }
        });
    }
}
