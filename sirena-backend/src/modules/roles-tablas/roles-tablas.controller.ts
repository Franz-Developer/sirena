// C:\sirena\sirena-backend\src\modules\roles-tablas\roles-tablas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateRolTablaDto } from './dto/create-rol-tabla.dto';
import { RolTablaResponseDto } from './dto/rol-tabla-response.dto';
import { FindRolesTablasQueryDto } from './dto/find-roles-tablas-query.dto';
import { UpdateRolTablaDto } from './dto/update-rol-tabla.dto';
import { RolesTablasService } from './roles-tablas.service';

@UseGuards(JwtAuthGuard)
@Controller('roles-tablas')
export class RolesTablasController {
    constructor(
        private readonly rolesTablasService: RolesTablasService,
    ) {}

    // GET /roles-tablas - Listar permisos de roles por tabla
    @Get()
    @FindAllRateLimit()
    @Cache('roles_tablas', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindRolesTablasQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<RolTablaResponseDto>> {
        return this.rolesTablasService.findAll(query, user.usuario_id);
    }

    // GET /roles-tablas/:id - Obtener un permiso por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('roles_tablas', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolTablaResponseDto> {
        return this.rolesTablasService.findOne(id, user.usuario_id);
    }

    // POST /roles-tablas - Crear permiso de rol por tabla
    @Post()
    @CreateRateLimit()
    @InvalidateCache('roles_tablas')
    create(
        @Body() dto: CreateRolTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolTablaResponseDto> {
        return this.rolesTablasService.create(dto, user.usuario_id);
    }

    // PATCH /roles-tablas/:id - Actualizar permiso
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('roles_tablas')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateRolTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolTablaResponseDto> {
        return this.rolesTablasService.update(id, dto, user.usuario_id);
    }

    // DELETE /roles-tablas/:id - Eliminar permiso (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('roles_tablas')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolTablaResponseDto> {
        return this.rolesTablasService.remove<RolTablaResponseDto>(id, user.usuario_id);
    }
}
