ARCHIVO CONSOLIDADO TYPESCRIPT (.TS) 
============================================ 
Generado: lun 07/09/2026 21:16:21,30 
Directorio analizado: C:\sirena\sirena-backend\src\modules\almacenes 
============================================ 
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\almacenes.controller.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateAlmacenDto } from './dto/create-almacen.dto';
import { AlmacenResponseDto } from './dto/almacen-response.dto';
import { FindAlmacenesQueryDto } from './dto/find-almacenes-query.dto';
import { UpdateAlmacenDto } from './dto/update-almacen.dto';
import { AlmacenesService } from './almacenes.service';

@UseGuards(JwtAuthGuard)
@Controller('almacenes')
export class AlmacenesController {
    constructor(
        private readonly almacenesService: AlmacenesService,
    ) {}

    // GET /almacenes - Listar almacenes
    @Get()
    @FindAllRateLimit()
    @Cache('almacenes', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindAlmacenesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<AlmacenResponseDto>> {
        return this.almacenesService.findAll(query, user.usuario_id);
    }

    // GET /almacenes/:id - Obtener un almacén
    @Get(':id')
    @FindOneRateLimit()
    @Cache('almacenes', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.findOne(id, user.usuario_id);
    }

    // POST /almacenes - Crear almacén
    @Post()
    @CreateRateLimit()
    @InvalidateCache('almacenes')
    create(
        @Body() dto: CreateAlmacenDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.create(dto, user.usuario_id);
    }

    // PATCH /almacenes/:id - Actualizar almacén
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('almacenes')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateAlmacenDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.update(id, dto, user.usuario_id);
    }

    // DELETE /almacenes/:id - Eliminar almacén (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('almacenes')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.remove<AlmacenResponseDto>(id, user.usuario_id);
    }

    // PATCH /almacenes/:id/archivar - Archivar almacén
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('almacenes')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.archivar<AlmacenResponseDto>(id, user.usuario_id);
    }

    // PATCH /almacenes/:id/desarchivar - Desarchivar almacén
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('almacenes')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenResponseDto> {
        return this.almacenesService.desarchivar<AlmacenResponseDto>(id, user.usuario_id);
    }
}
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\almacenes.module.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlmacenesController } from './almacenes.controller';
import { AlmacenesService } from './almacenes.service';
import { Almacen } from './entities/almacen.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Almacen]),
        ConfigModule,
    ],
    controllers: [AlmacenesController],
    providers: [AlmacenesService],
    exports: [AlmacenesService],
})
export class AlmacenesModule {}
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA, TIPOS_ALMACEN_VENTA_DIRECTA, TIPOS_ALMACEN_LOGISTICA_INTERNA, TIPO_ALMACEN_METADATA, TipoAlmacen } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateAlmacenDto } from './dto/create-almacen.dto';
import { AlmacenResponseDto } from './dto/almacen-response.dto';
import { FindAlmacenesQueryDto } from './dto/find-almacenes-query.dto';
import { UpdateAlmacenDto } from './dto/update-almacen.dto';
import { Almacen } from './entities/almacen.entity';

@Injectable()
export class AlmacenesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'almacenes',
        nombreEntidad: 'Almacen',
        campoPK: 'almacen_id',
        alias: 't',
        responseDto: AlmacenResponseDto,
        camposBusquedaEnQ: FindAlmacenesQueryDto.getCamposParaQ(),
        tablasDependientes: FindAlmacenesQueryDto.getDependencias(),
        joins: [
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = t.sucursal_id',
                selectColumns: [
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'sucursal_id',
                nombreColumna: 'sucursal_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_almacen_id',
                nombreColumna: 'tipo_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_operacion_almacen_id',
                nombreColumna: 'tipo_operacion_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'almacen_id',
            camposPermitidosParaOrdenar: FindAlmacenesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindAlmacenesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
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

    private validarCombinacionTipoAlmacen(
        tipoOperacionId: number,
        tipoAlmacenId: number
    ): void {
        const combinacionesValidas: Record<number, number[]> = {
            [TipoOperacionAlmacen.LOGISTICA_INTERNA]: [
                ...TIPOS_ALMACEN_LOGISTICA_INTERNA
            ],
            [TipoOperacionAlmacen.VENTA_DIRECTA]: [
                ...TIPOS_ALMACEN_VENTA_DIRECTA
            ],
        };

        const tiposPermitidos = combinacionesValidas[tipoOperacionId];
        if (!tiposPermitidos) {
            const operacionesValidas = Object.keys(combinacionesValidas)
                .map(id => {
                    const meta = TIPO_OPERACION_ALMACEN_METADATA[Number(id) as TipoOperacionAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');
            throw new DomainException(
                `tipo_operacion_almacen_id "${tipoOperacionId}" no es válido. ` +
                `Valores permitidos: ${operacionesValidas}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (!tiposPermitidos.includes(tipoAlmacenId)) {
            const operacionMeta = TIPO_OPERACION_ALMACEN_METADATA[tipoOperacionId as TipoOperacionAlmacen];
            const operacionNombre = operacionMeta?.abreviatura ?? 'DESCONOCIDO';

            const tiposPermitidosStr = tiposPermitidos
                .map(id => {
                    const meta = TIPO_ALMACEN_METADATA[id as TipoAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');

            throw new DomainException(
                `Combinación inválida: tipo_operacion_almacen_id "${tipoOperacionId}" (${operacionNombre}) ` +
                `no permite tipo_almacen_id "${tipoAlmacenId}". ` +
                `Tipos permitidos: ${tiposPermitidosStr}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'almacen', valor: dto.almacen },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'codigo', valor: dto.codigo },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                })
            ]);

            this.validarCombinacionTipoAlmacen(
                dto.tipo_operacion_almacen_id,
                dto.tipo_almacen_id
            );

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    almacen,
                    codigo,
                    tipo_almacen_id,
                    tipo_operacion_almacen_id,
                    descripcion,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.almacen,
                dto.codigo,
                dto.tipo_almacen_id,
                dto.tipo_operacion_almacen_id,
                dto.descripcion || null,
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
                        'Error al insertar el almacén.',
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

    async update(id: number, dto: UpdateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const almacenActual = await manager.findOne(Almacen, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!almacenActual) {
                throw new DomainException(
                    `Almacén no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindAlmacenesQueryDto.getDependencias(),
                FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id)
                );
            }

            if (
                (dto.almacen !== undefined && dto.almacen !== almacenActual.almacen) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen', valor: dto.almacen ?? almacenActual.almacen },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (
                (dto.codigo !== undefined && dto.codigo !== almacenActual.codigo) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'codigo', valor: dto.codigo ?? almacenActual.codigo },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
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

            const operacionId = dto.tipo_operacion_almacen_id ?? almacenActual.tipo_operacion_almacen_id;
            const tipoId = dto.tipo_almacen_id ?? almacenActual.tipo_almacen_id;

            if (dto.tipo_operacion_almacen_id !== undefined || dto.tipo_almacen_id !== undefined) {
                this.validarCombinacionTipoAlmacen(operacionId, tipoId);
            }

            Object.assign(almacenActual, dto);
            almacenActual.update(usuarioId);

            try {
                await manager.save(almacenActual);

                const updatedRecord = await manager.findOne(Almacen, {
                    where: { [this.campoPK]: id }
                });

                if (!updatedRecord) {
                    throw new DomainException('No se pudo recuperar el registro actualizado.', {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    });
                }

                const responseDto = new AlmacenResponseDto();
                Object.assign(responseDto, updatedRecord);

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
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\dto\almacen-response.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\dto\almacen-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: AlmacenRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoAlmacen = (tipoAlmacenId: unknown) => {
    const id = Number(tipoAlmacenId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_ALMACEN_METADATA[id as TipoAlmacen];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

const transformTipoOperacionAlmacen = (tipoOperacionId: unknown) => {
    const id = Number(tipoOperacionId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_OPERACION_ALMACEN_METADATA[id as TipoOperacionAlmacen];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface AlmacenRawResult {
    almacen_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    almacen: string;
    codigo: string;
    tipo_almacen_id: string | number;
    tipo_operacion_almacen_id: string | number;
    descripcion: string | null;
    estado_id: string | number;
    estado_registro: string;
    usuario_operacion: string;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number | null;
    usuario_id_baja?: string | number | null;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date | null;
    fecha_baja?: string | Date | null;
    total_count?: string | number;
    tiene_dependencias?: boolean;
    campos_protegidos?: string[];
}

export class AlmacenResponseDto {
    @Expose() almacen_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose() almacen!: string;
    @Expose() codigo!: string;
    @Expose() tipo_almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoAlmacen(obj.tipo_almacen_id))
    tipo_almacen!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() tipo_operacion_almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoOperacionAlmacen(obj.tipo_operacion_almacen_id))
    tipo_operacion_almacen!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() descripcion?: string | null;
    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose() usuario_operacion!: string;
    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number | null;
    @Expose() usuario_id_baja?: number | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose() tiene_dependencias!: boolean;
    @Expose() campos_protegidos?: string[];
	}
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\dto\create-almacen.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\dto\create-almacen.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateAlmacenDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number = 1;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'almacen debe ser un texto.' })
    @IsNotEmpty({ message: 'almacen es obligatorio.' })
    @MinLength(1, { message: 'almacen debe tener al menos 1 carácter.' })
    @MaxLength(200, { message: 'almacen no puede exceder los 200 caracteres.' })
    @IsSafeText()
    almacen: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'codigo debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo es obligatorio.' })
    @MinLength(3, { message: 'codigo debe tener al menos 3 caracteres.' })
    @MaxLength(60, { message: 'codigo no puede exceder los 60 caracteres.' })
    @Matches(/^[A-Z0-9_-]+$/, { message: 'codigo debe contener solo letras mayúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    codigo: string;

    @IsInt({ message: 'tipo_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoAlmacen), {
        message: createEnumMessage(TIPO_ALMACEN_METADATA, getEnumValues(TipoAlmacen), 'tipo_almacen_id')
    })
    tipo_almacen_id: number;

    @IsInt({ message: 'tipo_operacion_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoOperacionAlmacen), {
        message: createEnumMessage(TIPO_OPERACION_ALMACEN_METADATA, getEnumValues(TipoOperacionAlmacen), 'tipo_operacion_almacen_id')
    })
    tipo_operacion_almacen_id: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(500, { message: 'descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\dto\find-almacenes-query.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\dto\find-almacenes-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindAlmacenesQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 (flexible) o 1 (exacta).' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    @Type(() => Number)
    @IsInt({ message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    @Min(1, { message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    sucursal_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoAlmacen), {
        message: createEnumMessage(TIPO_ALMACEN_METADATA, getEnumValues(TipoAlmacen), 'tipo_almacen_id')
    })
    tipo_almacen_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_operacion_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoOperacionAlmacen), {
        message: createEnumMessage(TIPO_OPERACION_ALMACEN_METADATA, getEnumValues(TipoOperacionAlmacen), 'tipo_operacion_almacen_id')
    })
    tipo_operacion_almacen_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        return [
            `${alias}.almacen_id`,
            `${alias}.sucursal_id`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${alias}.almacen`,
            `${alias}.codigo`,
            `${alias}.tipo_almacen_id`,
            `${alias}.tipo_operacion_almacen_id`,
            `${alias}.descripcion`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['almacen', 'codigo', 'descripcion', 's.sucursal', 's.codigo'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'almacen_id',
            'sucursal_id',
            'almacen',
            'codigo',
            'tipo_almacen_id',
            'tipo_operacion_almacen_id',
            'sucursal_nombre',
            'sucursal_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'ubicaciones', campoFk: 'almacen_id' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'almacen_id' },
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['sucursal_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        return {
            'almacen_id': `${alias}.almacen_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'almacen': `${alias}.almacen`,
            'codigo': `${alias}.codigo`,
            'tipo_almacen_id': `${alias}.tipo_almacen_id`,
            'tipo_operacion_almacen_id': `${alias}.tipo_operacion_almacen_id`,
            'descripcion': `${alias}.descripcion`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`
        };
    }
}

export { PaginatedResult };
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\dto\update-almacen.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\dto\update-almacen.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateAlmacenDto } from './create-almacen.dto';

export class UpdateAlmacenDto extends PartialType(CreateAlmacenDto) {}
 
 
---- C:\sirena\sirena-backend\src\modules\almacenes\entities\almacen.entity.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\almacenes\entities\almacen.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'almacenes' })
@Check('chk_almacenes_tipoalmacenid', `
    tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)
    AND (
        (tipo_operacion_almacen_id = 4050 AND tipo_almacen_id IN (1704, 1709, 1710, 1711, 1712))
        OR
        (tipo_operacion_almacen_id = 4051 AND tipo_almacen_id IN (1700, 1701, 1702, 1703, 1705, 1706, 1707, 1708))
    )
`)
@Check('chk_almacenes_tipooperacionalmacenid', 'tipo_operacion_almacen_id IN (4050, 4051)')
@Check('chk_almacenes_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_almacenes_almacen_notempty', "TRIM(almacen) <> ''")
@Check('chk_almacenes_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_almacenes_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_almacenes_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_almacenes_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Index('uix_almacenes_sucursalid_almacenid_unique', ['sucursal_id', 'almacen_id'], { unique: true })
@Index('uix_almacenes_sucursalid_almacen_unique', ['sucursal_id', 'almacen'], { unique: true, where: "estado_id IN (1000, 1002)" })
@Index('uix_almacenes_sucursalid_codigo_unique', ['sucursal_id', 'codigo'], { unique: true, where: "estado_id IN (1000, 1002)" })
export class Almacen extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'almacen_id', type: 'bigint' })
    almacen_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'almacen', type: 'varchar', length: 200, nullable: false })
    almacen!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'tipo_almacen_id', type: 'smallint', nullable: false, default: 1700 })
    tipo_almacen_id!: number;

    @Column({ name: 'tipo_operacion_almacen_id', type: 'smallint', nullable: false, default: 4050 })
    tipo_operacion_almacen_id!: number;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string | null;
}
 
 
============================================ 
RESUMEN DE ARCHIVOS CONSOLIDADOS: 
============================================ 
[1] C:\sirena\sirena-backend\src\modules\almacenes\almacenes.controller.ts 
[2] C:\sirena\sirena-backend\src\modules\almacenes\almacenes.module.ts 
[3] C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts 
[4] C:\sirena\sirena-backend\src\modules\almacenes\dto\almacen-response.dto.ts 
[5] C:\sirena\sirena-backend\src\modules\almacenes\dto\create-almacen.dto.ts 
[6] C:\sirena\sirena-backend\src\modules\almacenes\dto\find-almacenes-query.dto.ts 
[7] C:\sirena\sirena-backend\src\modules\almacenes\dto\update-almacen.dto.ts 
[8] C:\sirena\sirena-backend\src\modules\almacenes\entities\almacen.entity.ts 
============================================ 
Total de archivos procesados: 8 
============================================ 

en el servicio no se valida 