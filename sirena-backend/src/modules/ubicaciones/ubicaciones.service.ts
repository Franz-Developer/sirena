// C:\sirena\sirena-backend\src\modules\ubicaciones\ubicaciones.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateUbicacionDto } from './dto/create-ubicacion.dto';
import { UbicacionResponseDto } from './dto/ubicacion-response.dto';
import { FindUbicacionesQueryDto } from './dto/find-ubicaciones-query.dto';
import { UpdateUbicacionDto } from './dto/update-ubicacion.dto';
import { Ubicacion } from './entities/ubicacion.entity';
import { TipoUbicacion, CODIGO_TIPO_UBICACION } from '../../common/constants/ubicaciones.constants';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class UbicacionesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'ubicaciones',
        nombreEntidad: 'Ubicación',
        campoPK: 'ubicacion_id',
        alias: 't',
        responseDto: UbicacionResponseDto,
        camposBusquedaEnQ: FindUbicacionesQueryDto.getCamposParaQ(),
        tablasDependientes: FindUbicacionesQueryDto.getDependencias(),
        joins: [
            {
                table: 'almacenes',
                alias: 'a',
                onCondition: 'a.almacen_id = t.almacen_id',
                selectColumns: [
                    'a.almacen AS almacen_nombre',
                    'a.codigo AS almacen_codigo'
                ],
                type: 'INNER'
            },
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'almacen_id',
                nombreColumna: 'almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'ubicacion_id',
            camposPermitidosParaOrdenar: FindUbicacionesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindUbicacionesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindUbicacionesQueryDto.getCamposProtegidosConDependencias(),
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

    private generateCode(tipo: string, valor: string, nivel?: number): string {
        const prefijo = CODIGO_TIPO_UBICACION[tipo as TipoUbicacion] || 'NIN';
        let code = `${prefijo}-${valor}`;
        if (nivel !== undefined && nivel !== null) {
            code += `-${nivel}`;
        }
        return code.toUpperCase();
    }

    private async getExistingCodes(
        almacenId: number,
        prefijo: string,
        manager: any
    ): Promise<string[]> {
        const query = `
            SELECT codigo
            FROM ${this.nombreTabla}
            WHERE almacen_id = $1
                AND codigo LIKE $2
                AND estado_id IN (${ESTADOS_VIVOS.join(', ')})
            ORDER BY codigo ASC
        `;
        const params = [almacenId, `${prefijo}-%`];

        const results = await manager.query(query, params);
        return results?.map((row: any) => row.codigo) || [];
    }

    private getNextAvailableNumber(existingCodes: string[], prefijo: string): string {
        const numbers: number[] = [];

        for (const code of existingCodes) {
            const match = code.match(new RegExp(`${prefijo}-(\\d+)`));
            if (match && match[1]) {
                numbers.push(parseInt(match[1], 10));
            }
        }

        if (numbers.length === 0) {
            return '01';
        }

        numbers.sort((a, b) => a - b);

        let nextNum = 1;
        for (const num of numbers) {
            if (num === nextNum) {
                nextNum++;
            } else if (num > nextNum) {
                break;
            }
        }

        return String(nextNum).padStart(2, '0');
    }

    async create(dto: CreateUbicacionDto, usuarioId: number): Promise<UbicacionResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dto.almacen_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const tipo = dto.jerarquia.tipo;
            const cantidadNiveles = dto.niveles || 1;

            const prefijo = CODIGO_TIPO_UBICACION[tipo as TipoUbicacion] || 'NIN';
            const existingCodes = await this.getExistingCodes(dto.almacen_id, prefijo, manager);
            const baseNumber = this.getNextAvailableNumber(existingCodes, prefijo);

            const results: UbicacionResponseDto[] = [];

            for (let i = 0; i < cantidadNiveles; i++) {
                const nivel = i + 1;
                const currentNumber = String(Number(baseNumber) + i).padStart(2, '0');
                const codigo = this.generateCode(tipo, currentNumber, nivel);

                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'almacen_id', valor: dto.almacen_id },
                        { nombre: 'codigo', valor: codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                });

                const ubicacion = manager.create(Ubicacion, {
                    ...dto,
                    usuario_id_registro: Number(usuarioId),
                });

                try {
                    const saved = await manager.save(ubicacion);
                    const result = await this.findOne<UbicacionResponseDto>(saved.ubicacion_id, usuarioId, manager);
                    results.push(result);
                } catch (error: unknown) {
                    if (isDomainException(error)) {
                        throw error;
                    }

                    const errorMessage = getErrorMessage(error);
                    this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                    throw crearError(error, 'la ubicación', 'crear');
                }
            }

            return results.length === 1 ? results[0] : (results as any);
        });
    }

    async update(id: number, dto: UpdateUbicacionDto, usuarioId: number): Promise<UbicacionResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const ubicacionActual = await manager.findOne(Ubicacion, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!ubicacionActual) {
                throw new DomainException(
                    'Registro de ubicación no encontrado.',
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindUbicacionesQueryDto.getDependencias(),
                FindUbicacionesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.almacen_id !== undefined && dtoProcesado.almacen_id !== ubicacionActual.almacen_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dtoProcesado.almacen_id)
                );

                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen_id', valor: dtoProcesado.almacen_id },
                            { nombre: 'codigo', valor: ubicacionActual.codigo }
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

            if (dtoProcesado.almacen_id !== undefined) {
                ubicacionActual.almacen_id = dtoProcesado.almacen_id;
            }

            if (dtoProcesado.descripcion !== undefined) {
                ubicacionActual.descripcion = dtoProcesado.descripcion;
            }

            ubicacionActual.update(usuarioId);

            try {
                await manager.save(ubicacionActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la ubicación', 'actualizar');
            }
        });
    }
}
