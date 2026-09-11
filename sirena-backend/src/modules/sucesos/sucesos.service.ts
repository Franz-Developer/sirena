// C:\sirena\sirena-backend\src\modules\sucesos\sucesos.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateSucesoDto } from './dto/create-suceso.dto';
import { SucesoResponseDto } from './dto/suceso-response.dto';
import { FindSucesosQueryDto } from './dto/find-sucesos-query.dto';
import { UpdateSucesoDto } from './dto/update-suceso.dto';
import { Suceso } from './entities/suceso.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class SucesosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'sucesos',
        nombreEntidad: 'Suceso',
        campoPK: 'suceso_id',
        alias: 't',
        responseDto: SucesoResponseDto,
        camposBusquedaEnQ: FindSucesosQueryDto.getCamposParaQ(),
        tablasDependientes: FindSucesosQueryDto.getDependencias(),
        joins: [
            {
                table: 'tablas',
                alias: 'tb',
                onCondition: 'tb.tabla_id = t.tabla_id',
                selectColumns: [
                    'tb.nombre AS tabla_nombre'
                ],
                type: 'INNER'
            },
            {
                table: 'roles_permisos_sucesos',
                alias: 'rps',
                onCondition: 'rps.suceso_id = t.suceso_id',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'roles_permisos_tablas',
                alias: 'rpt',
                onCondition: 'rpt.rol_permiso_tabla_id = rps.rol_permiso_tabla_id',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'roles',
                alias: 'r',
                onCondition: 'r.rol_id = rpt.rol_id',
                selectColumns: [
                    'r.rol_id AS rol_id',
                    'r.rol AS rol_nombre',
                    'r.codigo AS rol_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'tabla_id',
                nombreColumna: 't.tabla_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'rol_id',
                nombreColumna: 'r.rol_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'suceso_id',
            camposPermitidosParaOrdenar: FindSucesosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindSucesosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindSucesosQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource() dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string { return this.config.nombreTabla; }
    private get campoPK(): string { return this.config.campoPK; }

    async create(dto: CreateSucesoDto, usuarioId: number): Promise<SucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('tablas', 'tabla_id', dto.tabla_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dto.codigo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'suceso', valor: dto.suceso }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const suceso = manager.create(Suceso, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(suceso);
                return this.findOne<SucesoResponseDto>(saved.suceso_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el suceso', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateSucesoDto, usuarioId: number): Promise<SucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const sucesoActual = await manager.findOne(Suceso, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!sucesoActual) {
                throw new DomainException(
                    `Suceso no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindSucesosQueryDto.getDependencias(),
                FindSucesosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.codigo !== undefined && dtoProcesado.codigo !== sucesoActual.codigo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'codigo', valor: dtoProcesado.codigo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS],
                    })
                );
            }

            if (dtoProcesado.suceso !== undefined && dtoProcesado.suceso !== sucesoActual.suceso) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'suceso', valor: dtoProcesado.suceso }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS],
                    })
                );
            }

            if (dtoProcesado.tabla_id !== undefined && dtoProcesado.tabla_id !== sucesoActual.tabla_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('tablas', 'tabla_id', dtoProcesado.tabla_id)
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(sucesoActual, dtoProcesado);
            sucesoActual.update(usuarioId);

            try {
                await manager.save(sucesoActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el suceso', 'actualizar');
            }
        });
    }
}
