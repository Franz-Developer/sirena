ERROR No. 1

Archivo: cargos.service.ts
Función: update

Explicación: Se usa `lock: { mode: 'pessimistic_write' }` en `manager.findOne()`, pero dentro de una transacción `runInTransaction` que ya maneja el aislamiento. Esto es redundante y puede causar problemas de rendimiento innecesarios.

Se puso lock: { mode: 'pessimistic_write' } por si dos usuarios intentan actualizar el mismo registro al mismo tiempo 

ERROR No. 2

Archivo: cargos.service.ts
Función: create y update

Explicación: Se crea un objeto `responseDto` con `new CargoResponseDto()` y luego se asigna `Object.assign(responseDto, updatedRecord)`, pero inmediatamente después se llama a `this.findOne()` que ya realiza el mapeo completo. El objeto `responseDto` nunca se utiliza. Código muerto que debe eliminarse.

Exolicar no entiendo 


ERROR No. 3

Archivo: cargos.service.ts
Función: update

Explicación: Se realizan dos consultas `findOne` consecutivas: una para obtener `updatedRecord` y otra para `this.findOne(id)`. La primera es innecesaria porque `manager.save(cargoActual)` ya devuelve el registro actualizado.

se añadio 
const updatedRecord = await manager.findOne(Cargo, {
	where: { [this.campoPK]: id }
});

if (!updatedRecord) {
	throw new DomainException('No se pudo recuperar el registro actualizado.', {
		httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
	});
}

const responseDto = new CargoResponseDto();
Object.assign(responseDto, updatedRecord);

para ver si se actualizo 

PERO por que no dijiste lo mismo en 
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
            const descripcionNormalizada = dto.descripcion?.trim() || null;

            const dtoNormalizado = {
                ...dto,
                codigo_asfi: codigoAsfiNormalizado,
                descripcion: descripcionNormalizada
            };

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
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla}
                (banco, codigo_asfi, abreviatura, descripcion, estado_id, usuario_id_registro, fecha_registro)
                VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;
            const params = [
                dtoNormalizado.banco,
                dtoNormalizado.codigo_asfi,
                dtoNormalizado.abreviatura,
                dtoNormalizado.descripcion,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];
            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] ?? 0);

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

            if (dtoNormalizado.descripcion !== undefined) {
                dtoNormalizado.descripcion = dtoNormalizado.descripcion?.trim() || null;
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const bancoActual = await manager.findOne(Banco, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!bancoActual) {
                throw new DomainException(
                    `Banco no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            if (dtoNormalizado.descripcion !== undefined &&
                dtoNormalizado.descripcion !== bancoActual.descripcion) {
                this.logger.log(
                    `[AUDITORIA] Banco ID ${id}: descripcion cambiada de "${bancoActual.descripcion}" a "${dtoNormalizado.descripcion}"`
                );
            }

            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindBancosQueryDto.getDependencias(),
                FindBancosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            // Validaciones de unicidad
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

                const updatedRecord = await manager.findOne(Banco, {
                    where: { [this.campoPK]: id }
                });

                if (!updatedRecord) {
                    throw new DomainException('No se pudo recuperar el registro actualizado.', {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    });
                }

                const responseDto = new BancoResponseDto();
                Object.assign(responseDto, updatedRecord);

                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) throw error;
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}


