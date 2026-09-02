// C:\sirena\sirena-backend\src\modules\unidades\unidades.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UnidadesService } from './unidades.service';
import { UnidadResponseDto } from './dto/unidad-response.dto';
import { CreateUnidadDto } from './dto/create-unidad.dto';
import { FindUnidadesQueryDto } from './dto/find-unidades-query.dto';
import { UpdateUnidadDto } from './dto/update-unidad.dto';

@UseGuards(JwtAuthGuard)
@Controller('unidades')
export class UnidadesController {
    constructor(
        private readonly unidadesService: UnidadesService,
    ) {}

    // GET /unidades - Listar unidades
    @Get()
    @FindAllRateLimit()
    @Cache('unidades', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindUnidadesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<UnidadResponseDto>> {
        return this.unidadesService.findAll(query, user.usuario_id);
    }

    // GET /unidades/:id - Obtener una unidad
    @Get(':id')
    @FindOneRateLimit()
    @Cache('unidades', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.findOne(id, user.usuario_id);
    }

    // POST /unidades - Crear unidad
    @Post()
    @CreateRateLimit()
    @InvalidateCache('unidades')
    create(
        @Body() dto: CreateUnidadDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.create(dto, user.usuario_id);
    }

    // PATCH /unidades/:id - Actualizar unidad
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('unidades')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateUnidadDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.update(id, dto, user.usuario_id);
    }

    // DELETE /unidades/:id - Eliminar unidad (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('unidades')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.remove<UnidadResponseDto>(id, user.usuario_id);
    }

    // PATCH /unidades/:id/archivar - Archivar unidad
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('unidades')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.archivar<UnidadResponseDto>(id, user.usuario_id);
    }

    // PATCH /unidades/:id/desarchivar - Desarchivar unidad
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('unidades')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UnidadResponseDto> {
        return this.unidadesService.desarchivar<UnidadResponseDto>(id, user.usuario_id);
    }
}
