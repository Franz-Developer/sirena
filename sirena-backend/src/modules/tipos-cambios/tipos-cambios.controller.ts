// C:\sirena\sirena-backend\src\modules\tipos-cambios\tipos-cambios.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateTipoCambioDto } from './dto/create-tipo-cambio.dto';
import { ConvertirMonedaDto } from './dto/convertir-moneda.dto';
import { TipoCambioResponseDto } from './dto/tipo-cambio-response.dto';
import { FindTiposCambiosQueryDto } from './dto/find-tipos-cambios-query.dto';
import { UpdateTipoCambioDto } from './dto/update-tipo-cambio.dto';
import { TiposCambiosService } from './tipos-cambios.service';

@UseGuards(JwtAuthGuard)
@Controller('tipos_cambios')
export class TiposCambiosController {
    constructor(
        private readonly tiposCambiosService: TiposCambiosService,
    ) {}

    // GET /tipos_cambios - Listar tipos de cambios
    @Get()
    @FindAllRateLimit()
    @Cache('tipos_cambios', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindTiposCambiosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<TipoCambioResponseDto>> {
        return this.tiposCambiosService.findAll(query, user.usuario_id);
    }

    // GET /tipos_cambios/:id - Obtener un tipo de cambio por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('tipos_cambios', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.findOne(id, user.usuario_id);
    }

    // POST /tipos_cambios - Crear tipo de cambio
    @Post()
    @CreateRateLimit()
    @InvalidateCache('tipos_cambios')
    create(
        @Body() dto: CreateTipoCambioDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.create(dto, user.usuario_id);
    }

    // POST /tipos_cambios/convertir/bolivianos_a_dolares - Convertir BOB a USD
    @Post('convertir/bolivianos_a_dolares')
    @CreateRateLimit()
    async convertirBolivianosADolares(
        @Body() dto: ConvertirMonedaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<{
        montoDolares: number;
        factorUsado: number;
        tipoCambioId: number;
        origen: { id: number; abreviatura: string; prefijo: string };
        destino: { id: number; abreviatura: string; prefijo: string };
    }> {
        return this.tiposCambiosService.convertirBolivianosADolares(
            dto.monto_bolivianos,
            dto.fecha_cotizacion,
            user.usuario_id
        );
    }

    // PATCH /tipos_cambios/:id - Actualizar tipo de cambio
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('tipos_cambios')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateTipoCambioDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.update(id, dto, user.usuario_id);
    }

    // DELETE /tipos_cambios/:id - Eliminar tipo de cambio (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('tipos_cambios')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.remove<TipoCambioResponseDto>(id, user.usuario_id);
    }

    // PATCH /tipos_cambios/:id/archivar - Archivar tipo de cambio (pasar a histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('tipos_cambios')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.archivar<TipoCambioResponseDto>(id, user.usuario_id);
    }

    // PATCH /tipos_cambios/:id/desarchivar - Desarchivar tipo de cambio (volver a activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('tipos_cambios')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TipoCambioResponseDto> {
        return this.tiposCambiosService.desarchivar<TipoCambioResponseDto>(id, user.usuario_id);
    }
}
