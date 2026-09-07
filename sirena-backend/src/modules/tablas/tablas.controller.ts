// C:\sirena\sirena-backend\src\modules\tablas\tablas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TablasService } from './tablas.service';
import { CreateTablaDto } from './dto/create-tabla.dto';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';
import { TablaResponseDto } from './dto/tabla-response.dto';
import { UpdateTablaDto } from './dto/update-tabla.dto';

@UseGuards(JwtAuthGuard)
@Controller('tablas')
export class TablasController {
    constructor(
        private readonly tablasService: TablasService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('tablas', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindTablasQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<TablaResponseDto>> {
        return this.tablasService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('tablas', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('tablas')
    create(
        @Body() dto: CreateTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('tablas')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('tablas')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.remove<TablaResponseDto>(id, user.usuario_id);
    }
}