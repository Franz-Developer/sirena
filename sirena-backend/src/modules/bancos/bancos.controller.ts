// C:\sirena\sirena-backend\src\modules\bancos\bancos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit} from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { BancosService } from './bancos.service';
import { BancoResponseDto } from './dto/banco-response.dto';
import { CreateBancoDto } from './dto/create-banco.dto';
import { FindBancosQueryDto } from './dto/find-bancos-query.dto';
import { UpdateBancoDto } from './dto/update-banco.dto';

@UseGuards(JwtAuthGuard)
@Controller('bancos')
export class BancosController {
    constructor(
        private readonly bancosService: BancosService,
    ) {}

    // GET /bancos - Listar bancos
    @Get()
    @FindAllRateLimit()
    @Cache('bancos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindBancosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<BancoResponseDto>> {
        return this.bancosService.findAll(query, user.usuario_id);
    }

    // GET /bancos/:id - Obtener un banco
    @Get(':id')
    @FindOneRateLimit()
    @Cache('bancos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.findOne(id, user.usuario_id);
    }

    // POST /bancos - Crear banco
    @Post()
    @CreateRateLimit()
    @InvalidateCache('bancos')
    create(
        @Body() dto: CreateBancoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.create(dto, user.usuario_id);
    }

    // PATCH /bancos/:id - Actualizar banco
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('bancos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateBancoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.update(id, dto, user.usuario_id);
    }

    // DELETE /bancos/:id - Eliminar banco (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('bancos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.remove<BancoResponseDto>(id, user.usuario_id);
    }

    // PATCH /bancos/:id/archivar - Archivar banco
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('bancos')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.archivar<BancoResponseDto>(id, user.usuario_id);
    }

    // PATCH /bancos/:id/desarchivar - Desarchivar banco
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('bancos')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<BancoResponseDto> {
        return this.bancosService.desarchivar<BancoResponseDto>(id, user.usuario_id);
    }
}