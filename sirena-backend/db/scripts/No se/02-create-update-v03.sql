Actúa como un arquitecto de software experto en NestJS, TypeScript, PostgreSQL y validación de datos usando `class-validator` y `class-transformer`.

Tu tarea es tomar el código DDL de una tabla de la base de datos Sirena y generar estrictamente dos archivos DTO limpios, profesionales y altamente descriptivos:
1. El DTO de creación (`create-[nombre-modulo].dto.ts`)
2. El DTO de actualización (`update-[nombre-modulo].dto.ts`)

### ⚠️ REGLAS OBLIGATORIAS E INQUEBRANTABLES (EL CUMPLIMIENTO ES DEL 100%)

1. **Mensajes robustos y descriptivos obligatorios:**
   - Absolutamente todos los decoradores de validación deben incluir obligatoriamente su propiedad `message` con un texto explicativo, claro, profesional y en español.
   - Prohibido dejar decoradores vacíos o sin parámetro de mensaje.

2. **Formato estricto de los Imports en UNA sola línea:**
   - Las sentencias de importación de `class-validator` y `class-transformer` **deben ir obligatoriamente en una sola línea**.
   - Queda estrictamente prohibido usar saltos de línea dentro de las llaves `{ ... }`.
   - Ejemplo correcto: `import { IsString, IsNotEmpty, IsNumber, IsOptional, MaxLength, MinLength, Min, Max, IsInt } from 'class-validator';`

3. **Omisión absoluta de campos de sistema:**
   - Excluye llaves primarias autoincrementables (ej. `[nombre]_id`).
   - Excluye campos de auditoría (`usuario_id_registro`, `usuario_id_actualizacion`, `usuario_id_baja`, `fecha_registro`, `fecha_actualizacion`, `fecha_baja`).
   - Excluye el campo `estado_id`.

4. **Tratamiento estricto de campos con DEFAULT y Nulabilidad (Cero Inventos):**
   - **No inventes restricciones ni obligatoriedades que el DDL no declare.** Analiza si la columna tiene `NOT NULL` sin `DEFAULT`, si permite `NULL`, o si posee una cláusula `DEFAULT ...`.
   - Si una columna en el DDL incluye una cláusula `DEFAULT` (por ejemplo, `DEFAULT 1.50`, `DEFAULT 0`, etc.), debes tratarla obligatoriamente como **opcional** en el DTO de creación usando `@IsOptional()`, ya que la base de datos se encargará de asignar dicho valor por defecto si el cliente no lo envía.
   - Si una columna es `NOT NULL` sin `DEFAULT`, entonces es obligatoria y debe llevar `@IsNotEmpty()` (o su equivalente según el tipo de dato). Si permite `NULL`, debe llevar `@IsOptional()`.

5. **Mapeo inteligente de Tipos de Datos Numéricos (`DECIMAL` / `NUMERIC`):**
   - Si una columna es de tipo `DECIMAL(p, s)` o `NUMERIC(p, s)`, debes mapearla estrictamente como tipo `number` utilizando el siguiente patrón de validación:
     ```typescript
     @Type(() => Number)
     @IsOptional() // (O el decorador de obligatoriedad según el DDL)
     @IsNumber({ maxDecimalPlaces: s }, { message: 'El campo [nombre] debe ser un número válido con hasta s decimales.' })
     @Min(0.01, { message: 'El campo [nombre] debe ser mayor a 0.' }) // (O el valor mínimo que dicte el DDL o lógica de negocio)
     [nombre]?: number;
     ```
   - Los campos `INTEGER` o `BIGINT` se mapean con `@Type(() => Number)` y `@IsInt()`.

6. **Transformaciones y Validaciones de Texto:**
   - Usa `@Transform(({ value }) => typeof value === 'string' ? value.trim() : value)` arriba de los strings.
   - Solo añade `.toUpperCase()` si el DDL contiene explícitamente una restricción del tipo `CONSTRAINT ... CHECK (campo = UPPER(campo))`. No lo inventes.
   - Respeta estrictamente los límites de `VARCHAR(n)` mapeándolos con `@MaxLength(n, { message: '...' })`. Si el DDL especifica un `CHECK (LENGTH(TRIM(campo)) >= x)`, tradúcelo a `@MinLength(x, { message: '...' })`.

7. **Estructura obligatoria para el DTO de Actualización (¡MUY IMPORTANTE!):**
   - El archivo `update-[singular].dto.ts` **NUNCA** debe reescribir ni duplicar los campos a mano. Debe usar obligatoriamente `PartialType` heredando del Create DTO de la siguiente manera exacta:
     ```typescript
     // C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\update-[nombre-modulo].dto.ts
     import { PartialType } from '@nestjs/mapped-types';
     import { Create[SingularPascalCase]Dto } from './create-[nombre-modulo].dto';

     export class Update[SingularPascalCase]Dto extends PartialType(Create[SingularPascalCase]Dto) {}
     ```

8. **Formato de Cabecera y Rutas Absolutas:**
   - La primera línea de cada archivo debe ser exactamente el comentario con la ruta absoluta:
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\create-[nombre-modulo].dto.ts`
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\update-[nombre-modulo].dto.ts`
   - Sin saltos de línea vacíos entre el comentario de ruta y el primer `import`.

9. **Formato de Salida y Ventana Independiente:**
   - Devuelve el código TypeScript limpio, estructurado e indentado dentro de un **único bloque de código independiente (comillas invertidas / backticks ```typescript ... ```)**, comenzando estrictamente en la primera línea con el comentario de la ruta.

10. NO INCLUIR 
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,

Aquí tienes el DDL de la tabla a procesar:
