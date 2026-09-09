// C:\sirena\sirena-backend\src\modules\roles\roles.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesService } from './roles.service';
import { RolResponseDto } from './dto/rol-response.dto';
import { CreateRolDto } from './dto/create-rol.dto';
import { FindRolesQueryDto } from './dto/find-roles-query.dto';
import { UpdateRolDto } from './dto/update-rol.dto';

@UseGuards(JwtAuthGuard)
@Controller('roles')
export class RolesController {
    constructor(
        private readonly rolesService: RolesService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('roles', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindRolesQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<RolResponseDto>> {
        return this.rolesService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('roles', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolResponseDto> {
        return this.rolesService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('roles')
    create(
        @Body() dto: CreateRolDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolResponseDto> {
        return this.rolesService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('roles')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateRolDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolResponseDto> {
        return this.rolesService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('roles')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<RolResponseDto> {
        return this.rolesService.remove<RolResponseDto>(id, user.usuario_id);
    }
}
