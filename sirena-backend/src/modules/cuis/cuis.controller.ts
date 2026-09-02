// C:\sirena\sirena-backend\src\modules\cuis\cuis.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateCuiDto } from './dto/create-cui.dto';
import { CuiResponseDto } from './dto/cui-response.dto';
import { FindCuisQueryDto } from './dto/find-cuis-query.dto';
import { UpdateCuiDto } from './dto/update-cui.dto';
import { CuisService } from './cuis.service';

@UseGuards(JwtAuthGuard)
@Controller('cuis')
export class CuisController {
    constructor(
        private readonly cuisService: CuisService,
    ) {}

    // GET /cuis - Listar códigos CUIS
    @Get()
    @FindAllRateLimit()
    @Cache('cuis', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindCuisQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<CuiResponseDto>> {
        return this.cuisService.findAll(query, user.usuario_id);
    }

    // GET /cuis/:id - Obtener un código CUIS por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('cuis', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.findOne(id, user.usuario_id);
    }

    // POST /cuis - Crear código CUIS
    @Post()
    @CreateRateLimit()
    @InvalidateCache('cuis')
    create(
        @Body() dto: CreateCuiDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.create(dto, user.usuario_id);
    }

    // PATCH /cuis/:id - Actualizar código CUIS
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('cuis')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateCuiDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.update(id, dto, user.usuario_id);
    }

    // DELETE /cuis/:id - Eliminar código CUIS (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('cuis')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.remove<CuiResponseDto>(id, user.usuario_id);
    }

    // PATCH /cuis/:id/archivar - Archivar código CUIS (histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('cuis')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.archivar<CuiResponseDto>(id, user.usuario_id);
    }

    // PATCH /cuis/:id/desarchivar - Desarchivar código CUIS (activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('cuis')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.desarchivar<CuiResponseDto>(id, user.usuario_id);
    }
}
