// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\inventarios-fisicos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateInventarioFisicoDto } from './dto/create-inventario-fisico.dto';
import { InventarioFisicoResponseDto } from './dto/inventario-fisico-response.dto';
import { FindInventariosFisicosQueryDto } from './dto/find-inventarios-fisicos-query.dto';
import { UpdateInventarioFisicoDto } from './dto/update-inventario-fisico.dto';
import { InventariosFisicosService } from './inventarios-fisicos.service';

@UseGuards(JwtAuthGuard)
@Controller('inventarios-fisicos')
export class InventariosFisicosController {
    constructor(
        private readonly inventariosFisicosService: InventariosFisicosService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('inventarios-fisicos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindInventariosFisicosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<InventarioFisicoResponseDto>> {
        return this.inventariosFisicosService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('inventarios-fisicos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<InventarioFisicoResponseDto> {
        return this.inventariosFisicosService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('inventarios-fisicos')
    create(
        @Body() dto: CreateInventarioFisicoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<InventarioFisicoResponseDto> {
        return this.inventariosFisicosService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('inventarios-fisicos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateInventarioFisicoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<InventarioFisicoResponseDto> {
        return this.inventariosFisicosService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('inventarios-fisicos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<InventarioFisicoResponseDto> {
        return this.inventariosFisicosService.remove<InventarioFisicoResponseDto>(id, user.usuario_id);
    }
}
