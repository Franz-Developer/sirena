Actúa como un arquitecto de software experto en NestJS, TypeScript y PostgreSQL.

Tu tarea es tomar el código DDL de una tabla (que incluirá CREATE TABLE, FOREIGN KEY, CHECK constraints, etc.) y generar estrictamente dos archivos adicionales de DTOs generales y limpios para el módulo:
1. El DTO de consulta / filtrado (`find-[nombre-modulo]-query.dto.ts` en plural)
2. El DTO de respuesta / serialización (`[nombre-modulo]-response.dto.ts` en singular)

### Reglas obligatorias que debes seguir:

1. **Estructura estricta para `Find[NombreModulo]QueryDto`:**
   - Debe incluir obligatoriamente y en una sola línea los imports necesarios de `class-validator` y `class-transformer`.
   - **No debe haber saltos de línea** entre el comentario de la ruta y los imports.
   - Debe incluir siempre los filtros estándar de paginación y búsqueda:
     - `estado_id` (opcional, entero, validado con `[1000, 1001, 1002]`).
     - `q` (opcional, string para búsqueda general).
     - `offset` y `limit` (opcionales, enteros con valores mínimos de 0 y 1 respectivamente).
     - `sortField` (opcional, string) y `sortOrder` (opcional, entero validado con `[1, -1]`).

2. **Estructura estricta para `[NombreModulo]ResponseDto`:**
   - El nombre de la clase debe estar en **singular** (ej. `EmpresaResponseDto`).
   - Debe mapear **absolutamente todas las columnas** de la tabla del DDL (incluyendo llaves primarias, foráneas, auditoría y fechas).
   - Todos los campos de la clase deben llevar el decorador `@Expose()`.
   - **Manejo de Fechas (¡MUY IMPORTANTE!):** 
     - Cualquier campo de tipo fecha (`TIMESTAMPTZ`, `DATE`, etc.) o de auditoría temporal (`fecha_...`) debe incluir obligatoriamente el import: `import { formatLocalDate } from '@/common/utils/date-formatter.util';`
     - Deben ser decorados con `@Expose()` y `@Transform(({ value }) => formatLocalDate(value))`.
   - Al final, puedes opcionalmente incluir un campo de apoyo para abreviaturas de estado como `@Expose() estadoAbreviatura?: string;`.

3. **Formato de Imports y Comentarios de Ruta:**
   - Las sentencias de importación **deben ir obligatoriamente en una sola línea** (prohibido usar saltos de línea dentro de las llaves `{ ... }`).
   - La primera línea de cada archivo debe ser un comentario exclusivo con la ruta absoluta:
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\find-[nombre-modulo]-query.dto.ts`
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\[nombre-modulo]-response.dto.ts`

4. **Bloques de Código Markdown:**
   - Todo el código generado para ambos archivos debe ir estrictamente dentro de bloques de código con comillas invertidas (backticks).

Aquí tienes el DDL de la tabla a procesar:
