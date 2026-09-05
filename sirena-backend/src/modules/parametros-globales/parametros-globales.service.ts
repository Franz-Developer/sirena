// C:\sirena\sirena-backend\src\modules\parametros-globales\parametros-globales.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoDato } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateParametroGlobalDto } from './dto/create-parametro-global.dto';
import { FindParametrosGlobalesQueryDto } from './dto/find-parametros-globales-query.dto';
import { ParametroGlobalResponseDto } from './dto/parametro-global-response.dto';
import { UpdateParametroGlobalDto } from './dto/update-parametro-global.dto';
import { ParametroGlobal } from './entities/parametro-global.entity';

@Injectable()
export class ParametrosGlobalesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'parametros_globales',
        nombreEntidad: 'Parametro Global',
        campoPK: 'parametro_id',
        alias: 't',
        responseDto: ParametroGlobalResponseDto,
        camposBusquedaEnQ: FindParametrosGlobalesQueryDto.getCamposParaQ(),
        tablasDependientes: [],
        joins: [],
        configuracionFiltros: [
            {
                nombreCampo: 'tipo_dato_id',
                nombreColumna: 'tipo_dato_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'editable',
                nombreColumna: 'editable',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'parametro_id',
            camposPermitidosParaOrdenar: FindParametrosGlobalesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindParametrosGlobalesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindParametrosGlobalesQueryDto.getCamposProtegidosConDependencias(),
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

    private validarReglasNegocio(dto: CreateParametroGlobalDto | UpdateParametroGlobalDto | any): void {
        // 1. Validar que el valor sea compatible con el tipo de dato usando el Enum TipoDato
        if (dto.tipo_dato_id !== undefined && dto.valor !== undefined) {
            const tipo = dto.tipo_dato_id;
            const valor = dto.valor;

            switch (tipo) {
                case TipoDato.INTEGER:
                    if (!/^-?\d+$/.test(valor)) {
                        throw new DomainException(
                            'El valor debe ser un número entero válido para el tipo INTEGER.',
                            { httpStatus: HttpStatus.BAD_REQUEST }
                        );
                    }
                    break;
                case TipoDato.DECIMAL:
                    if (!/^-?\d+(\.\d+)?$/.test(valor)) {
                        throw new DomainException(
                            'El valor debe ser un número decimal válido para el tipo DECIMAL.',
                            { httpStatus: HttpStatus.BAD_REQUEST }
                        );
                    }
                    break;
                case TipoDato.BOOLEAN:
                    if (!/^[01]$/.test(valor)) {
                        throw new DomainException(
                            'El valor debe ser 0 o 1 para el tipo BOOLEAN.',
                            { httpStatus: HttpStatus.BAD_REQUEST }
                        );
                    }
                    break;
                case TipoDato.TIMESTAMP:
                    if (isNaN(new Date(valor).getTime())) {
                        throw new DomainException(
                            'El valor debe ser una fecha válida en formato ISO 8601 para el tipo TIMESTAMP.',
                            { httpStatus: HttpStatus.BAD_REQUEST }
                        );
                    }
                    break;
                case TipoDato.JSONB:
                    if (dto.datos_json === undefined || dto.datos_json === null) {
                        throw new DomainException(
                            'El campo datos_json es obligatorio cuando tipo_dato_id es JSONB.',
                            { httpStatus: HttpStatus.BAD_REQUEST }
                        );
                    }
                    break;
            }
        }
    }

    async create(dto: CreateParametroGlobalDto, usuarioId: number): Promise<ParametroGlobalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const dtoNormalizado = { ...dto };

            this.validarReglasNegocio(dtoNormalizado);

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'clave', valor: dto.clave }
                    ],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    clave,
                    valor,
                    tipo_dato_id,
                    datos_json,
                    descripcion,
                    editable,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dtoNormalizado.clave,
                dtoNormalizado.valor,
                dtoNormalizado.tipo_dato_id,
                dtoNormalizado.datos_json,
                dtoNormalizado.descripcion,
                dtoNormalizado.editable,
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
                        `Error al insertar el parámetro global "${dtoNormalizado.clave}".`,
                        { clave: dtoNormalizado.clave, httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                if (dtoNormalizado.clave === 'gestion_activa') {
                    this.tablaValidador.invalidarCacheGestion();
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

    async update(id: number, dto: UpdateParametroGlobalDto, usuarioId: number): Promise<ParametroGlobalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);
            this.validarReglasNegocio(dtoNormalizado);

            const parametroActual = await manager.findOne(ParametroGlobal, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!parametroActual) {
                throw new DomainException(
                    `Parámetro global no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            // Centralización de dependencias y permisos de Administrador (1 sola línea)
            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindParametrosGlobalesQueryDto.getDependencias(),
                FindParametrosGlobalesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (parametroActual.editable === 0) {
                throw new DomainException(
                    `El parámetro "${parametroActual.clave}" no es editable.`,
                    { httpStatus: HttpStatus.FORBIDDEN }
                );
            }

            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.clave && dtoNormalizado.clave !== parametroActual.clave) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'clave', valor: dtoNormalizado.clave }
                        ],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS],
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            const claveAnterior = parametroActual.clave;
            Object.assign(parametroActual, dtoNormalizado);
            parametroActual.update(usuarioId);

            try {
                await manager.save(parametroActual);

                if (claveAnterior === 'gestion_activa' || parametroActual.clave === 'gestion_activa') {
                    this.tablaValidador.invalidarCacheGestion();
                }

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
