-- ================================================================================================
-- Paso 8. Generador de [nombre-modulo]-response.dto.ts

Actúa como un arquitecto de software experto en NestJS, TypeScript, PostgreSQL y transformación de datos usando `class-transformer`.

Tu tarea es tomar el código DDL de una tabla principal y generar estrictamente el archivo Response DTO (`[nombre-modulo]-response.dto.ts`) cumpliendo con las siguientes reglas de arquitectura y mapeo:

- Archivo a generar: `[nombre-modulo]-response.dto.ts`
- Ruta del archivo: `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\[nombre-modulo]-response.dto.ts`

### ⚠️ REGLAS OBLIGATORIAS E INQUEBRANTABLES (CUMPLIMIENTO DEL 100%)

1. **Estructura Base del Archivo y de la Interfaz Raw:**
   - Importaciones fijas obligatorias:
     ```typescript
     import { Expose, Type, Transform } from 'class-transformer';
     import { formatLocalDate } from '@/common/utils/date-formatter.util';
     ```
   - Debes generar una interfaz `[SingularPascalCase]RawResult` que tipifique todas las columnas de la tabla principal (con tipos flexibles como `string | number`, `string | Date`, etc.), incluyendo `total_count?: string | number;` y las columnas relacionales adicionales de soporte (como `estado_abreviatura`).

2. **Mapeo Inteligente de Claves Foráneas (FKs) hacia `dominios`:**
   - Analiza las restricciones `FOREIGN KEY` en el DDL. Si una columna ID termina en `_id` y apunta a la tabla `dominios` (por ejemplo, `genero_id`, `estado_civil_id`, `estado_id`), debes exponer tanto su propiedad numérica de tipo `number` como su respectiva propiedad anidada utilizando la entidad `DominioResponseDto` en formato **CamelCase** (eliminando el sufijo `_id` o `id` del nombre base):
     - *Ejemplo:* Si existe `genero_id`, debes generar:
       ```typescript
       @Expose() genero_id!: number;

       @Expose()
       @Type(() => DominioResponseDto)
       genero?: DominioResponseDto;
       ```
     - *Ejemplo:* Si existe `estado_civil_id`, debes generar:
       ```typescript
       @Expose() estado_civil_id!: number;

       @Expose()
       @Type(() => DominioResponseDto)
       estadoCivil?: DominioResponseDto;
       ```

3. **Mapeo de Columnas Propias del DDL:**
   - Convierte cada columna restante de la tabla al tipo de TypeScript correspondiente dentro de la clase `[SingularPascalCase]ResponseDto`:
     - `BIGSERIAL` / `INTEGER` / `DECIMAL` / `NUMERIC` -> `number`
     - `VARCHAR` / `TEXT` -> `string` (con `?` si es `NULL`).

4. **Formato Automático de Fechas:**
   - Cualquier columna de tipo fecha (`DATE`, `TIMESTAMPTZ`) debe ir decorada obligatoriamente con el formateador local de fechas:
     ```typescript
     @Expose()
     @Transform(({ value }) => formatLocalDate(value))
     fecha_campo!: string | null;
     ```

5. **Formato de Salida en Bloque Único:**
   - Devuelve todo el código TypeScript limpio, estructurado e indentado dentro de un **único bloque de código independiente (` ```typescript ... ``` `)**, comenzando estrictamente en la primera línea con el comentario de la ruta absoluta del archivo.

### 📥 DATOS DE ENTRADA:

**1. DDL de la Tabla Principal:**



**2. DDLs de las Tablas Foráneas (FKs) Relacionadas:**
