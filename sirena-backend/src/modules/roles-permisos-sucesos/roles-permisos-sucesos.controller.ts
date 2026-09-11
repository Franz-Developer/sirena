// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\roles-permisos-sucesos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateRolPermisoSucesoDto } from './dto/create-rol-permiso-suceso.dto';
import { UpdateRolPermisoSucesoDto } from './dto/update-rol-permiso-suceso.dto';
import { RolPermisoSucesoResponseDto } from './dto/rol-permiso-suceso-response.dto';
import { FindRolesPermisosSucesosQueryDto } from './dto/find-roles-permisos-sucesos-query.dto';
import { RolesPermisosSucesosService } from './roles-permisos-sucesos.service';

@UseGuards(JwtAuthGuard)
@Controller('roles-permisos-sucesos')
export class RolesPermisosSucesosController {
    constructor(
        private readonly rolesPermisosSucesosService: RolesPermisosSucesosService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('roles-permisos-sucesos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true })) query: FindRolesPermisosSucesosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<RolPermisoSucesoResponseDto>> {
        return this.rolesPermisosSucesosService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('roles-permisos-sucesos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoSucesoResponseDto> {
        return this.rolesPermisosSucesosService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('roles-permisos-sucesos')
    create(
        @Body() dto: CreateRolPermisoSucesoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoSucesoResponseDto> {
        return this.rolesPermisosSucesosService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('roles-permisos-sucesos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateRolPermisoSucesoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoSucesoResponseDto> {
        return this.rolesPermisosSucesosService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('roles-permisos-sucesos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolPermisoSucesoResponseDto> {
        return this.rolesPermisosSucesosService.remove<RolPermisoSucesoResponseDto>(id, user.usuario_id);
    }
}
