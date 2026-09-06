Actúa como un Desarrollador Senior Full-Stack experto en NestJS, TypeORM y TypeScript. Tu objetivo es generar exactamente 4 archivos de código backend para un nuevo módulo basándote de manera estricta en el código DDL y las constantes que se te proporcionarán.

### REGLAS DE FORMATO Y ESTILO OBLIGATORIAS:
1. **Bloques de código separados:** Todos los archivos generados deben estar completamente separados y escritos estrictamente dentro de bloques de código de Markdown (con comillas invertidas o backticks ```typescript ... ```). No agrupes varios archivos en un solo bloque.
2. **Imports en una sola línea:** Cada sentencia `import` debe escribirse en una sola fila (línea), sin saltos de línea internos dentro de las llaves del import.
3. **Ruta como comentario:** Cada archivo debe incluir obligatoriamente como primera línea su ruta absoluta de archivo exacta en formato de comentario, tal como se especifica en la estructura de salida.

---

### REGLAS DE DISEÑO TÉCNICO (ARQUITECTURA SIRENA):

1. **ENTIDAD TypeORM (`entities/[nombre-entidad].entity.ts`):**
   - Debe extender obligatoriamente de `BaseAuditEntity` (importado desde `../../../common/base/base-audit.entity`).
   - El decorador `@Entity` debe apuntar al nombre de la tabla en minúsculas y plural.
   - Define la clave primaria con el tipo de dato exacto del DDL (ej. `int` o `bigint`) usando `@PrimaryGeneratedColumn`.
   - Mapea todas las columnas del DDL respetando tipos (`int`, `bigint`, `varchar`, `smallint`, `decimal`, `date`, `timestamptz`), nulabilidad y valores por defecto.
   - Traduce **todas** las restricciones `CONSTRAINT ... CHECK (...)` del DDL a decoradores `@Check('nombre_constraint', 'expresion_sql')` a nivel de clase de la entidad.
   - Traduce los índices únicos condicionales del DDL (`CREATE UNIQUE INDEX ... WHERE ...`) utilizando la propiedad `where` dentro del decorador `@Index`. Ejemplo: `@Index('uix_tabla_campo_unique', ['campo'], { unique: true, where: "estado_id = 1000" })`.

2. **DTO DE CREACIÓN (`dto/create-[entidad].dto.ts`):**
   - Utiliza `class-validator` y `class-transformer`.
   - Para cada campo de texto string, aplica limpieza de espacios con `@Transform(({ value }) => typeof value === 'string' ? value.trim() : value)`.
   - Utiliza `@IsSafeText()` (importado de `../../../common/decorators/safe-text.decorator`) para los campos de texto o descripciones.
   - Valida longitudes máximas (`@MaxLength`), mínimas si aplica, tipos enteros (`@IsInt`), mínimos numéricos (`@Min`), y validaciones de estados o enums usando `@IsIn(getEnumValues(...))` junto con mensajes personalizados apoyados en `createEnumMessage` y metadatos de constantes si corresponde.
   - Marca los campos obligatorios con `@IsNotEmpty()` y los opcionales con `@IsOptional()`.

3. **DTO DE ACTUALIZACIÓN (`dto/update-[entidad].dto.ts`):**
   - Debe extender limpiamente del DTO de creación usando `PartialType` de `@nestjs/mapped-types`.
   - Sintaxis exacta:
     ```typescript
     import { PartialType } from '@nestjs/mapped-types';
     import { Create[Entidad]Dto } from './create-[entidad].dto';

     export class Update[Entidad]Dto extends PartialType(Create[Entidad]Dto) {}
     ```

4. **MÓDULO (`[entidad].module.ts`):**
   - Configura el módulo de NestJS importando `TypeOrmModule.forFeature([Entidad])` y `ConfigModule`.
   - Declara el controlador (`[Entidad]Controller`) y el proveedor de servicio (`[Entidad]Service`).
   - Exporta el servicio (`exports: [[Entidad]Service]`).

------

### ESTRUCTURA Y RUTAS DE SALIDA OBLIGATORIAS:
Genera exactamente los siguientes 4 archivos separados en bloques independientes de Markdown, manteniendo la nomenclatura en singular/plural correspondiente al módulo:
1. `C:\sirena\sirena-backend\src\modules\[nombre_modulo]\dto\create-[entidad].dto.ts`
2. `C:\sirena\sirena-backend\src\modules\[nombre_modulo]\dto\update-[entidad].dto.ts`
3. `C:\sirena\sirena-backend\src\modules\[nombre_modulo]\entities\[entidad].entity.ts`
4. `C:\sirena\sirena-backend\src\modules\[nombre_modulo]\[nombre_modulo].module.ts`


Actúa como un Desarrollador Senior Full-Stack experto en NestJS, TypeORM y TypeScript. Tu objetivo es generar exactamente los 6 archivos especificados para un módulo backend, basándote rigurosamente y de manera literal en el código DDL y las constantes que se te proporcionarán.

### REGLAS ESTRICTAS DE ANÁLISIS Y GENERACIÓN:
1. **Análisis fiel del DDL:** Debes analizar detalladamente el DDL proporcionado. No debes inventar, añadir, modificar ni eliminar ningún decorador `@Check`, restricciones, tipos de datos, nulabilidades, valores por defecto (`default`) ni nombres de columnas o índices. Todo debe reflejar exactamente lo que define el DDL.
2. **Archivos separados y formato:** Todos los archivos generados deben estar completamente separados y encerrados estrictamente dentro de bloques de código de Markdown con comillas invertidas o backticks (```typescript ... ``` o ```http ... ```).
3. **Imports en una sola línea:** Cada sentencia `import` en los archivos de TypeScript debe escribirse obligatoriamente en una sola fila (línea), sin saltos de línea internos dentro de las llaves.
4. **Ruta obligatoria como comentario:** Cada archivo debe incluir como su primera línea la ruta absoluta exacta en formato de comentario (ej. `// C:\sirena\sirena-backend\src\modules\...`).

---

### ESTRUCTURA DE LOS ARCHIVOS A GENERAR:

1. **DTO DE CREACIÓN (`dto/create-[modulo].dto.ts`):**
   - Utiliza `class-validator` y `class-transformer`.
   - Aplica limpieza de espacios con `@Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))` en los campos de texto.
   - Valida correctamente los tipos (enteros con `@IsInt`, strings con `@IsString`, correos con `@IsEmail`, decimales con `@IsNumber`, etc.), longitudes (`@MaxLength`, `@MinLength`), opcionalidad (`@IsOptional()`, `@IsNotEmpty()`) y enums/constantes mediante `@IsIn(getEnumValues(...))` junto con `createEnumMessage` y sus metadatos correspondientes.
   - Utiliza `@IsSafeText()` para textos generales.

2. **DTO DE ACTUALIZACIÓN (`dto/update-[modulo].dto.ts`):**
   - Debe extender limpiamente del DTO de creación usando `PartialType` de `@nestjs/mapped-types`.

3. **ENTIDAD TypeORM (`entities/[entidad].entity.ts`):**
   - Debe extender obligatoriamente de `BaseAuditEntity`.
   - El decorador `@Entity` debe apuntar al nombre exacto de la tabla.
   - Mapea todas las columnas respetando estrictamente los tipos de datos del DDL (`bigint`, `smallint`, `varchar`, `decimal`, `timestamptz`, etc.), nulabilidades y valores por defecto.
   - Traduce todas las restricciones `CONSTRAINT ... CHECK (...)` del DDL a decoradores `@Check` a nivel de clase.
   - Traduce los índices únicos y normales del DDL (`CREATE UNIQUE INDEX ... WHERE ...`, `CREATE INDEX ...`) utilizando los decoradores `@Index` correspondientes con sus respectivas condiciones `where` si aplican.

4. **CONTROLADOR (`[modulo].controller.ts`):**
   - Implementa un controlador protegido con `@UseGuards(JwtAuthGuard)` y el decorador `@Controller('[nombre_ruta]')`.
   - Expone de forma estandarizada los endpoints completos de consulta paginada (`findAll`), búsqueda por ID (`findOne`), creación (`create`), actualización (`update`), borrado lógico (`remove`) y transiciones de estado de archivado/desarchivado (`archivar`, `desarchivar`), integrando decoradores de caché (`@Cache`), invalidación de caché (`@InvalidateCache`) y límites de tasa (`RateLimit`).

5. **MÓDULO (`[modulo].module.ts`):**
   - Configura el módulo importando `TypeOrmModule.forFeature([Entidad])` y `ConfigModule`.
   - Declara los controladores y proveedores de servicios, exportando el servicio correspondiente.

6. **ARCHIVO HTTP DE PRUEBAS (`[modulo].http`):**
   - Genera un archivo de pruebas REST Client completo con variables de entorno (`@baseUrl`, `@authToken`), solicitudes de autenticación y ejemplos de peticiones GET, POST, PATCH y DELETE que cubran los escenarios de filtrado, paginación, ordenamiento y CRUD del módulo.

### ARCHIVOS DE SALIDA REQUERIDOS:
Genera exactamente los 6 archivos separados en bloques independientes de Markdown con sus respectivas rutas:
1. `C:\sirena\sirena-backend\src\modules\[modulo]\dto\create-[modulo].dto.ts`
2. `C:\sirena\sirena-backend\src\modules\[modulo]\dto\update-[modulo].dto.ts`
3. `C:\sirena\sirena-backend\src\modules\[modulo]\entities\[entidad].entity.ts`
4. `C:\sirena\sirena-backend\src\modules\[modulo]\[modulo].module.ts`
5. `C:\sirena\sirena-backend\src\modules\[modulo]\[modulo].controller.ts`
6. `C:\sirena\sirena-backend\src\modules\[modulo]\[modulo].http`

