// C:\sirena\sirena-backend\src\modules\tablas\tablas.service.ts
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
import { CreateTablaDto } from './dto/create-tabla.dto';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';
import { TablaResponseDto } from './dto/tabla-response.dto';
import { UpdateTablaDto } from './dto/update-tabla.dto';
import { Tabla } from './entities/tabla.entity';

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
        joins: [], // No hay joins necesarios para esta entidad
        configuracionFiltros: [
            {
                nombreCampo: 'estado_id',
                nombreColumna: 'estado_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
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
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear')
            ];

            // Validar unicidad del nombre (solo para registros ACTIVOS)
            validaciones.push(
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'nombre', valor: dto.nombre }],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            );

            await Promise.all(validaciones);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    nombre,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.nombre,
                ESTADO_ACTIVO,
                Number(usuarioId),
            ];

            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] ?? 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al registrar la tabla.',
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

    async update(id: number, dto: UpdateTablaDto, usuarioId: number): Promise<TablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const tablaActual = await manager.findOne(Tabla, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!tablaActual) {
                throw new DomainException(
                    'Tabla no encontrada.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindTablasQueryDto.getDependencias(),
                FindTablasQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            // Validar unicidad del nombre solo si cambió
            if (dto.nombre !== undefined && dto.nombre !== tablaActual.nombre) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'nombre', valor: dto.nombre }],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(tablaActual, dto);
            tablaActual.update(usuarioId);

            try {
                await manager.save(tablaActual);
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
