// C:\sirena\sirena-backend\src\modules\sucesos\sucesos.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SucesosService } from './sucesos.service';
import { CreateSucesoDto } from './dto/create-suceso.dto';
import { UpdateSucesoDto } from './dto/update-suceso.dto';
import { SucesoResponseDto } from './dto/suceso-response.dto';
import { Suceso } from './entities/suceso.entity';
import { FindSucesosQueryDto } from './dto/find-sucesos-query.dto';

@UseGuards(JwtAuthGuard)
@Controller('sucesos')
export class SucesosController {
    constructor(private readonly sucesosService: SucesosService) {}

    @Get()
    @FindAllRateLimit()
    @Cache('sucesos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true })) query: FindSucesosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<Suceso>> {
        return this.sucesosService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('sucesos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<Suceso> {
        return this.sucesosService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('sucesos')
    create(
        @Body() dto: CreateSucesoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucesoResponseDto> {
        return this.sucesosService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('sucesos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateSucesoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucesoResponseDto> {
        return this.sucesosService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('sucesos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<SucesoResponseDto> {
        return this.sucesosService.remove<SucesoResponseDto>(id, user.usuario_id);
    }
}
