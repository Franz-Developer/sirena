// C:\sirena\sirena-backend\src\modules\bancos\bancos.service.ts
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
import { BancoResponseDto } from './dto/banco-response.dto';
import { CreateBancoDto } from './dto/create-banco.dto';
import { FindBancosQueryDto } from './dto/find-bancos-query.dto';
import { UpdateBancoDto } from './dto/update-banco.dto';
import { Banco } from './entities/banco.entity';

@Injectable()
export class BancosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'bancos',
        nombreEntidad: 'Banco',
        campoPK: 'banco_id',
        alias: 't',
        responseDto: BancoResponseDto,
        camposBusquedaEnQ: FindBancosQueryDto.getCamposParaQ(),
        tablasDependientes: FindBancosQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'banco_id',
            camposPermitidosParaOrdenar: FindBancosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindBancosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindBancosQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        private readonly unicidadValidador: UnicidadValidadorService,
        tablaValidador: TablaValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    async create(dto: CreateBancoDto, usuarioId: number): Promise<BancoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const codigoAsfiNormalizado = dto.codigo_asfi.trim().padStart(2, '0');
            const dtoNormalizado = { ...dto, codigo_asfi: codigoAsfiNormalizado };

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo_asfi', valor: dtoNormalizado.codigo_asfi }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'abreviatura', valor: dtoNormalizado.abreviatura }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'banco', valor: dtoNormalizado.banco }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro, fecha_registro)
                VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;
            const params = [
                dtoNormalizado.banco,
                dtoNormalizado.codigo_asfi,
                dtoNormalizado.abreviatura,
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
                        `Error al insertar el banco "${dtoNormalizado.banco}".`,
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

    async update(id: number, dto: UpdateBancoDto, usuarioId: number): Promise<BancoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            if (dtoNormalizado.banco) {
                dtoNormalizado.banco = dtoNormalizado.banco.trim().toUpperCase();
            }

            if (dtoNormalizado.codigo_asfi) {
                dtoNormalizado.codigo_asfi = dtoNormalizado.codigo_asfi.trim().padStart(2, '0');
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const bancoActual = await manager.findOne(Banco, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!bancoActual) {
                throw new DomainException(
                    `Banco no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            // Centralización de dependencias y permisos de Administrador (1 sola línea)
            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindBancosQueryDto.getDependencias(),
                FindBancosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            // Las validaciones de unicidad continúan ejecutándose sobre los campos que sobrevivieron al DTO
            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.codigo_asfi && dtoNormalizado.codigo_asfi !== bancoActual.codigo_asfi) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'codigo_asfi', valor: dtoNormalizado.codigo_asfi }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (dtoNormalizado.abreviatura && dtoNormalizado.abreviatura !== bancoActual.abreviatura) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'abreviatura', valor: dtoNormalizado.abreviatura }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (dtoNormalizado.banco && dtoNormalizado.banco !== bancoActual.banco) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'banco', valor: dtoNormalizado.banco }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(bancoActual, dtoNormalizado);
            bancoActual.update(usuarioId);

            try {
                await manager.save(bancoActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) throw error;
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}
