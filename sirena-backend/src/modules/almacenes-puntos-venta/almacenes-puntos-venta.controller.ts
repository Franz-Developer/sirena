// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\almacenes-puntos-venta.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateAlmacenPuntoVentaDto } from './dto/create-almacen-punto-venta.dto';
import { AlmacenPuntoVentaResponseDto } from './dto/almacen-punto-venta-response.dto';
import { FindAlmacenesPuntosVentaQueryDto } from './dto/find-almacenes-puntos-venta-query.dto';
import { UpdateAlmacenPuntoVentaDto } from './dto/update-almacen-punto-venta.dto';
import { AlmacenesPuntosVentaService } from './almacenes-puntos-venta.service';

@UseGuards(JwtAuthGuard)
@Controller('almacenes-puntos-venta')
export class AlmacenesPuntosVentaController {
    constructor(
        private readonly almacenesPuntosVentaService: AlmacenesPuntosVentaService,
    ) {}

    // GET /almacenes-puntos-venta - Listar relaciones almacén-punto de venta
    @Get()
    @FindAllRateLimit()
    @Cache('almacenes_puntos_venta', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindAlmacenesPuntosVentaQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<AlmacenPuntoVentaResponseDto>> {
        return this.almacenesPuntosVentaService.findAll(query, user.usuario_id);
    }

    // GET /almacenes-puntos-venta/:id - Obtener una relación por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('almacenes_puntos_venta', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.findOne(id, user.usuario_id);
    }

    // POST /almacenes-puntos-venta - Crear relación almacén-punto de venta
    @Post()
    @CreateRateLimit()
    @InvalidateCache('almacenes_puntos_venta')
    create(
        @Body() dto: CreateAlmacenPuntoVentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.create(dto, user.usuario_id);
    }

    // PATCH /almacenes-puntos-venta/:id - Actualizar relación
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('almacenes_puntos_venta')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateAlmacenPuntoVentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.update(id, dto, user.usuario_id);
    }

    // DELETE /almacenes-puntos-venta/:id - Eliminar relación (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('almacenes_puntos_venta')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.remove<AlmacenPuntoVentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /almacenes-puntos-venta/:id/archivar - Archivar relación (histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('almacenes_puntos_venta')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.archivar<AlmacenPuntoVentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /almacenes-puntos-venta/:id/desarchivar - Desarchivar relación (activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('almacenes_puntos_venta')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<AlmacenPuntoVentaResponseDto> {
        return this.almacenesPuntosVentaService.desarchivar<AlmacenPuntoVentaResponseDto>(id, user.usuario_id);
    }
}
