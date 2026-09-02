// C:\sirena\sirena-backend\src\modules\ubicaciones\ubicaciones.service.ts
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
import { CreateUbicacionDto } from './dto/create-ubicacion.dto';
import { UbicacionResponseDto } from './dto/ubicacion-response.dto';
import { FindUbicacionesQueryDto } from './dto/find-ubicaciones-query.dto';
import { UpdateUbicacionDto } from './dto/update-ubicacion.dto';
import { Ubicacion } from './entities/ubicacion.entity';
import { generarCodigoUbicacion, generarJerarquiaUbicacion } from '../../common/helpers/ubicaciones.helper';
import { TipoUbicacion, CODIGO_TIPO_UBICACION } from '../../common/constants/ubicaciones.constants';

@Injectable()
export class UbicacionesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'ubicaciones',
        nombreEntidad: 'Ubicación',
        campoPK: 'ubicacion_id',
        alias: 't',
        responseDto: UbicacionResponseDto,
        camposBusquedaEnQ: FindUbicacionesQueryDto.getCamposParaQ(),
        tablasDependientes: [],
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

    async create(dto: CreateUbicacionDto, usuarioId: number): Promise<any> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dto.almacen_id);
            await this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear');

            const valor = await this.calcularSiguienteValor(dto.almacen_id, dto.tipo, manager);
            const niveles = this.obtenerNiveles(dto);

            if (niveles.length === 0) {
                throw new DomainException(
                    'Debe especificar al menos un nivel para crear ubicaciones.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            const esBatch = niveles.length > 1;
            const resultados = [];
            const errores = [];

            for (const nivel of niveles) {
                try {
                    const resultado = await this.createUbicacionIndividual(
                        dto.almacen_id,
                        dto.tipo,
                        valor,
                        nivel,
                        dto.descripcion,
                        usuarioId,
                        manager
                    );
                    resultados.push(resultado);
                } catch (error) {
                    errores.push({
                        nivel,
                        error: error instanceof Error ? error.message : 'Error desconocido'
                    });
                }
            }

            if (!esBatch && resultados.length === 1 && errores.length === 0) {
                return resultados[0];
            }

            return {
                creados: resultados,
                total_creados: resultados.length,
                total_errores: errores.length,
                errores: errores.length > 0 ? errores : undefined,
                resumen: {
                    total_solicitados: niveles.length,
                    exitosos: resultados.length,
                    fallidos: errores.length
                }
            };
        });
    }

    private async createUbicacionIndividual(
        almacenId: number,
        tipo: TipoUbicacion,
        valor: string,
        nivel: number,
        descripcionPersonalizada: string | undefined,
        usuarioId: number,
        manager: any
    ): Promise<UbicacionResponseDto> {
        const codigo = generarCodigoUbicacion(tipo, valor, nivel);
        const jerarquia = generarJerarquiaUbicacion(tipo, valor, nivel);

        const descripcion = descripcionPersonalizada
            ? `${descripcionPersonalizada} - NIVEL ${nivel}`
            : this.generarDescripcionPorDefecto(tipo, valor, nivel);

        await this.unicidadValidador.validarUnicidad({
            tabla: this.nombreTabla,
            campos: [
                { nombre: 'almacen_id', valor: almacenId },
                { nombre: 'codigo', valor: codigo }
            ],
            estadosValidos: [...ESTADOS_VIVOS],
            campoPk: this.campoPK,
        });

        const query = `
            INSERT INTO ${this.nombreTabla} (
                almacen_id,
                codigo,
                jerarquia,
                descripcion,
                estado_id,
                usuario_id_registro,
                fecha_registro
            )
            VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
            RETURNING ${this.campoPK}
        `;

        const params = [
            almacenId,
            codigo,
            JSON.stringify(jerarquia),
            descripcion,
            ESTADO_ACTIVO,
            Number(usuarioId)
        ];

        logSqlQuery(query, params, `createUbicacionIndividual - ${this.nombreTabla}`);

        await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
        const insertResult = await manager.query(query, params);
        const newId = Number(insertResult[0]?.[this.campoPK] || 0);

        if (newId === 0) {
            throw new DomainException(
                'Error al insertar el registro de ubicación.',
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }

        return this.findOne(newId, usuarioId, manager);
    }

    private async calcularSiguienteValor(
        almacenId: number,
        tipo: TipoUbicacion,
        manager: any
    ): Promise<string> {
        const prefijo = CODIGO_TIPO_UBICACION[tipo];

        const query = `
            SELECT codigo
            FROM ${this.nombreTabla}
            WHERE almacen_id = $1
                AND codigo LIKE $2
                AND estado_id IN (${ESTADOS_VIVOS.join(', ')})
            ORDER BY codigo ASC
        `;

        const params = [almacenId, `${prefijo}-%`];
        logSqlQuery(query, params, `calcularSiguienteValor - ${this.nombreTabla}`);

        const resultados = await manager.query(query, params);

        if (!resultados || resultados.length === 0) {
            return '01';
        }

        const numerosExistentes: number[] = [];
        for (const row of resultados) {
            const match = row.codigo.match(new RegExp(`${prefijo}-(\\d+)`));
            if (match) {
                numerosExistentes.push(parseInt(match[1], 10));
            }
        }

        if (numerosExistentes.length === 0) {
            return '01';
        }

        numerosExistentes.sort((a, b) => a - b);

        let siguienteNumero = 1;
        for (const num of numerosExistentes) {
            if (num === siguienteNumero) {
                siguienteNumero++;
            } else if (num > siguienteNumero) {
                break;
            }
        }

        return String(siguienteNumero).padStart(2, '0');
    }

    private obtenerNiveles(dto: CreateUbicacionDto): number[] {
        const cantidad = dto.niveles ?? 1;
        return Array.from({ length: cantidad }, (_, i) => i + 1);
    }

    private generarDescripcionPorDefecto(tipo: TipoUbicacion, valor: string, nivel: number): string {
        const nombres: Record<string, string> = {
            'ESTANTERIA': 'Estantería',
            'RACK': 'Rack',
            'VITRINA': 'Vitrina',
            'REFRIGERADOR': 'Refrigerador',
            'CONGELADOR': 'Congelador',
            'ARMARIO': 'Armario',
            'CAJA_FUERTE': 'Caja Fuerte',
            'GAVETA': 'Gaveta',
            'ZONA': 'Zona',
            'PALETIZADO': 'Pallet',
            'ANAQUEL': 'Anaquél',
            'EXHIBIDOR': 'Exhibidor',
            'BANDEJA': 'Bandeja',
        };

        const nombre = nombres[tipo] || tipo;
        return `${nombre} ${valor} - NIVEL ${nivel}`;
    }

    async update(
        id: number,
        dto: UpdateUbicacionDto,
        usuarioId: number
    ): Promise<UbicacionResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(
                this.nombreTabla,
                id,
                dtoNormalizado,
                this.campoPK,
                usuarioId
            );

            const ubicacionActual = await manager.findOne(Ubicacion, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!ubicacionActual) {
                throw new DomainException(
                    'Registro de ubicación no encontrado.',
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindUbicacionesQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindUbicacionesQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach((campo) => {
                    if (campo in dtoNormalizado) {
                        delete (dtoNormalizado as any)[campo];
                    }
                });
            }

            const validaciones: Promise<any>[] = [];

            if (
                dtoNormalizado.almacen_id !== undefined &&
                !tieneDependencias &&
                dtoNormalizado.almacen_id !== ubicacionActual.almacen_id
            ) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos(
                        'almacenes',
                        'almacen_id',
                        dtoNormalizado.almacen_id
                    )
                );

                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen_id', valor: dtoNormalizado.almacen_id },
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

            if (dtoNormalizado.almacen_id !== undefined && !tieneDependencias) {
                ubicacionActual.almacen_id = dtoNormalizado.almacen_id;
            }

            if (dtoNormalizado.descripcion !== undefined) {
                ubicacionActual.descripcion = dtoNormalizado.descripcion;
            }

            ubicacionActual.update(usuarioId);

            try {
                await manager.save(ubicacionActual);
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
