-- ================================================================================================
-- Paso 7. Generar find-[nombre-modulo]-query.dto.ts

Actúa como un arquitecto de software experto en NestJS, TypeScript, PostgreSQL y validación de datos usando `class-validator` y `class-transformer`.

Tu tarea es tomar el código DDL de una tabla de la base de datos Sirena y generar estrictamente el archivo Query DTO de búsqueda y paginación para el módulo:
- Archivo a generar: `[nombre-modulo]-query.dto.ts`
- Ruta del archivo: `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\find-[nombre-modulo]-query.dto.ts`

### ⚠️ REGLAS OBLIGATORIAS E INQUEBRANTABLES (EL CUMPLIMIENTO ES DEL 100%)

1. **Estructura Base Obligatoria y Exportación de Interfaces:**
   - El archivo debe incluir obligatoriamente las siguientes interfaces antes de la clase principal:
     ```typescript
     export interface DependenciaRaw {
         table_name: string;
         column_name: string;
         total_registros: number;
         registros_activos: number;
     }

     export interface FindAllParams {
         q?: string;
         exactMatch?: number;
         useFullText?: boolean;
         limit?: number;
         offset?: number;
     }
     ```
   - La clase principal debe llamarse estrictamente `Find[SingularPascalCase]QueryDto` y debe heredar de `BasePaginationQueryDto`.
   - Debe incluir la exportación final de `PaginatedResult`.

2. **Imports Estrictos en Una Sola Línea:**
   - Las sentencias de importación de `class-validator` y `class-transformer` **deben ir obligatoriamente en una sola línea**.
   - Ejemplo correcto: `import { IsOptional, IsString, IsIn, IsInt, IsDateString } from 'class-validator';`

3. **Filtros Automáticos basados en columnas del DDL:**
   - **Campos de texto (`VARCHAR`):** Por cada columna clave de texto (ej. `dominio`, `abreviatura`), agrega un filtro opcional tipo string con su respectivo mensaje de error descriptivo en español.
   - **Campos enteros/numéricos de selección (`INTEGER` sin autoincremento o flags como `es_protegido`):** Agrégalos como opcionales con validación `@IsInt()` y `@IsIn(...)` si representan opciones acotadas (como `0` y `1`).
   - **Exclusiones obligatorias:** No crees filtros de consulta para la llave primaria autoincremental (`[nombre]_id`), ni para los campos de auditoría estándar del sistema (`estado_id` ya se maneja de forma especial, y se omiten `usuario_id_registro`, `usuario_id_actualizacion`, `usuario_id_baja`, `fecha_registro`, `fecha_actualizacion`, `fecha_baja`).

4. **Regla Inteligente de Rangos de Fechas (¡OBLIGATORIO!):**
   - Analiza el DDL en busca de columnas de tipo `DATE` o `TIMESTAMPTZ`.
   - **Excepción:** Ignora por completo las columnas automáticas de auditoría del sistema: `fecha_registro`, `fecha_actualizacion` y `fecha_baja`.
   - Si la tabla contiene **cualquier otra columna de tipo fecha de negocio** (por ejemplo, `fecha_vencimiento`, `fecha_inicio_contrato`, etc.), debes generar automáticamente para dicha columna un par de filtros de rango en el Query DTO utilizando los sufijos `_inicio` y `_fin`.
   - Cada uno de estos filtros debe estar decorado con `@IsOptional()` y `@IsDateString({ message: '...' })`, además de usar `@Type(() => Date)` si es requerido por la transformación.

5. **Filtros Estándar de Paginación, Búsqueda Global y Estados:**
   - Incluye siempre las propiedades estándar de control:
     - `q?: string;` (Búsqueda general de texto)
     - `exactMatch: number = 0;` (Con validación `@IsIn([0, 1])` y `@Type(() => Number)`)
     - `estado_id?: number;` (Validado contra el enum `Estado` importado desde `../../../common/constants/estados.constant`)

6. **Métodos de Control y Ordenamiento requeridos en la clase:**
   - `getDefaultSortField(): string`: Debe retornar la llave primaria o principal de la tabla (ej. `'dominio_id'`).
   - `getAllowedSortFields(): string[]`: Debe retornar un arreglo con los campos permitidos para ordenar (llave primaria, campos de texto principales, `estado_id`, `fecha_registro`, etc.).
   - `getSortFieldMapping(): Record<string, string>`: Mapeos alternativos si apliquen (ej. transformar alias de ordenamiento como `'nombre'` a `'dominio'`).
   - `getEstados(): number[]`: Lógica estándar para retornar los estados activos/históricos por defecto si no se especifica un `estado_id`.

7. **Formato de Salida en Bloque Único:**
   - Devuelve todo el código TypeScript limpio, estructurado e indentado dentro de un **único bloque de código independiente (` ```typescript ... ``` `)**, comenzando estrictamente en la primera línea con el comentario de la ruta absoluta.

Aquí tienes el DDL de la tabla a procesar:

