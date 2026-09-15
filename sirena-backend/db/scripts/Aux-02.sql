
CREATE TABLE almacenes (
    almacen_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    almacen VARCHAR(200) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    tipo_almacen_id SMALLINT NOT NULL DEFAULT 1700,              -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    tipo_operacion_almacen_id SMALLINT NOT NULL DEFAULT 4050,    -- 4050=LOGISTICA_INTERNA, 4051=VENTA_DIRECTA
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_almacenes_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_almacenes_tipoalmacenid CHECK (
        tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)
        AND (
            (tipo_operacion_almacen_id = 4050 AND tipo_almacen_id IN (1704, 1709, 1710, 1711, 1712))
            OR
            (tipo_operacion_almacen_id = 4051 AND tipo_almacen_id IN (1700, 1701, 1702, 1703, 1705, 1706, 1707, 1708))
        )
    ),
    CONSTRAINT chk_almacenes_tipooperacionalmacenid CHECK (tipo_operacion_almacen_id IN (4050, 4051)),
    CONSTRAINT chk_almacenes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_almacenes_almacen_notempty CHECK (TRIM(almacen) <> ''),
    CONSTRAINT chk_almacenes_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_almacenes_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_almacenes_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_almacenes_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$')
);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_almacenid_unique ON almacenes (sucursal_id, almacen_id);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_almacen_unique ON almacenes (sucursal_id, almacen) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_codigo_unique ON almacenes (sucursal_id, codigo) WHERE estado_id IN (1000, 1002);

CREATE TABLE ubicaciones (
    ubicacion_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
	codigo VARCHAR(60) NOT NULL,
    jerarquia JSONB NOT NULL DEFAULT '{}'::jsonb,
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ubicaciones_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
	CONSTRAINT chk_ubicaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ubicaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
	CONSTRAINT chk_ubicaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_ubicaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_ubicaciones_jerarquia_estructura CHECK (
        jerarquia IS NULL OR
        jsonb_typeof(jerarquia) = 'object' AND
        (jerarquia ? 'niveles' OR jerarquia ? 'camino')
    )
);
CREATE UNIQUE INDEX uix_ubicaciones_varios_unique ON ubicaciones (almacen_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ubicaciones_jerarquia ON ubicaciones USING GIN (jerarquia);

// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts

export interface ConstanteMetadata {
    id: number;
    abreviatura: string;
    prefijo: string | null;
    valor: number;
    descripcion: string;
}

// ==========================================
// ESTADO
// ==========================================
export enum Estado {
    ACTIVO = 1000,
    BORRADO = 1001,
    HISTORICO = 1002,
    ANULADO = 1003,
}

export const ESTADO_ACTIVO = Estado.ACTIVO;
export const ESTADO_HISTORICO = Estado.HISTORICO;
export const ESTADO_BORRADO = Estado.BORRADO;
export const ESTADO_ANULADO = Estado.ANULADO;

export const ESTADOS_CONSULTA = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO,
	] as const;

export const ESTADOS_PERMITIDOS = [
    Estado.ACTIVO,
    Estado.BORRADO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    Estado.ACTIVO,
    Estado.HISTORICO
	] as const;

export const ESTADOS_VIVOS_ESPECIAL = [
Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO
] as const;

export const ESTADO_METADATA: Record<Estado, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};

para ubicaciones.service.ts 
como seria poner mensajePersonalizado 

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
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId, undefined, 'El usuario del sistema no se encuentra activo o no existe.')
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

ejemplo 
async create(dto: CreateSucursalDto, usuarioId: number): Promise<SucursalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const nombreEmpresa = await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id, 't.empresa');

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal', valor: dto.sucursal }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe una sucursal con el nombre '${dto.sucursal}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'sucursal_largo', valor: dto.sucursal_largo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe una sucursal con el nombre largo '${dto.sucursal_largo}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo', valor: dto.codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un registro con el código '${dto.codigo}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: dto.empresa_id },
                        { nombre: 'codigo_sin', valor: dto.codigo_sin }
                    ],
                    estadosValidos: [ESTADO_ACTIVO],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un registro con código sin '${dto.codigo_sin}' para la empresa '${nombreEmpresa}'.`,
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId, undefined, 'El usuario del sistema no se encuentra activo o no existe.')
            ]);

            const sucursal = manager.create(Sucursal, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(sucursal);
                return this.findOne<SucursalResponseDto>(saved.sucursal_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la sucursal', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateSucursalDto, usuarioId: number): Promise<SucursalResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const sucursalActual = await manager.findOne(Sucursal, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!sucursalActual) {
                throw new DomainException(
                    'Sucursal no encontrada.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindSucursalesQueryDto.getDependencias(),
                FindSucursalesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const empresaIdEval = dtoProcesado.empresa_id ?? sucursalActual.empresa_id;
            const nombreEmpresa = await this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', empresaIdEval, 't.empresa');

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.sucursal !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorSucursal = dtoProcesado.sucursal ?? sucursalActual.sucursal;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal', valor: dtoProcesado.sucursal ?? sucursalActual.sucursal }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe una sucursal con el nombre '${valorSucursal}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.sucursal_largo !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorSucursalLargo = dtoProcesado.sucursal_largo ?? sucursalActual.sucursal_largo;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'sucursal_largo', valor: dtoProcesado.sucursal_largo ?? sucursalActual.sucursal_largo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe una sucursal con el nombre largo '${valorSucursalLargo}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.codigo !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorCodigo = dtoProcesado.codigo ?? sucursalActual.codigo;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo', valor: dtoProcesado.codigo ?? sucursalActual.codigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe un registro con el código '${valorCodigo}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (dtoProcesado.codigo_sin !== undefined || dtoProcesado.empresa_id !== undefined) {
                const valorCodigoSin = dtoProcesado.codigo_sin ?? sucursalActual.codigo_sin;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'empresa_id', valor: empresaIdEval },
                            { nombre: 'codigo_sin', valor: dtoProcesado.codigo_sin ?? sucursalActual.codigo_sin }
                        ],
                        idExcluir: id,
                        estadosValidos: [ESTADO_ACTIVO],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe un registro con código sin '${valorCodigoSin}' para la empresa '${nombreEmpresa}'.`,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(sucursalActual, dtoProcesado);
            sucursalActual.update(usuarioId);

            try {
                await manager.save(sucursalActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la sucursal', 'actualizar');
            }
        });
    }