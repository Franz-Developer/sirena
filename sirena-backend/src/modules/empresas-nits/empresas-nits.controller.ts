// C:\sirena\sirena-backend\src\modules\empresas-nits\empresas-nits.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateEmpresaNitDto } from './dto/create-empresa-nit.dto';
import { EmpresaNitResponseDto } from './dto/empresa-nit-response.dto';
import { FindEmpresasNitsQueryDto } from './dto/find-empresas-nits-query.dto';
import { UpdateEmpresaNitDto } from './dto/update-empresa-nit.dto';
import { EmpresasNitsService } from './empresas-nits.service';

@UseGuards(JwtAuthGuard)
@Controller('empresas_nits')
export class EmpresasNitsController {
    constructor(
        private readonly empresasNitsService: EmpresasNitsService,
    ) {}

    // GET /empresas_nits - Listar NITs de empresas
    @Get()
    @FindAllRateLimit()
    @Cache('empresas_nits', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindEmpresasNitsQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<EmpresaNitResponseDto>> {
        return this.empresasNitsService.findAll(query, user.usuario_id);
    }

    // GET /empresas_nits/:id - Obtener un NIT de empresa
    @Get(':id')
    @FindOneRateLimit()
    @Cache('empresas_nits', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.findOne(id, user.usuario_id);
    }

    // POST /empresas_nits - Crear NIT de empresa
    @Post()
    @CreateRateLimit()
    @InvalidateCache('empresas_nits')
    create(
        @Body() dto: CreateEmpresaNitDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.create(dto, user.usuario_id);
    }

    // PATCH /empresas_nits/:id - Actualizar NIT de empresa
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('empresas_nits')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateEmpresaNitDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.update(id, dto, user.usuario_id);
    }

    // DELETE /empresas_nits/:id - Eliminar NIT de empresa (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('empresas_nits')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.remove<EmpresaNitResponseDto>(id, user.usuario_id);
    }

    // PATCH /empresas_nits/:id/archivar - Archivar NIT de empresa
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('empresas_nits')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.archivar<EmpresaNitResponseDto>(id, user.usuario_id);
    }

    // PATCH /empresas_nits/:id/desarchivar - Desarchivar NIT de empresa
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('empresas_nits')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaNitResponseDto> {
        return this.empresasNitsService.desarchivar<EmpresaNitResponseDto>(id, user.usuario_id);
    }
}
