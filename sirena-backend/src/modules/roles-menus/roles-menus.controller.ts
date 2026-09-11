// C:\sirena\sirena-backend\src\modules\roles-menus\roles-menus.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateRolMenuDto } from './dto/create-rol-menu.dto';
import { RolMenuResponseDto } from './dto/rol-menu-response.dto';
import { FindRolesMenusQueryDto } from './dto/find-roles-menus-query.dto';
import { UpdateRolMenuDto } from './dto/update-rol-menu.dto';
import { RolesMenusService } from './roles-menus.service';

@UseGuards(JwtAuthGuard)
@Controller('roles-menus')
export class RolesMenusController {
    constructor(
        private readonly rolesMenusService: RolesMenusService,
    ) {}

    // GET /roles-menus - Listar relaciones rol-menú
    @Get()
    @FindAllRateLimit()
    @Cache('roles_menus', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindRolesMenusQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<RolMenuResponseDto>> {
        return this.rolesMenusService.findAll(query, user.usuario_id);
    }

    // GET /roles-menus/:id - Obtener una relación por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('roles_menus', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolMenuResponseDto> {
        return this.rolesMenusService.findOne(id, user.usuario_id);
    }

    // POST /roles-menus - Crear relación rol-menú
    @Post()
    @CreateRateLimit()
    @InvalidateCache('roles_menus')
    create(
        @Body() dto: CreateRolMenuDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolMenuResponseDto> {
        return this.rolesMenusService.create(dto, user.usuario_id);
    }

    // PATCH /roles-menus/:id - Actualizar relación
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('roles_menus')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateRolMenuDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolMenuResponseDto> {
        return this.rolesMenusService.update(id, dto, user.usuario_id);
    }

    // DELETE /roles-menus/:id - Eliminar relación (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('roles_menus')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolMenuResponseDto> {
        return this.rolesMenusService.remove<RolMenuResponseDto>(id, user.usuario_id);
    }
}
