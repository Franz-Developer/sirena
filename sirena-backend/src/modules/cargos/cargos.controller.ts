// C:\sirena\sirena-backend\src\modules\cargos\cargos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CargosService } from './cargos.service';
import { CargoResponseDto } from './dto/cargo-response.dto';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { FindCargosQueryDto } from './dto/find-cargos-query.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';

@UseGuards(JwtAuthGuard)
@Controller('cargos')
export class CargosController {
    constructor(
        private readonly cargosService: CargosService,
    ) {}

    // GET /cargos - Listar cargos
    @Get()
    @FindAllRateLimit()
    @Cache('cargos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindCargosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<CargoResponseDto>> {
        return this.cargosService.findAll(query, user.usuario_id);
    }

    // GET /cargos/:id - Obtener un cargo
    @Get(':id')
    @FindOneRateLimit()
    @Cache('cargos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.findOne(id, user.usuario_id);
    }

    // POST /cargos - Crear cargo
    @Post()
    @CreateRateLimit()
    @InvalidateCache('cargos')
    create(
        @Body() dto: CreateCargoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.create(dto, user.usuario_id);
    }

    // PATCH /cargos/:id - Actualizar cargo
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('cargos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateCargoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.update(id, dto, user.usuario_id);
    }

    // DELETE /cargos/:id - Eliminar cargo (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('cargos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.remove<CargoResponseDto>(id, user.usuario_id);
    }

    // PATCH /cargos/:id/archivar - Archivar cargo
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('cargos')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.archivar<CargoResponseDto>(id, user.usuario_id);
    }

    // PATCH /cargos/:id/desarchivar - Desarchivar cargo
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('cargos')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CargoResponseDto> {
        return this.cargosService.desarchivar<CargoResponseDto>(id, user.usuario_id);
    }
}
