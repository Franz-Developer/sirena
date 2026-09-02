-- ================================================================================================
-- Paso 12. Generar `[nombre-modulo].service.ts`

Actúa como un Arquitecto de Software Senior especializado en NestJS, TypeORM y PostgreSQL. Tu objetivo es generar el archivo `[nombre-tabla].service.ts` de un módulo específico, adaptándote rigurosamente a las convenciones, patrones de diseño y estándares de la arquitectura del proyecto sirena.

Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

Para construir el servicio `[nombre-tabla].service.ts`, se te proporcionarán los siguientes insumos en el prompt de la petición:
1. **DDL de la tabla:** Definición de la base de datos (columnas, tipos de datos, llaves foráneas, restricciones y catálogos).
2. **Entidad principal (`[nombre-tabla].entity.ts`):** Estructura de TypeORM de la tabla.
3. **DTOs asociados:** 
   - `create-[nombre-tabla].dto.ts`
   - `update-[nombre-tabla].dto.ts`
   - `find-[nombre-tabla]-query.dto.ts`
   - `[nombre-tabla]-response.dto.ts`
4. **Validador del módulo (`[nombre-tabla]-validator.service.ts`):** Servicio inyectable encargado de las reglas de negocio y validaciones previas.
5. **Controlador (`[nombre-tabla].controller.ts`):** Para entender los endpoints y flujos esperados.
6. **Utilidades y clases base de referencia:**
   - `string.util.ts` (Funciones `SQL_NORMALIZE`, `normalizeText`, `validateSafeText`, `logSQL`).
   - `base-audit.entity.ts` (Campos de auditoría y estados estándar: Activo, Borrado/Inactivo, Histórico).
   - Servicio de catálogos (`CatalogoDominioConfigService`) para la resolución dinámica de estados (`ACTIVO_ID`, `BORRADO_ID`, `HISTORICO_ID`).

---

### REGLAS OBLIGATORIAS DE IMPLEMENTACIÓN:

1. **Inyección de Dependencias y Constructor:**
   - Inyectar el repositorio TypeORM de la entidad correspondiente (`@InjectRepository(Entity)`).
   - Inyectar el validador específico del módulo (`[NombreTabla]ValidatorService`).
   - Inyectar `CatalogoDominioConfigService` para manejar los IDs de estados de forma dinámica (`ACTIVO_ID`, `BORRADO_ID`, `HISTORICO_ID`).
   - Inyectar `DataSource` de TypeORM para el manejo de transacciones con `QueryRunner`.

2. **Método `findAll` (Listado, Paginación, Filtros y Búsqueda Avanzada):**
   - Extraer todos los parámetros de filtrado, paginación (`offset`, `limit`), ordenamiento (`sortField`, `sortOrder`) y búsqueda (`q`) desde el DTO de consulta.
   - Si se proporciona el parámetro de búsqueda `q`, validar obligatoriamente su seguridad con `validateSafeText(q, ...)`.
   - Construir consultas SQL nativas o mediante query builder utilizando `SQL_NORMALIZE` y `normalizeText` para búsquedas tolerantes a acentos y mayúsculas/minúsculas en campos de texto relevantes.
   - Realizar `LEFT JOIN` o `INNER JOIN` según corresponda con tablas relacionadas (como `sucursales`, `clientes`, `dominios`, etc.) para poblar nombres descriptivos y abreviaturas en la respuesta.
   - Ejecutar una consulta independiente para obtener el conteo total (`total`) utilizando un subquery (`SELECT COUNT(1) AS total FROM (...) AS sub`).
   - Registrar la traza SQL utilizando `logSQL(...)`.
   - Transformar los resultados planos crudos (`rawData`) a instancias del DTO de respuesta utilizando `plainToInstance(ResponseDto, rawData, { excludeExtraneousValues: true })`.

3. **Método `findOne` (Búsqueda por ID):**
   - Consultar el registro aplicando los mismos `JOIN` y mapeos que en el `findAll` para retornar un objeto completo y enriquecido.
   - Lanzar `NotFoundException` si el registro no es encontrado.

4. **Método `create` (Creación transaccional):**
   - Invocar las validaciones de negocio correspondientes a través del servicio validador (`validarReglasNegocio`, unicidades de códigos o combinaciones vigentes).
   - Utilizar un `QueryRunner` y transacción (`startTransaction`, `commitTransaction`, `rollbackTransaction`) para asegurar la atomicidad.
   - Manejar errores de restricciones únicas de base de datos (por ejemplo, código de error PostgreSQL `'23505'`), lanzando un `BadRequestException` limpio y amigable.
   - Retornar el resultado llamando internamente a `this.findOne(saved.id)`.

5. **Método `update` (Actualización transaccional):**
 	primero debe validar await this.pruebasValidator.validarRegistroProtegido(id);
   - Validar que el registro exista, no esté protegido, y no se encuentre en estado `BORRADO` mediante el servicio validador.
   - Ejecutar validaciones de unicidad condicionales (solo si el código o campos únicos cambian).
   - Utilizar `QueryRunner` para envolver la actualización en una transacción segura.
   - siempre debe haber 
   if ('estado_id' in dto) {
		throw new BadRequestException('No está permitido modificar el estado. Use /archivar o /desarchivar.');
	}
	
6. **Métodos de Gestión de Estados (`remove`, `archivar`, `desarchivar`):**
	primero debe validar await this.pruebasValidator.validarRegistroProtegido(id);
   - **`remove` (Eliminación lógica):** Validar dependencias y cambiar el estado del registro a `BORRADO_ID`, asignando el `usuario_id_baja`.
   - **`archivar`:** Cambiar el estado a `HISTORICO_ID`.
   - **`desarchivar`:** reglas antes de retornar el registro a `ACTIVO_ID`.

7. **Tareas Programadas (`@Cron`) y Manejo de Archivos (si aplican en el DDL o entidad):**
   - Si la entidad maneja archivos adjuntos (imágenes, logos, documentos), implementar lógica defensiva con `fs`, `path` y `sharp` para validación de dimensiones, formatos permitidos y tareas de limpieza automática de archivos huérfanos mediante `@Cron`.

8. **Estilo de Código:**
   - Código limpio, tipado estricto en TypeScript, manejo estructurado de excepciones (`NotFoundException`, `BadRequestException`), y registro de eventos mediante `Logger`.
   - Seguir estrictamente la estructura organizativa y de nombres mostrada en el ejemplo de referencia (`pruebas.service.ts`).  

NUNCA Usar QueryBuilder


EJEMPLO 
// C:\sirena\sirena-backend\src\modules\pruebas\pruebas.service.ts
import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import * as fs from 'fs';
import * as path from 'path';
import { join } from 'path';
import * as sharp from 'sharp';
import { Metadata } from 'sharp';
import { Prueba } from './entities/prueba.entity';
import { CreatePruebaDto } from './dto/create-prueba.dto';
import { UpdatePruebaDto } from './dto/update-prueba.dto';
import { FindPruebasQueryDto } from './dto/find-pruebas-query.dto';
import { PruebaResponseDto } from './dto/prueba-response.dto';
import { PruebasValidatorService } from '../../common/validators/pruebas-validator.service';
import { CatalogoDominioConfigService } from '../dominios/catalogo-dominio-config.service';
import { SQL_NORMALIZE, normalizeText, validateSafeText, logSQL } from '../../common/utils/string.util';
import { plainToInstance } from 'class-transformer';

@Injectable()
export class PruebasService {
    private readonly logger = new Logger(PruebasService.name);

    constructor(
        @InjectRepository(Prueba)
        private readonly pruebaRepository: Repository<Prueba>,
        private readonly pruebasValidator: PruebasValidatorService,
        private readonly catalogoConfig: CatalogoDominioConfigService,
        private readonly dataSource: DataSource,
    ) {}

    private get ACTIVO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get BORRADO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.BORRADO); }
    private get HISTORICO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    /**
     * Tarea programada diaria a las 3:00 AM para limpiar logos huérfanos que no estén referenciados
     * en la base de datos por ningún registro activo/histórico de pruebas y tengan más de 24 horas de antigüedad.
     */
    @Cron(CronExpression.EVERY_DAY_AT_3AM)
    async limpiarLogosHuerfanos(): Promise<void> {
        const carpetaLogos = join(process.cwd(), 'uploads', 'logos');
        if (!fs.existsSync(carpetaLogos)) return;

        try {
            const archivosEnDisco = fs.readdirSync(carpetaLogos);
            const pruebas = await this.pruebaRepository.find({
                select: ['logo'],
                where: { estado_id: this.ACTIVO_ID } // Se puede ajustar o ampliar a otros estados según modelo
            });

            const logosEnBD = new Set(pruebas.map(p => p.logo).filter(logo => !!logo));
            let borrados = 0;
            const AHORA = Date.now();
            const UN_DIA_EN_MS = 24 * 60 * 60 * 1000;

            for (const archivo of archivosEnDisco) {
                if (!logosEnBD.has(archivo)) {
                    const rutaCompleta = join(carpetaLogos, archivo);
                    try {
                        const stats = fs.statSync(rutaCompleta);
                        if (AHORA - stats.mtimeMs > UN_DIA_EN_MS) {
                            fs.unlinkSync(rutaCompleta);
                            borrados++;
                        }
                    } catch (statError) {
                        this.logger.error(`No se pudo procesar el archivo huérfano: ${rutaCompleta}`, statError);
                    }
                }
            }
            if (borrados > 0) {
                this.logger.log(`[LIMPIEZA] Se eliminaron ${borrados} logos huérfanos del servidor.`);
            }
        } catch (error) {
            this.logger.error('Error en la tarea programada de limpieza de logos huérfanos:', error);
        }
    }

    async validarDimensionesLogo(filename: string): Promise<void> {
        const ruta = join(process.cwd(), 'uploads', 'logos', filename);
        if (!fs.existsSync(ruta)) {
            throw new BadRequestException('El archivo de imagen no existe en el servidor.');
        }

        let metadata: Metadata;
        try {
            metadata = await sharp(ruta).metadata();
        } catch (error) {
            this.borrarArchivoFisico(filename);
            throw new BadRequestException('El archivo no es una imagen válida o está corrupto.');
        }

        const formatosPermitidos = ['png', 'jpeg', 'jpg'];
        if (!metadata.format || !formatosPermitidos.includes(metadata.format)) {
            this.borrarArchivoFisico(filename);
            throw new BadRequestException('El archivo adjunto no corresponde a una imagen válida (formato no permitido o ejecutable disfrazado).');
        }

        const { width, height } = metadata;
        if (!width || !height) {
            this.borrarArchivoFisico(filename);
            throw new BadRequestException('No se pudieron determinar las dimensiones de la imagen.');
        }

        const MAX_HEIGHT = 450;
        const MAX_WIDTH = 1500;
        if (height > MAX_HEIGHT || width > MAX_WIDTH) {
            this.borrarArchivoFisico(filename);
            const errorMsg = 'El logo no cumple el tamaño permitido.\n' +
                             `Máximo: ${MAX_WIDTH}px de ancho y ${MAX_HEIGHT}px de alto.\n` +
                             `Tu imagen es: ${width}px de ancho y ${height}px de alto.`;
            throw new BadRequestException(errorMsg);
        }
    }

    private borrarArchivoFisico(nombreArchivo: string): void {
        if (!nombreArchivo) return;
        const rutaArchivo = join(process.cwd(), 'uploads', 'logos', nombreArchivo);
        if (fs.existsSync(rutaArchivo)) {
            try {
                fs.unlinkSync(rutaArchivo);
            } catch (error) {
                this.logger.error(`No se pudo borrar el archivo físico: ${rutaArchivo}`, error);
            }
        }
    }

    async findAll(queryDto: FindPruebasQueryDto): Promise<{ data: PruebaResponseDto[]; total: number }> {
        const {
            estado_id = this.ACTIVO_ID,
            sucursal_id,
            cliente_id,
            tipo_beneficio_id,
            estado_extra_id,
            fecha_inicio_inicio,
            fecha_inicio_fin,
            fecha_cotizacion_inicio,
            fecha_cotizacion_fin,
            q,
            offset = 0,
            limit = 10,
            sortField = 'fecha_registro',
            sortOrder = -1,
        } = queryDto;

        if (q) {
            validateSafeText(q, 'Parámetro de búsqueda q');
        }

        let baseQuery = `
            SELECT 
                p.prueba_id, p.sucursal_id, p.cliente_id, p.tipo_beneficio_id,
                p.codigo, p.nombre, p.descripcion, p.monto, p.cantidad, p.logo, p.es_activo,
                p.fecha_cotizacion, p.fecha_inicio, p.fecha_fin, p.fecha_prueba, p.fecha_hora,
                p.parametros, p.metadatos, p.estado_extra_id, p.estado_id,
                p.usuario_id_registro, p.usuario_id_actualizacion, p.usuario_id_baja,
                p.fecha_registro, p.fecha_actualizacion, p.fecha_baja,
                s.sucursal AS "sucursal_nombre",
                c.razon_social AS "cliente_razon_social",
                dtb.nombre AS "tipo_beneficio_nombre",
                dte.nombre AS "estado_extra_nombre",
                des.nombre AS "estado_nombre",
                des.abreviatura AS "estadoAbreviatura",
                dte.abreviatura AS "estadoExtraAbreviatura"
            FROM pruebas p
            INNER JOIN sucursales s ON s.sucursal_id = p.sucursal_id
            INNER JOIN clientes c ON c.cliente_id = p.cliente_id
            INNER JOIN dominios dtb ON dtb.dominio_id = p.tipo_beneficio_id
            INNER JOIN dominios dte ON dte.dominio_id = p.estado_extra_id
            INNER JOIN dominios des ON des.dominio_id = p.estado_id
            WHERE p.estado_id = $1
        `;

        const params: any[] = [estado_id];
        let pIdx = 2;

        if (sucursal_id) {
            baseQuery += ` AND p.sucursal_id = $${pIdx++}`;
            params.push(sucursal_id);
        }

        if (cliente_id) {
            baseQuery += ` AND p.cliente_id = $${pIdx++}`;
            params.push(cliente_id);
        }

        if (tipo_beneficio_id) {
            baseQuery += ` AND p.tipo_beneficio_id = $${pIdx++}`;
            params.push(tipo_beneficio_id);
        }

        if (estado_extra_id) {
            baseQuery += ` AND p.estado_extra_id = $${pIdx++}`;
            params.push(estado_extra_id);
        }

        if (fecha_inicio_inicio) {
            baseQuery += ` AND p.fecha_inicio >= $${pIdx++}`;
            params.push(fecha_inicio_inicio);
        }

        if (fecha_inicio_fin) {
            baseQuery += ` AND p.fecha_inicio <= $${pIdx++}`;
            params.push(fecha_inicio_fin);
        }

        if (fecha_cotizacion_inicio) {
            baseQuery += ` AND p.fecha_cotizacion >= $${pIdx++}`;
            params.push(fecha_cotizacion_inicio);
        }

        if (fecha_cotizacion_fin) {
            baseQuery += ` AND p.fecha_cotizacion <= $${pIdx++}`;
            params.push(fecha_cotizacion_fin);
        }

        if (q?.trim()) {
            const words = q.trim().split(/\s+/);
            words.forEach(word => {
                const search = `%${normalizeText(word)}%`;
                baseQuery += `
                    AND (
                        ${SQL_NORMALIZE('p.codigo')} LIKE $${pIdx++}
                        OR ${SQL_NORMALIZE('p.nombre')} LIKE $${pIdx++}
                        OR ${SQL_NORMALIZE("COALESCE(p.descripcion, '')")} LIKE $${pIdx++}
                        OR ${SQL_NORMALIZE('s.sucursal')} LIKE $${pIdx++}
                    )
                `;
                params.push(search, search, search, search);
            });
        }

        const countQuery = `SELECT COUNT(1) AS total FROM (${baseQuery}) AS sub`;
        logSQL('pruebas.service.ts', 'findAll (Count)', countQuery, params);
        const countResult = await this.pruebaRepository.query(countQuery, params);
        const total = countResult[0]?.total ? parseInt(countResult[0].total, 10) : 0;

        const allowedSortFields: Record<string, string> = {
            prueba_id: 'p.prueba_id',
            codigo: 'p.codigo',
            nombre: 'p.nombre',
            monto: 'p.monto',
            cantidad: 'p.cantidad',
            fecha_cotizacion: 'p.fecha_cotizacion',
            fecha_inicio: 'p.fecha_inicio',
            fecha_registro: 'p.fecha_registro',
        };

        const dbSortField = allowedSortFields[sortField] || 'p.fecha_registro';
        const dbSortOrder = sortOrder === 1 ? 'ASC' : 'DESC';

        baseQuery += ` ORDER BY ${dbSortField} ${dbSortOrder} LIMIT $${pIdx++} OFFSET $${pIdx++}`;
        const queryParamsWithPagination = [...params, limit, offset];

        logSQL('pruebas.service.ts', 'findAll', baseQuery, queryParamsWithPagination);
        const rawData = await this.pruebaRepository.query(baseQuery, queryParamsWithPagination);

        const data = plainToInstance(PruebaResponseDto, rawData, { excludeExtraneousValues: true });
        return { data, total };
    }

    async findOne(id: number): Promise<PruebaResponseDto> {
        const query = `
            SELECT 
                p.prueba_id, p.sucursal_id, p.cliente_id, p.tipo_beneficio_id,
                p.codigo, p.nombre, p.descripcion, p.monto, p.cantidad, p.logo, p.es_activo,
                p.fecha_cotizacion, p.fecha_inicio, p.fecha_fin, p.fecha_prueba, p.fecha_hora,
                p.parametros, p.metadatos, p.estado_extra_id, p.estado_id,
                p.usuario_id_registro, p.usuario_id_actualizacion, p.usuario_id_baja,
                p.fecha_registro, p.fecha_actualizacion, p.fecha_baja,
                s.sucursal AS "sucursal_nombre",
                c.razon_social AS "cliente_razon_social",
                dtb.nombre AS "tipo_beneficio_nombre",
                dte.nombre AS "estado_extra_nombre",
                des.nombre AS "estado_nombre",
                des.abreviatura AS "estadoAbreviatura",
                dte.abreviatura AS "estadoExtraAbreviatura"
            FROM pruebas p
            INNER JOIN sucursales s ON s.sucursal_id = p.sucursal_id
            INNER JOIN clientes c ON c.cliente_id = p.cliente_id
            INNER JOIN dominios dtb ON dtb.dominio_id = p.tipo_beneficio_id
            INNER JOIN dominios dte ON dte.dominio_id = p.estado_extra_id
            INNER JOIN dominios des ON des.dominio_id = p.estado_id
            WHERE p.prueba_id = $1
        `;

        logSQL('pruebas.service.ts', 'findOne', query, [id]);
        const rawData = await this.pruebaRepository.query(query, [id]);

        if (!rawData || rawData.length === 0) {
            throw new NotFoundException(`La prueba con ID ${id} no existe.`);
        }

        return plainToInstance(PruebaResponseDto, rawData[0], { excludeExtraneousValues: true });
    }

    async create(dto: CreatePruebaDto, userId: number): Promise<PruebaResponseDto> {
        await this.pruebasValidator.validarReglasNegocio(dto);

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            await this.pruebasValidator.validarUnicidadCodigo(dto.codigo);
            await this.pruebasValidator.validarUnicidadCotizacionVigente(
                dto.sucursal_id,
                dto.cliente_id,
                dto.tipo_beneficio_id,
                dto.fecha_cotizacion!
            );

            const nuevaPrueba = this.pruebaRepository.create({
                ...dto,
                estado_id: this.ACTIVO_ID,
                usuario_id_registro: userId,
            });

            const saved = await queryRunner.manager.save(nuevaPrueba);
            await queryRunner.commitTransaction();

            this.logger.log(`Usuario ${userId} creó la prueba ${saved.prueba_id} (${saved.codigo})`);
            return this.findOne(saved.prueba_id);
        } catch (error) {
            await queryRunner.rollbackTransaction();
            if (error.code === '23505') {
                throw new BadRequestException('Ya existe un registro con ese código o restricción única.');
            }
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    async update(id: number, dto: UpdatePruebaDto, userId: number): Promise<PruebaResponseDto> {
        await this.pruebasValidator.validarRegistroProtegido(id);
        await this.pruebasValidator.validarPruebaActivoOHistorico(id);
		
		if ('estado_id' in dto) {
            throw new BadRequestException('No está permitido modificar el estado. Use /archivar o /desarchivar.');
        }
		
        const pruebaActual = await this.pruebaRepository.findOne({ where: { prueba_id: id } });
        if (!pruebaActual) {
            throw new NotFoundException(`La prueba con ID ${id} no existe.`);
        }

        if (pruebaActual.estado_id === this.BORRADO_ID) {
            throw new BadRequestException(`No se puede actualizar una prueba que está en estado BORRADO.`);
        }

        await this.pruebasValidator.validarReglasNegocio(dto);

        if (dto.codigo && dto.codigo !== pruebaActual.codigo) {
            await this.pruebasValidator.validarUnicidadCodigo(dto.codigo, id);
        }

        const sucursalId = dto.sucursal_id ?? pruebaActual.sucursal_id;
        const clienteId = dto.cliente_id ?? pruebaActual.cliente_id;
        const tipoBeneficioId = dto.tipo_beneficio_id ?? pruebaActual.tipo_beneficio_id;
        const fechaCotizacion = dto.fecha_cotizacion ?? pruebaActual.fecha_cotizacion;

        if (
            dto.sucursal_id !== undefined ||
            dto.cliente_id !== undefined ||
            dto.tipo_beneficio_id !== undefined ||
            dto.fecha_cotizacion !== undefined
        ) {
            await this.pruebasValidator.validarUnicidadCotizacionVigente(
                sucursalId,
                clienteId,
                tipoBeneficioId,
                fechaCotizacion,
                id
            );
        }

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            Object.assign(pruebaActual, dto);
            pruebaActual.usuario_id_actualizacion = userId;

            await queryRunner.manager.save(pruebaActual);
            await queryRunner.commitTransaction();

            this.logger.log(`Usuario ${userId} actualizó la prueba ${id}`);
            return this.findOne(id);
        } catch (error) {
            await queryRunner.rollbackTransaction();
            if (error.code === '23505') {
                throw new BadRequestException('Ya existe un registro con ese código o restricción única.');
            }
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    async remove(id: number, userId: number): Promise<{ message: string }> {
        await this.pruebasValidator.validarRegistroProtegido(id);
        await this.pruebasValidator.validarPruebaActivoOHistorico(id);
        await this.pruebasValidator.validarPruebaSinDependencias(id);

        const prueba = await this.pruebaRepository.findOne({ where: { prueba_id: id } });
        if (!prueba) {
            throw new NotFoundException(`La prueba con ID ${id} no existe.`);
        }

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            prueba.estado_id = this.BORRADO_ID;
            prueba.usuario_id_baja = userId;
            await queryRunner.manager.save(prueba);
            await queryRunner.commitTransaction();

            this.logger.log(`Usuario ${userId} eliminó lógicamente la prueba ${id}`);
            return { message: `La prueba con ID ${id} ha sido eliminada lógicamente de forma exitosa.` };
        } catch (error) {
            await queryRunner.rollbackTransaction();
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    async archivar(id: number, userId: number): Promise<PruebaResponseDto> {
        await this.pruebasValidator.validarRegistroProtegido(id);
        await this.pruebasValidator.validarPruebaActivo(id);

        const prueba = await this.pruebaRepository.findOne({ where: { prueba_id: id } });
        if (!prueba) {
            throw new NotFoundException(`La prueba con ID ${id} no existe.`);
        }

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            this.logger.log(`Usuario ${userId} archivando prueba ${id} (${prueba.codigo})`);
            prueba.estado_id = this.HISTORICO_ID;
            prueba.usuario_id_actualizacion = userId;
            await queryRunner.manager.save(prueba);
            await queryRunner.commitTransaction();

            return this.findOne(id);
        } catch (error) {
            await queryRunner.rollbackTransaction();
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    async desarchivar(id: number, userId: number): Promise<PruebaResponseDto> {
        await this.pruebasValidator.validarRegistroProtegido(id);
        await this.pruebasValidator.validarPruebaHistorico(id);

        const prueba = await this.pruebaRepository.findOne({ where: { prueba_id: id } });
        if (!prueba) {
            throw new NotFoundException(`La prueba con ID ${id} no existe.`);
        }

        await this.pruebasValidator.validarUnicidadCodigo(prueba.codigo, id);
        await this.pruebasValidator.validarUnicidadCotizacionVigente(
            prueba.sucursal_id,
            prueba.cliente_id,
            prueba.tipo_beneficio_id,
            prueba.fecha_cotizacion,
            id
        );

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            prueba.estado_id = this.ACTIVO_ID;
            prueba.usuario_id_actualizacion = userId;
            await queryRunner.manager.save(prueba);
            await queryRunner.commitTransaction();

            this.logger.log(`Usuario ${userId} desarchivó la prueba ${id}`);
            return this.findOne(id);
        } catch (error) {
            await queryRunner.rollbackTransaction();
            throw error;
        } finally {
            await queryRunner.release();
        }
    }
}

