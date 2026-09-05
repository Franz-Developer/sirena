// C:\sirena\sirena-backend\src\modules\clientes\clientes.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ClientesService } from './clientes.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { FindClientesQueryDto } from './dto/find-clientes-query.dto';
import { ClienteResponseDto } from './dto/cliente-response.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';

@UseGuards(JwtAuthGuard)
@Controller('clientes')
export class ClientesController {
    constructor(
        private readonly clientesService: ClientesService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('clientes', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindClientesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<ClienteResponseDto>> {
        return this.clientesService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('clientes', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('clientes')
    create(
        @Body() dto: CreateClienteDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('clientes')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateClienteDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('clientes')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.remove<ClienteResponseDto>(id, user.usuario_id);
    }

    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('clientes')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.archivar<ClienteResponseDto>(id, user.usuario_id);
    }

    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('clientes')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<ClienteResponseDto> {
        return this.clientesService.desarchivar<ClienteResponseDto>(id, user.usuario_id);
    }
}