// C:\sirena\sirena-backend\src\modules\ubicaciones\ubicaciones.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateUbicacionDto } from './dto/create-ubicacion.dto';
import { UbicacionResponseDto } from './dto/ubicacion-response.dto';
import { FindUbicacionesQueryDto } from './dto/find-ubicaciones-query.dto';
import { UpdateUbicacionDto } from './dto/update-ubicacion.dto';
import { UbicacionesService } from './ubicaciones.service';

@UseGuards(JwtAuthGuard)
@Controller('ubicaciones')
export class UbicacionesController {
    constructor(
        private readonly ubicacionesService: UbicacionesService,
    ) {}

    // GET /ubicaciones - Listar ubicaciones
    @Get()
    @FindAllRateLimit()
    @Cache('ubicaciones', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindUbicacionesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<UbicacionResponseDto>> {
        return this.ubicacionesService.findAll(query, user.usuario_id);
    }

    // GET /ubicaciones/:id - Obtener una ubicación por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('ubicaciones', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.findOne(id, user.usuario_id);
    }

    // POST /ubicaciones - Crear ubicación
    @Post()
    @CreateRateLimit()
    @InvalidateCache('ubicaciones')
    create(
        @Body() dto: CreateUbicacionDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.create(dto, user.usuario_id);
    }

    // PATCH /ubicaciones/:id - Actualizar ubicación
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('ubicaciones')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateUbicacionDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.update(id, dto, user.usuario_id);
    }

    // DELETE /ubicaciones/:id - Eliminar ubicación (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('ubicaciones')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.remove<UbicacionResponseDto>(id, user.usuario_id);
    }

    // PATCH /ubicaciones/:id/archivar - Archivar ubicación (histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('ubicaciones')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.archivar<UbicacionResponseDto>(id, user.usuario_id);
    }

    // PATCH /ubicaciones/:id/desarchivar - Desarchivar ubicación (activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('ubicaciones')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UbicacionResponseDto> {
        return this.ubicacionesService.desarchivar<UbicacionResponseDto>(id, user.usuario_id);
    }
}
