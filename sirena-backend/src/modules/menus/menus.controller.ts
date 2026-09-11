// C:\sirena\sirena-backend\src\modules\menus\menus.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MenusService } from './menus.service';
import { MenuResponseDto } from './dto/menu-response.dto';
import { CreateMenuDto } from './dto/create-menu.dto';
import { FindMenusQueryDto } from './dto/find-menus-query.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';

@UseGuards(JwtAuthGuard)
@Controller('menus')
export class MenusController {
    constructor(
        private readonly menusService: MenusService,
    ) {}

    // GET /menus - Listar menus
    @Get()
    @FindAllRateLimit()
    @Cache('menus', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindMenusQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<MenuResponseDto>> {
        return this.menusService.findAll(query, user.usuario_id);
    }

    // GET /menus/:id - Obtener un menu
    @Get(':id')
    @FindOneRateLimit()
    @Cache('menus', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<MenuResponseDto> {
        return this.menusService.findOne(id, user.usuario_id);
    }

    // POST /menus - Crear menu
    @Post()
    @CreateRateLimit()
    @InvalidateCache('menus')
    create(
        @Body() dto: CreateMenuDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<MenuResponseDto> {
        return this.menusService.create(dto, user.usuario_id);
    }

    // PATCH /menus/:id - Actualizar menu
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('menus')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateMenuDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<MenuResponseDto> {
        return this.menusService.update(id, dto, user.usuario_id);
    }

    // DELETE /menus/:id - Eliminar menu (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('menus')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<MenuResponseDto> {
        return this.menusService.remove<MenuResponseDto>(id, user.usuario_id);
    }
}
