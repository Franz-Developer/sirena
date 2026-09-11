// C:\sirena\sirena-backend\src\modules\unidades\unidades.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { UnidadResponseDto } from './dto/unidad-response.dto';
import { CreateUnidadDto } from './dto/create-unidad.dto';
import { FindUnidadesQueryDto } from './dto/find-unidades-query.dto';
import { UpdateUnidadDto } from './dto/update-unidad.dto';
import { Unidad } from './entities/unidad.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class UnidadesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'unidades',
        nombreEntidad: 'Unidad',
        campoPK: 'unidad_id',
        alias: 't',
        responseDto: UnidadResponseDto,
        camposBusquedaEnQ: FindUnidadesQueryDto.getCamposParaQ(),
        tablasDependientes: [],
        joins: [],
        configuracionFiltros: [
            {
                nombreCampo: 'codigo_sin',
                nombreColumna: 'codigo_sin',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'unidad_id',
            camposPermitidosParaOrdenar: FindUnidadesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindUnidadesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindUnidadesQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateUnidadDto, usuarioId: number): Promise<UnidadResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dto.codigo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'unidad', valor: dto.unidad }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const unidad = manager.create(Unidad, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(unidad);
                return this.findOne<UnidadResponseDto>(saved.unidad_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la unidad', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateUnidadDto, usuarioId: number): Promise<UnidadResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const unidadActual = await manager.findOne(Unidad, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!unidadActual) {
                throw new DomainException(
                    `Unidad no encontrada.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindUnidadesQueryDto.getDependencias(),
                FindUnidadesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.codigo && dtoProcesado.codigo !== unidadActual.codigo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'codigo', valor: dtoProcesado.codigo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (dtoProcesado.unidad && dtoProcesado.unidad !== unidadActual.unidad) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'unidad', valor: dtoProcesado.unidad }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(unidadActual, dto);
            unidadActual.update(usuarioId);

            try {
                await manager.save(unidadActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la unidad', 'actualizar');
            }
        });
    }
}
