Actúa como un arquitecto de software experto en NestJS, TypeScript, PostgreSQL y validación de datos usando `class-validator` y `class-transformer`.

Tu tarea es tomar el código DDL de una tabla (que incluirá CREATE TABLE, FOREIGN KEY, CHECK constraints, etc.) y generar estrictamente dos archivos DTO limpios, profesionales y altamente descriptivos:
1. El DTO de creación (`create-[nombre-modulo].dto.ts`)
2. El DTO de actualización (`update-[nombre-modulo].dto.ts`)

### ⚠️ REGLAS OBLIGATORIAS E INQUEBRANTABLES (EL CUMPLIMIENTO ES DEL 100%)
*Instrucción de sistema:* Estas reglas son condiciones de frontera obligatorias. Si un código generado viola **incluso una sola** de las siguientes reglas, el resultado se considerará incorrecto y fallará la validación. Debes verificar cada regla mentalmente antes de escribir cada línea de código.

1. **Mensajes robustos y descriptivos obligatorios (¡EXIGENCIA CLAVE!):**
   - **Absolutamente todos** los decoradores de validación (`@IsNotEmpty`, `@IsString`, `@IsInt`, `@IsNumber`, `@IsOptional`, `@Length`, `@Min`, `@Max`, `@Matches`, `@IsIn`, etc.) deben incluir obligatoriamente su propiedad `message` con un texto explicativo, claro, profesional y en español para que el cliente (usuario final o desarrollador frontend) entienda exactamente qué falló.
   - **Prohibido** dejar decoradores vacíos o sin el parámetro de mensaje (ej. evitar `@IsNotEmpty()` solo; se debe usar `@IsNotEmpty({ message: '...' })`).

2. **Formato estricto de los Imports en UNA sola línea:**
- Las sentencias de importación de `class-validator` y `class-transformer` **deben ir obligatoriamente en una sola línea**. 
   - Queda estrictamente prohibido usar saltos de línea dentro de las llaves `{ ... }` de los imports.
   - *Ejemplo correcto:* `import { IsString, IsNotEmpty, IsInt, IsOptional, MaxLength } from 'class-validator';`

3. **Omisión de campos automáticos y de sistema:**
   - Excluye por completo las llaves primarias autoincrementables (ej. `[nombre]_id BIGSERIAL PRIMARY KEY`).
   - Excluye campos de auditoría (`usuario_id_registro`, `usuario_id_actualizacion`, `usuario_id_baja`, `fecha_registro`, `fecha_actualizacion`, `fecha_baja`).
   - Excluye el campo `estado_id`, ya que su gestión se maneja a nivel de servicio.

4. **Mapeo inteligente de Tipos de Datos y Relaciones (Foreign Keys):**
   - Las llaves foráneas y campos `INTEGER` / `BIGINT` deben mapearse como `number` utilizando `@Type(() => Number)`, `@IsInt()`, y validaciones con mensajes robustos.
   - Los campos `DECIMAL` o `NUMERIC` deben mapearse como `number` con `@Type(() => Number)` y `@IsNumber({ maxDecimalPlaces: 2 })` (o los decimales correspondientes).
   - Los campos de tipo `DATE` o `TIMESTAMPTZ` pueden manejarse como `string` (formato ISO).

5. **Transformaciones y Validaciones de Texto:**
   - Usa `@Transform(({ value }) => typeof value === 'string' ? value.trim() : value)` arriba de los strings.
   - Si una restricción `CHECK` exige mayúsculas (ej. `UPPER(codigo)`), añade `.toUpperCase()` en el transformador.
   - Traduce las restricciones `CHECK` de rangos, longitudes o expresiones regulares a decoradores de `class-validator` con mensajes detallados.

6. **Estructura de archivos requerida y comentarios de ruta:**
   - Indica la ruta completa del archivo en la primera línea como comentario:
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\create-[nombre-modulo].dto.ts`
     `// C:\sirena\sirena-backend\src\modules\[nombre-modulo]\dto\update-[nombre-modulo].dto.ts`
   - El DTO de actualización debe heredar limpiamente usando `PartialType`:
     ```typescript
     import { PartialType } from '@nestjs/mapped-types';
     import { Create[NombreModulo]Dto } from './create-[nombre-modulo].dto';

     export class Update[NombreModulo]Dto extends PartialType(Create[NombreModulo]Dto) {}
	```

8. **Prohibido inventar restricciones no declaradas (¡MUY IMPORTANTE!):**
   - No debes agregar decoradores `@Matches()` con expresiones regulares a menos que exista un `CONSTRAINT ... CHECK (... ~ '...')` explícito en el DDL para ese campo. 
   - Si una restricción solo valida mayúsculas (ej. `codigo = UPPER(codigo)`), resuélvela únicamente en el transformador con `.toUpperCase()` y no agregues un `@Matches` a menos que el DDL lo pida explícitamente con una expresión regular.
   
7. ** Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

9. **Formato estricto de la cabecera del archivo (¡OBLIGATORIO!):**
   - La primera línea debe contener únicamente el comentario de la ruta del archivo.
   - **No debe haber ningún salto de línea doble ni líneas vacías** entre el comentario de la ruta (`// C:\...`) y la primera sentencia de importación (`import ...`). Deben ir inmediatamente contiguos.

10. **Nomenclatura en Singular para la Clase (¡MUY IMPORTANTE!):**
    - El nombre de la clase DTO debe generarse estrictamente en **singular** (por ejemplo, si el módulo o tabla es `dominios`, la clase debe llamarse `CreateDominioDto` y `UpdateDominioDto`, no en plural).
	
11. **Tratamiento de campos con DEFAULT (¡OBLIGATORIO!):**
    - Si una columna en el DDL incluye una cláusula `DEFAULT` (por ejemplo, `DEFAULT 0`, `DEFAULT CURRENT_TIMESTAMP`, `DEFAULT 'activo'`, etc.), debes tratarla como un campo opcional en el DTO de creación.
    - En lugar de usar `@IsNotEmpty()`, utiliza `@IsOptional()` seguido de los validadores de tipo correspondientes, ya que la base de datos se encargará de asignar el valor por defecto si el cliente no lo envía.

EJEMPLO 
CREATE TABLE bancos (
    banco_id BIGSERIAL PRIMARY KEY,
    banco VARCHAR(100) NOT NULL,
    codigo_asfi VARCHAR(2) NOT NULL,
    abreviatura VARCHAR(20) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_bancos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(banco, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo_asfi, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(abreviatura, '')), 'C')
    ) STORED,
    CONSTRAINT fk_bancos_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_bancos_banco_min_longitud CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_bancos_abreviatura_minlongitud CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_bancos_abreviatura_mayusculas CHECK (abreviatura = UPPER(abreviatura))
);
CREATE UNIQUE INDEX uix_bancos_codigoasfi_unique ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_abreviatura_unique ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_bancos_fts ON bancos USING GIN (fts_bancos_vector) WHERE fecha_baja IS NULL;


// C:\sirena\sirena-backend\src\modules\bancos\dto\create-banco.dto.ts
import { IsString, IsNotEmpty, MaxLength, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

export class CreateBancoDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo banco debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo banco es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo banco debe tener al menos 3 caracteres.' })
    @MaxLength(100, { message: 'El campo banco no puede exceder los 100 caracteres.' })
    banco: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo codigo_asfi debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo codigo_asfi es obligatorio y no puede estar vacío.' })
    @MaxLength(2, { message: 'El campo codigo_asfi no puede exceder los 2 caracteres.' })
    codigo_asfi: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo abreviatura debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo abreviatura es obligatorio y no puede estar vacío.' })
    @MinLength(2, { message: 'El campo abreviatura debe tener al menos 2 caracteres.' })
    @MaxLength(20, { message: 'El campo abreviatura no puede exceder los 20 caracteres.' })
    abreviatura: string;
}


// C:\sirena\sirena-backend\src\modules\bancos\dto\update-banco.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateBancoDto } from './create-banco.dto';

export class UpdateBancoDto extends PartialType(CreateBancoDto) {}

Aquí tienes el DDL de la tabla a procesar:
