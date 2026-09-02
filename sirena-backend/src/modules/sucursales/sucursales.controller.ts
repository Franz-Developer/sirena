// C:\sirena\sirena-backend\src\modules\sucursales\sucursales.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateSucursalDto } from './dto/create-sucursal.dto';
import { SucursalResponseDto } from './dto/sucursal-response.dto';
import { FindSucursalesQueryDto } from './dto/find-sucursales-query.dto';
import { UpdateSucursalDto } from './dto/update-sucursal.dto';
import { SucursalesService } from './sucursales.service';

@UseGuards(JwtAuthGuard)
@Controller('sucursales')
export class SucursalesController {
    constructor(
        private readonly sucursalesService: SucursalesService,
    ) {}

    // GET /sucursales - Listar sucursales
    @Get()
    @FindAllRateLimit()
    @Cache('sucursales', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindSucursalesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<SucursalResponseDto>> {
        return this.sucursalesService.findAll(query, user.usuario_id);
    }

    // GET /sucursales/:id - Obtener una sucursal por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('sucursales', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.findOne(id, user.usuario_id);
    }

    // POST /sucursales - Crear sucursal
    @Post()
    @CreateRateLimit()
    @InvalidateCache('sucursales')
    create(
        @Body() dto: CreateSucursalDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.create(dto, user.usuario_id);
    }

    // PATCH /sucursales/:id - Actualizar sucursal
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('sucursales')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateSucursalDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.update(id, dto, user.usuario_id);
    }

    // DELETE /sucursales/:id - Eliminar sucursal (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('sucursales')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.remove<SucursalResponseDto>(id, user.usuario_id);
    }

    // PATCH /sucursales/:id/archivar - Archivar sucursal (cambiar a estado histórico/archivado)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('sucursales')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.archivar<SucursalResponseDto>(id, user.usuario_id);
    }

    // PATCH /sucursales/:id/desarchivar - Desarchivar sucursal (volver a ACTIVO)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('sucursales')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucursalResponseDto> {
        return this.sucursalesService.desarchivar<SucursalResponseDto>(id, user.usuario_id);
    }
}
