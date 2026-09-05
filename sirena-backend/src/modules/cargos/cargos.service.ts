// C:\sirena\sirena-backend\src\modules\cargos\cargos.service.ts
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
import { CargoResponseDto } from './dto/cargo-response.dto';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { FindCargosQueryDto } from './dto/find-cargos-query.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { Cargo } from './entities/cargo.entity';

@Injectable()
export class CargosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'cargos',
        nombreEntidad: 'Cargo',
        campoPK: 'cargo_id',
        alias: 't',
        responseDto: CargoResponseDto,
        camposBusquedaEnQ: FindCargosQueryDto.getCamposParaQ(),
        tablasDependientes: FindCargosQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'cargo_id',
            camposPermitidosParaOrdenar: FindCargosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindCargosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindCargosQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateCargoDto, usuarioId: number): Promise<CargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'cargo', valor: dto.cargo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dto.codigo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    cargo,
                    codigo,
                    descripcion,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.cargo,
                dto.codigo,
                dto.descripcion || null,
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
                        `Error al insertar el cargo "${dto.cargo}".`,
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

    async update(id: number, dto: UpdateCargoDto, usuarioId: number): Promise<CargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const cargoActual = await manager.findOne(Cargo, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!cargoActual) {
                throw new DomainException(
                    `Cargo no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindCargosQueryDto.getDependencias(),
                FindCargosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.cargo && dto.cargo !== cargoActual.cargo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'cargo', valor: dto.cargo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (dto.codigo && dto.codigo !== cargoActual.codigo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'codigo', valor: dto.codigo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(cargoActual, dto);
            cargoActual.update(usuarioId);

            try {
                await manager.save(cargoActual);
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
