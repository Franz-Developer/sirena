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

// C:\sirena\sirena-backend\src\modules\bancos\bancos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit} from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { BancosService } from './bancos.service';
import { BancoResponseDto } from './dto/banco-response.dto';
import { CreateBancoDto } from './dto/create-banco.dto';
import { FindBancosQueryDto } from './dto/find-bancos-query.dto';
import { UpdateBancoDto } from './dto/update-banco.dto';

@UseGuards(JwtAuthGuard)
@Controller('bancos')
export class BancosController {
    constructor(
        private readonly bancosService: BancosService,
    ) {}

    // GET /bancos - Listar bancos
    @Get()
    @FindAllRateLimit()
    @Cache('bancos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindBancosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<BancoResponseDto>> {
        return this.bancosService.findAll(query, user.usuario_id);
    }

    // GET /bancos/:id - Obtener un banco
    @Get(':id')
    @FindOneRateLimit()
    @Cache('bancos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.findOne(id, user.usuario_id);
    }

    // POST /bancos - Crear banco
    @Post()
    @CreateRateLimit()
    @InvalidateCache('bancos')
    create(
        @Body() dto: CreateBancoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.create(dto, user.usuario_id);
    }

    // PATCH /bancos/:id - Actualizar banco
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('bancos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateBancoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.update(id, dto, user.usuario_id);
    }

    // DELETE /bancos/:id - Eliminar banco (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('bancos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.remove<BancoResponseDto>(id, user.usuario_id);
    }

    // PATCH /bancos/:id/archivar - Archivar banco
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('bancos')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.archivar<BancoResponseDto>(id, user.usuario_id);
    }

    // PATCH /bancos/:id/desarchivar - Desarchivar banco
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('bancos')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.desarchivar<BancoResponseDto>(id, user.usuario_id);
    }
}

para replicar la misma logica de bancos 
que se debe auemntar en 
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


// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA, TIPO_ALMACEN_PROHIBIDOS, TIPO_ALMACEN_VALIDOS, TIPO_ALMACEN_METADATA, TipoAlmacen } from '../../common/constants/estados.constant';
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
                ...TIPO_ALMACEN_PROHIBIDOS
            ],
            [TipoOperacionAlmacen.VENTA_DIRECTA]: [
                ...TIPO_ALMACEN_VALIDOS
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

SOLO dime que linea o lineas debo aumentar 
