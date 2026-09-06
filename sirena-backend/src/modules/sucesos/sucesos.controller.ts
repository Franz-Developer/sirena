// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\trabajadores-cargos.controller.ts
/*import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateTrabajadorCargoDto } from './dto/create-trabajador-cargo.dto';
import { TrabajadorCargoResponseDto } from './dto/trabajador-cargo-response.dto';
import { FindTrabajadoresCargosQueryDto } from './dto/find-trabajadores-cargos-query.dto';
import { UpdateTrabajadorCargoDto } from './dto/update-trabajador-cargo.dto';
import { TrabajadoresCargosService } from './trabajadores-cargos.service';

@UseGuards(JwtAuthGuard)
@Controller('trabajadores-cargos')
export class TrabajadoresCargosController {
    constructor(
        private readonly trabajadoresCargosService: TrabajadoresCargosService,
    ) {}

    // GET /trabajadores-cargos - Listar asignaciones
    @Get()
    @FindAllRateLimit()
    @Cache('trabajadores-cargos', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindTrabajadoresCargosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<TrabajadorCargoResponseDto>> {
        return this.trabajadoresCargosService.findAll(query, user.usuario_id);
    }

    // GET /trabajadores-cargos/:id - Obtener una asignación
    @Get(':id')
    @FindOneRateLimit()
    @Cache('trabajadores-cargos', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TrabajadorCargoResponseDto> {
        return this.trabajadoresCargosService.findOne(id, user.usuario_id);
    }

    // POST /trabajadores-cargos - Crear asignación
    @Post()
    @CreateRateLimit()
    @InvalidateCache('trabajadores-cargos')
    create(
        @Body() dto: CreateTrabajadorCargoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TrabajadorCargoResponseDto> {
        return this.trabajadoresCargosService.create(dto, user.usuario_id);
    }

    // PATCH /trabajadores-cargos/:id - Actualizar asignación
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('trabajadores-cargos')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateTrabajadorCargoDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TrabajadorCargoResponseDto> {
        return this.trabajadoresCargosService.update(id, dto, user.usuario_id);
    }

    // DELETE /trabajadores-cargos/:id - Eliminar asignación (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('trabajadores-cargos')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TrabajadorCargoResponseDto> {
        return this.trabajadoresCargosService.remove<TrabajadorCargoResponseDto>(id, user.usuario_id);
    }
}
*/