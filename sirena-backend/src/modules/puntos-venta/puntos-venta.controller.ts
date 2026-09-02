// C:\sirena\sirena-backend\src\modules\puntos-venta\puntos-venta.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreatePuntoVentaDto } from './dto/create-punto-venta.dto';
import { PuntoVentaResponseDto } from './dto/punto-venta-response.dto';
import { FindPuntosVentaQueryDto } from './dto/find-puntos-venta-query.dto';
import { UpdatePuntoVentaDto } from './dto/update-punto-venta.dto';
import { PuntosVentaService } from './puntos-venta.service';

@UseGuards(JwtAuthGuard)
@Controller('puntos-venta')
export class PuntosVentaController {
    constructor(
        private readonly puntosVentaService: PuntosVentaService,
    ) {}

    // GET /puntos-venta - Listar puntos de venta
    @Get()
    @FindAllRateLimit()
    @Cache('puntos-venta', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindPuntosVentaQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<PuntoVentaResponseDto>> {
        return this.puntosVentaService.findAll(query, user.usuario_id);
    }

    // GET /puntos-venta/:id - Obtener un punto de venta
    @Get(':id')
    @FindOneRateLimit()
    @Cache('puntos-venta', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.findOne(id, user.usuario_id);
    }

    // POST /puntos-venta - Crear punto de venta
    @Post()
    @CreateRateLimit()
    @InvalidateCache('puntos-venta')
    create(
        @Body() dto: CreatePuntoVentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.create(dto, user.usuario_id);
    }

    // PATCH /puntos-venta/:id - Actualizar punto de venta
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('puntos-venta')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdatePuntoVentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.update(id, dto, user.usuario_id);
    }

    // DELETE /puntos-venta/:id - Eliminar punto de venta (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('puntos-venta')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.remove<PuntoVentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /puntos-venta/:id/archivar - Archivar punto de venta
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('puntos-venta')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.archivar<PuntoVentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /puntos-venta/:id/desarchivar - Desarchivar punto de venta
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('puntos-venta')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<PuntoVentaResponseDto> {
        return this.puntosVentaService.desarchivar<PuntoVentaResponseDto>(id, user.usuario_id);
    }
}
