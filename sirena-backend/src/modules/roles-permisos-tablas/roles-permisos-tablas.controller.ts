// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\roles-permisos-tablas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateRolPermisoTablaDto } from './dto/create-rol-permiso-tabla.dto';
import { UpdateRolPermisoTablaDto } from './dto/update-rol-permiso-tabla.dto';
import { RolPermisoTablaResponseDto } from './dto/rol-permiso-tabla-response.dto';
import { FindRolesPermisosTablasQueryDto } from './dto/find-roles-permisos-tablas-query.dto';
import { RolesPermisosTablasService } from './roles-permisos-tablas.service';

@UseGuards(JwtAuthGuard)
@Controller('roles-permisos-tablas')
export class RolesPermisosTablasController {
    constructor(
        private readonly rolesPermisosTablasService: RolesPermisosTablasService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('roles-permisos-tablas', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true })) query: FindRolesPermisosTablasQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<RolPermisoTablaResponseDto>> {
        return this.rolesPermisosTablasService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('roles-permisos-tablas', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoTablaResponseDto> {
        return this.rolesPermisosTablasService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('roles-permisos-tablas')
    create(
        @Body() dto: CreateRolPermisoTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoTablaResponseDto> {
        return this.rolesPermisosTablasService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('roles-permisos-tablas')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateRolPermisoTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoTablaResponseDto> {
        return this.rolesPermisosTablasService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('roles-permisos-tablas')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoTablaResponseDto> {
        return this.rolesPermisosTablasService.remove<RolPermisoTablaResponseDto>(id, user.usuario_id);
    }
}
