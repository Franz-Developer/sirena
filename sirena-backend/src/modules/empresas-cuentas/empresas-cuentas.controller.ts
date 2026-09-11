// C:\sirena\sirena-backend\src\modules\empresas-cuentas\empresas-cuentas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateEmpresaCuentaDto } from './dto/create-empresa-cuenta.dto';
import { EmpresaCuentaResponseDto } from './dto/empresa-cuenta-response.dto';
import { FindEmpresasCuentasQueryDto } from './dto/find-empresas-cuentas-query.dto';
import { UpdateEmpresaCuentaDto } from './dto/update-empresa-cuenta.dto';
import { EmpresasCuentasService } from './empresas-cuentas.service';

@UseGuards(JwtAuthGuard)
@Controller('empresas_cuentas')
export class EmpresasCuentasController {
    constructor(
        private readonly empresasCuentasService: EmpresasCuentasService,
    ) {}

    // GET /empresas_cuentas - Listar cuentas bancarias de empresas
    @Get()
    @FindAllRateLimit()
    @Cache('empresas_cuentas', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindEmpresasCuentasQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        return this.empresasCuentasService.findAll(query, user.usuario_id);
    }

    // GET /empresas_cuentas/:id - Obtener una cuenta bancaria de empresa
    @Get(':id')
    @FindOneRateLimit()
    @Cache('empresas_cuentas', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.findOne(id, user.usuario_id);
    }

    // POST /empresas_cuentas - Crear cuenta bancaria de empresa
    @Post()
    @CreateRateLimit()
    @InvalidateCache('empresas_cuentas')
    create(
        @Body() dto: CreateEmpresaCuentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.create(dto, user.usuario_id);
    }

    // PATCH /empresas_cuentas/:id - Actualizar cuenta bancaria de empresa
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('empresas_cuentas')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateEmpresaCuentaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.update(id, dto, user.usuario_id);
    }

    // DELETE /empresas_cuentas/:id - Eliminar cuenta bancaria de empresa (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('empresas_cuentas')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.remove<EmpresaCuentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /empresas_cuentas/:id/archivar - Archivar cuenta bancaria de empresa
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('empresas_cuentas')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.archivar<EmpresaCuentaResponseDto>(id, user.usuario_id);
    }

    // PATCH /empresas_cuentas/:id/desarchivar - Desarchivar cuenta bancaria de empresa
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('empresas_cuentas')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<EmpresaCuentaResponseDto> {
        return this.empresasCuentasService.desarchivar<EmpresaCuentaResponseDto>(id, user.usuario_id);
    }
}