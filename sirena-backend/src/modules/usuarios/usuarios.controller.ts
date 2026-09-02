// C:\sirena\sirena-backend\src\modules\usuarios\usuarios.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards, UploadedFile, UseInterceptors, HttpStatus } from '@nestjs/common';
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
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UsuarioResponseDto } from './dto/usuario-response.dto';
import { FindUsuariosQueryDto } from './dto/find-usuarios-query.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { UsuariosService } from './usuarios.service';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { DomainException } from '../../common/exceptions/domain.exception';

@UseGuards(JwtAuthGuard)
@Controller('usuarios')
export class UsuariosController {
    constructor(
        private readonly usuariosService: UsuariosService,
        private readonly fileUrlService: FileUrlService,
        private readonly imagenValidator: ImagenValidatorService,
    ) {}

    private transformarAvatar(usuario: UsuarioResponseDto): UsuarioResponseDto {
        if (usuario && usuario.avatar) {
            usuario.avatar = (this.fileUrlService as any).getAvatarUrl
                ? (this.fileUrlService as any).getAvatarUrl(usuario.avatar)
                : usuario.avatar;
        }
        return usuario;
    }

    @Post()
    @CreateRateLimit()
    @UseInterceptors(FileInterceptor('avatar', { storage: memoryStorage() }))
    @InvalidateCache('usuarios')
    async create(
        @Body() dto: CreateUsuarioDto,
        @UploadedFile() file: Express.Multer.File,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        if (file) {
            await this.imagenValidator.validarArchivo(file, 'avatar_config');
            dto.avatar = await this.imagenValidator.guardarArchivoFisico(file, 'avatars');
        } else if (dto.avatar) {
            dto.avatar = await this.imagenValidator.renombrarArchivo(dto.avatar, 'avatars');
        }

        const usuario = await this.usuariosService.create(dto, user.usuario_id);
        return this.transformarAvatar(usuario);
    }

    @Get()
    @FindAllRateLimit()
    @Cache('usuarios', CACHE_LARGO)
    async findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindUsuariosQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<UsuarioResponseDto>> {
        const result = await this.usuariosService.findAll<UsuarioResponseDto>(
            query,
            user.usuario_id
        );

        result.data = result.data.map((usuario: UsuarioResponseDto) => {
            if (usuario.avatar) {
                usuario.avatar = (this.fileUrlService as any).getAvatarUrl
                    ? (this.fileUrlService as any).getAvatarUrl(usuario.avatar)
                    : usuario.avatar;
            }
            return usuario;
        });
        return result;
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('usuarios', CACHE_LARGO)
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        const usuario = await this.usuariosService.findOne<UsuarioResponseDto>(id, user.usuario_id);
        return this.transformarAvatar(usuario);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @UseInterceptors(FileInterceptor('avatar', { storage: memoryStorage() }))
    @InvalidateCache('usuarios')
    async update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateUsuarioDto,
        @UploadedFile() file: Express.Multer.File,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        if (file) {
            await this.imagenValidator.validarArchivo(file, 'avatar_config');
            dto.avatar = await this.imagenValidator.guardarArchivoFisico(file, 'avatars');
        } else if (dto.avatar) {
            dto.avatar = await this.imagenValidator.renombrarArchivo(dto.avatar, 'avatars');
        }

        const usuario = await this.usuariosService.update(id, dto, user.usuario_id);
        return this.transformarAvatar(usuario);
    }

    @Patch(':id/cambiar-password')
    @UpdateRateLimit()
    @InvalidateCache('usuarios')
    async cambiarPassword(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdatePasswordDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<{ message: string }> {
        if (dto.nuevaContrasena !== dto.confirmarContrasena) {
            throw new DomainException(
                'La nueva contraseña y la confirmación no coinciden.',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        await this.usuariosService.cambiarPassword(id, dto, user.usuario_id);
        return { message: 'Contraseña actualizada exitosamente' };
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('usuarios')
    async remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        const usuario = await this.usuariosService.remove<UsuarioResponseDto>(id, user.usuario_id);
        return this.transformarAvatar(usuario);
    }

    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('usuarios')
    async archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        const usuario = await this.usuariosService.archivar<UsuarioResponseDto>(id, user.usuario_id);
        return this.transformarAvatar(usuario);
    }

    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('usuarios')
    async desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<UsuarioResponseDto> {
        const usuario = await this.usuariosService.desarchivar<UsuarioResponseDto>(id, user.usuario_id);
        return this.transformarAvatar(usuario);
    }
}
