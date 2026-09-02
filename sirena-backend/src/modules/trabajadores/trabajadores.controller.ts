// C:\sirena\sirena-backend\src\modules\trabajadores\trabajadores.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards, UploadedFile, UseInterceptors, } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { FileUrlService } from '../../common/services/file-url.service';
import { ImagenValidatorService } from '../../common/validators/imagen-validator.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateTrabajadorDto } from './dto/create-trabajador.dto';
import { TrabajadorResponseDto } from './dto/trabajador-response.dto';
import { FindTrabajadoresQueryDto } from './dto/find-trabajadores-query.dto';
import { UpdateTrabajadorDto } from './dto/update-trabajador.dto';
import { TrabajadoresService } from './trabajadores.service';

@UseGuards(JwtAuthGuard)
@Controller('trabajadores')
export class TrabajadoresController {
    constructor(
        private readonly trabajadoresService: TrabajadoresService,
        private readonly fileUrlService: FileUrlService,
        private readonly imagenValidator: ImagenValidatorService,
    ) {}

    private transformarFoto(trabajador: TrabajadorResponseDto): TrabajadorResponseDto {
        if (trabajador && trabajador.foto) {
            trabajador.foto = this.fileUrlService.getPersonUrl(trabajador.foto) || '';
        }
        return trabajador;
    }

    private transformarQR(trabajador: TrabajadorResponseDto): TrabajadorResponseDto {
        if (trabajador && trabajador.qr) {
            trabajador.qr = this.fileUrlService.getPersonQrUrl(trabajador.qr) || '';
        }
        return trabajador;
    }

    private transformarRespuesta(trabajador: TrabajadorResponseDto): TrabajadorResponseDto {
        return this.transformarQR(this.transformarFoto(trabajador));
    }

    @Post()
    @CreateRateLimit()
    @UseInterceptors(FileInterceptor('foto', { storage: memoryStorage() }))
    @InvalidateCache('trabajadores')
    async create(
        @Body() dto: CreateTrabajadorDto,
        @UploadedFile() file: Express.Multer.File,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        if (file) {
            await this.imagenValidator.validarArchivo(file, 'foto_trabajador_config');
            dto.foto = await this.imagenValidator.guardarArchivoFisico(file, 'persons');
        } else if (dto.foto) {
            dto.foto = await this.imagenValidator.renombrarArchivo(dto.foto, 'persons');
        }

        const trabajador = await this.trabajadoresService.create(dto, user.usuario_id);
        return this.transformarRespuesta(trabajador);
    }

    @Get()
    @FindAllRateLimit()
    @Cache('trabajadores', CACHE_LARGO)
    async findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindTrabajadoresQueryDto,
        @GetUser() user: AuthenticatedUser,
    ): Promise<PaginatedResult<TrabajadorResponseDto>> {
        const result = await this.trabajadoresService.findAll<TrabajadorResponseDto>(
            query,
            user.usuario_id,
        );

        result.data = result.data.map((trabajador: TrabajadorResponseDto) => {
            if (trabajador.foto) {
                trabajador.foto = this.fileUrlService.getPersonUrl(trabajador.foto) || '';
            }
            if (trabajador.qr) {
                trabajador.qr = this.fileUrlService.getPersonQrUrl(trabajador.qr) || '';
            }
            return trabajador;
        });
        return result;
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('trabajadores', CACHE_LARGO)
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        const trabajador = await this.trabajadoresService.findOne<TrabajadorResponseDto>(
            id,
            user.usuario_id,
        );
        return this.transformarRespuesta(trabajador);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @UseInterceptors(FileInterceptor('foto', { storage: memoryStorage() }))
    @InvalidateCache('trabajadores')
    async update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateTrabajadorDto,
        @UploadedFile() file: Express.Multer.File,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        // ✅ MISMA LÓGICA QUE EMPRESAS
        if (file) {
            await this.imagenValidator.validarArchivo(file, 'foto_trabajador_config');
            dto.foto = await this.imagenValidator.guardarArchivoFisico(file, 'persons');
        } else if (dto.foto) {
            dto.foto = await this.imagenValidator.renombrarArchivo(dto.foto, 'persons');
        }

        const trabajador = await this.trabajadoresService.update(id, dto, user.usuario_id);
        return this.transformarRespuesta(trabajador);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('trabajadores')
    async remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        const trabajador = await this.trabajadoresService.remove<TrabajadorResponseDto>(
            id,
            user.usuario_id,
        );
        return this.transformarRespuesta(trabajador);
    }

    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('trabajadores')
    async archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        const trabajador = await this.trabajadoresService.archivar<TrabajadorResponseDto>(
            id,
            user.usuario_id,
        );
        return this.transformarRespuesta(trabajador);
    }

    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('trabajadores')
    async desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser,
    ): Promise<TrabajadorResponseDto> {
        const trabajador = await this.trabajadoresService.desarchivar<TrabajadorResponseDto>(
            id,
            user.usuario_id,
        );
        return this.transformarRespuesta(trabajador);
    }
}
