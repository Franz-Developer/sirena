-- ================================================================================================
-- Paso 11. Generar `[nombre-modulo].controller.ts`

ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND EXPERTO EN NESTJS, TYPESCRIPT Y TYPEORM.

Tu tarea es generar el archivo de controlador `[nombre-modulo].controller.ts` para un módulo específico, basándote en la estructura de rutas, validaciones, seguridad y el siguiente ejemplo oficial de referencia.

Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

---

### EJEMPLOS DE REFERENCIA OFICIAL:

#### 1. Referencia: Controlador Estándar CRUD, Consultas Validadas y Transiciones de Estado
// C:\sirena\sirena-backend\src\modules\tipos-cambios\tipos-cambios.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, BadRequestException, ValidationPipe, UseGuards } from '@nestjs/common';
import { TiposCambiosService } from './tipos-cambios.service';
import { CreateTipoCambioDto } from './dto/create-tipo-cambio.dto';
import { UpdateTipoCambioDto } from './dto/update-tipo-cambio.dto';
import { FindTiposCambiosQueryDto } from './dto/find-tipos-cambios-query.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { validateUser } from '../../common/utils/auth.util';

@UseGuards(JwtAuthGuard)
@Controller('tipos-cambios')
export class TiposCambiosController {
    constructor(private readonly tiposCambiosService: TiposCambiosService) {}

    @Get()
    findAll(
        @Query(new ValidationPipe({
            whitelist: true,
            forbidNonWhitelisted: true,
            exceptionFactory: (errors) => {
                const wrongProps = errors.map(err => err.property);
                return new BadRequestException({
                    message: `Parámetros inválidos: ${wrongProps.join(', ')}. Parámetros permitidos: estado_id, q, offset, limit, sortField, sortOrder.`,
                    error: 'Bad Request',
                    statusCode: 400,
                });
            },
        })) query: FindTiposCambiosQueryDto, @GetUser() user: any
    ) {
        validateUser(user);
        return this.tiposCambiosService.findAll(query);
    }

    @Get(':id')
    findOne(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.findOne(id);
    }

    @Post()
    create(@Body() dto: CreateTipoCambioDto, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateTipoCambioDto, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    remove(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.remove(id, user.usuario_id);
    }

    @Patch(':id/archivar')
    archivar(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.archivar(id, user.usuario_id);
    }

    @Patch(':id/desarchivar')
    desarchivar(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.tiposCambiosService.desarchivar(id, user.usuario_id);
    }
}

#### 2. Referencia: Controlador con Interceptor de Archivos (Subida de Logos / Imágenes con Multer y Sharp)
// C:\sirena\sirena-backend\src\modules\empresas\empresas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, BadRequestException, ValidationPipe, UseGuards, UseInterceptors, UploadedFile } from '@nestjs/common';
import { EmpresasService } from './empresas.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { FindEmpresasQueryDto } from './dto/find-empresas-query.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { join, extname } from 'path';
import * as fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { validateUser } from '../../common/utils/auth.util';

@UseGuards(JwtAuthGuard)
@Controller('empresas')
export class EmpresasController {
    constructor(private readonly empresasService: EmpresasService) {}

    @Post('upload-logo')
    @UseInterceptors(FileInterceptor('file', {
        storage: diskStorage({
            destination: (_req, _file, cb) => {
                const uploadPath = join(process.cwd(), 'uploads', 'logos');
                if (!fs.existsSync(uploadPath)) {
                    fs.mkdirSync(uploadPath, { recursive: true });
                }
                cb(null, uploadPath);
            },
            filename: (_req, file, cb) => {
                const fileExtension = extname(file.originalname).toLowerCase();
                const fileName = `${uuidv4()}${fileExtension}`;
                cb(null, fileName);
            },
        }),
        fileFilter: (_req, file, cb) => {
            if (!file.originalname.match(/\.(jpg|jpeg|png)$/i)) {
                return cb(new BadRequestException('Solo se permiten archivos JPG, JPEG y PNG'), false);
            }
            cb(null, true);
        },
        limits: {
            fileSize: 200 * 1024,
        },
    }))
    async uploadLogo(@UploadedFile() file: Express.Multer.File, @GetUser() user: any) {
        validateUser(user);
        if (!file) {
            throw new BadRequestException('Archivo no recibido o formato inválido');
        }

        try {
            await this.empresasService.validarDimensionesLogo(file.filename);
            return {
                message: 'Logo verificado y guardado correctamente',
                filename: file.filename
            };
        } catch (error) {
            const filePath = join(process.cwd(), 'uploads', 'logos', file.filename);
            if (fs.existsSync(filePath)) {
                try {
                    fs.unlinkSync(filePath);
                } catch (unlinkError) {
                    console.error(`Error al eliminar archivo no válido: ${filePath}`, unlinkError);
                }
            }
            throw error;
        }
    }

    @Get()
    findAll(
        @Query(new ValidationPipe({
            whitelist: true,
            forbidNonWhitelisted: true,
            exceptionFactory: (errors) => {
                const wrongProps = errors.map(err => err.property);
                return new BadRequestException({
                    message: `Parámetros inválidos: ${wrongProps.join(', ')}. Use estado_id o q.`,
                    error: 'Bad Request',
                    statusCode: 400,
                });
            },
        })) query: FindEmpresasQueryDto, @GetUser() user: any
    ) {
        validateUser(user);
        return this.empresasService.findAll(query);
    }

    @Get(':id')
    findOne(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.findOne(id);
    }

    @Post()
    create(@Body() dto: CreateEmpresaDto, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateEmpresaDto, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    remove(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.remove(id, user.usuario_id);
    }

    @Patch(':id/archivar')
    archivar(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.archivar(id, user.usuario_id);
    }

    @Patch(':id/desarchivar')
    desarchivar(@Param('id', ParseIntPipe) id: number, @GetUser() user: any) {
        validateUser(user);
        return this.empresasService.desarchivar(id, user.usuario_id);
    }
}

---

### REGLAS OBLIGATORIAS PARA GENERAR EL CONTROLADOR (`[nombre-modulo].controller.ts`):

1. **Seguridad y Guards Base:**
   - La clase debe llevar obligatoriamente `@UseGuards(JwtAuthGuard)` y el decorador `@Controller('nombre-ruta')`.
   - Cada método debe validar la sesión del usuario llamando a `validateUser(user)` al inicio.

2. **Extracción de Auditoría:**
   - En las operaciones de escritura (`create`, `update`, `remove`, `archivar`, `desarchivar`), extraer el ID del usuario autenticado mediante `@GetUser()` y pasarlo como `user.usuario_id` al servicio.

3. **Validación Estricta de Consultas (`findAll`):**
   - Usar `ValidationPipe` en `@Query` con `whitelist: true`, `forbidNonWhitelisted: true` y un `exceptionFactory` personalizado que devuelva un `BadRequestException` estructurado listando los parámetros erróneos y permitidos.

4. **Tipado de Parámetros de Ruta:**
   - Todos los identificadores en parámetros (`:id`) deben tiparse estrictamente mediante `@Param('id', ParseIntPipe) id: number`.

5. **Manejo de Archivos (Si aplica):**
   - Utilizar `FileInterceptor` con restricciones estrictas de almacenamiento (`diskStorage`), validación de extensiones en `fileFilter`, control de límites de tamaño y un bloque `try/catch` con borrado físico automático (`fs.unlinkSync`) en caso de fallo de validación de negocio/imagen.

6. **Formato de Importaciones:** CADA importación debe ir estrictamente en una sola línea, sin saltos de línea intermedios.

-- ================================================================================================