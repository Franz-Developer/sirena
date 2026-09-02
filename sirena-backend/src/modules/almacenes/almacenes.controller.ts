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
