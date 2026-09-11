// C:\sirena\sirena-backend\src\modules\tablas\tablas.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateTablaDto } from './dto/create-tabla.dto';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';
import { TablaResponseDto } from './dto/tabla-response.dto';
import { UpdateTablaDto } from './dto/update-tabla.dto';
import { Tabla } from './entities/tabla.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class TablasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'tablas',
        nombreEntidad: 'Tabla',
        campoPK: 'tabla_id',
        alias: 't',
        responseDto: TablaResponseDto,
        camposBusquedaEnQ: FindTablasQueryDto.getCamposParaQ(),
        tablasDependientes: FindTablasQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'tabla_id',
            camposPermitidosParaOrdenar: FindTablasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindTablasQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindTablasQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateTablaDto, usuarioId: number): Promise<TablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'nombre', valor: dto.nombre }],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const tabla = manager.create(Tabla, {
                nombre: dto.nombre,
                estado_id: ESTADO_ACTIVO,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(tabla);
                return this.findOne<TablaResponseDto>(saved.tabla_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la tabla', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateTablaDto, usuarioId: number): Promise<TablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const tablaActual = await manager.findOne(Tabla, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!tablaActual) {
                throw new DomainException(
                    'Tabla no encontrada.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindTablasQueryDto.getDependencias(),
                FindTablasQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.nombre !== undefined && dtoProcesado.nombre !== tablaActual.nombre) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'nombre', valor: dtoProcesado.nombre }],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            manager.merge(Tabla, tablaActual, dtoProcesado);
            tablaActual.update(usuarioId);

            try {
                await manager.save(tablaActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la tabla', 'actualizar');
            }
        });
    }
}
