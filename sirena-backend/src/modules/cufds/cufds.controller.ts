// C:\sirena\sirena-backend\src\modules\cufds\cufds.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateCufdDto } from './dto/create-cufd.dto';
import { CufdResponseDto } from './dto/cufd-response.dto';
import { FindCufdsQueryDto } from './dto/find-cufds-query.dto';
import { UpdateCufdDto } from './dto/update-cufd.dto';
import { CufdsService } from './cufds.service';

@UseGuards(JwtAuthGuard)
@Controller('cufds')
export class CufdsController {
    constructor(
        private readonly cufdsService: CufdsService,
    ) {}

    // GET /cufds - Listar códigos CUFD
    @Get()
    @FindAllRateLimit()
    @Cache('cufds', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindCufdsQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<CufdResponseDto>> {
        return this.cufdsService.findAll(query, user.usuario_id);
    }

    // GET /cufds/:id - Obtener un código CUFD por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('cufds', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.findOne(id, user.usuario_id);
    }

    // POST /cufds - Crear código CUFD
    @Post()
    @CreateRateLimit()
    @InvalidateCache('cufds')
    create(
        @Body() dto: CreateCufdDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.create(dto, user.usuario_id);
    }

    // PATCH /cufds/:id - Actualizar código CUFD
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('cufds')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateCufdDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.update(id, dto, user.usuario_id);
    }

    // DELETE /cufds/:id - Eliminar código CUFD (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('cufds')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.remove<CufdResponseDto>(id, user.usuario_id);
    }

    // PATCH /cufds/:id/archivar - Archivar código CUFD (histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('cufds')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.archivar<CufdResponseDto>(id, user.usuario_id);
    }

    // PATCH /cufds/:id/desarchivar - Desarchivar código CUFD (activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('cufds')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CufdResponseDto> {
        return this.cufdsService.desarchivar<CufdResponseDto>(id, user.usuario_id);
    }
}
