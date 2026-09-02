-- ================================================================================================
-- Paso 7. Generar find-[nombre-modulo]-query.dto.ts

ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND EXPERTO EN NESTJS, TYPESCRIPT Y TYPEORM.

Tu tarea es generar el archivo de consulta `find-[nombre-modulo]-query.dto.ts` para un módulo específico, basándote en la estructura de la tabla SQL y el siguiente ejemplo oficial de referencia.

---

### EJEMPLO DE REFERENCIA OFICIAL:
// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\find-tipos-cambios-query.dto.ts
import { IsOptional, IsInt, IsString, Min, IsIn, IsDateString } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { formatOnlyDate } from '@/common/utils/date-formatter.util';
import { validateSafeText } from '@/common/utils/string.util';

export class FindTiposCambiosQueryDto {
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn([1000, 1001, 1002], { message: 'El estado_id debe ser 1000 (Activo), 1001 (Borrado) o 1002 (Histórico).' })
    estado_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El moneda_origen_id debe ser un número entero.' })
    @IsIn([2300, 2301, 2302, 2303], { message: 'El moneda_origen_id debe ser 2300 (Boliviano), 2301 (Dólar), 2302 (Euro) o 2303 (UFV).' })
    moneda_origen_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El banco_id debe ser un número entero.' })
    banco_id?: number;

    @IsOptional()
    @Transform(({ value }) => (value ? formatOnlyDate(value) : value))
    @IsDateString({}, { message: 'La fecha de cotización inicio debe tener un formato de fecha válido (YYYY-MM-DD).' })
    fecha_cotizacion_inicio?: string;

    @IsOptional()
    @Transform(({ value }) => (value ? formatOnlyDate(value) : value))
    @IsDateString({}, { message: 'La fecha de cotización fin debe tener un formato de fecha válido (YYYY-MM-DD).' })
    fecha_cotizacion_fin?: string;

    @IsOptional()
    @Transform(({ value }) => (typeof value === 'string' ? validateSafeText(value) : value))
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'offset debe ser un número entero.' })
    @Min(0, { message: 'offset debe ser >= 0' })
    offset?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'limit debe ser un número entero.' })
    @Min(1, { message: 'limit debe ser >= 1' })
    limit?: number;

    @IsOptional()
    @IsString({ message: 'El campo sortField debe ser una cadena de texto.' })
    sortField?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo sortOrder debe ser un número entero.' })
    @IsIn([1, -1], { message: 'El campo sortOrder debe ser 1 (ascendente) o -1 (descendente).' })
    sortOrder?: number;
}

---

### REGLAS OBLIGATORIAS PARA GENERAR EL DTO DE CONSULTA (`find-XXXX-query.dto.ts`):

1. **Naturaleza Opcional:** Absolutamente TODOS los campos del DTO de consulta deben llevar el decorador `@IsOptional()` y estar tipados como opcionales (`?`).
2. **Campos de Filtrado Específicos de la Tabla:**
   - **Filtros por Estado (`estado_id`):** Siempre incluirlo usando `@Type(() => Number)`, `@IsInt()`, e `@IsIn([1000, 1001, 1002], ...)` (o los estados que apliquen según la tabla).
   - **IDs / Dominios / FKs:** Si la columna es un dominio acotado en el SQL, validar con `@IsIn` y su respectiva lista de IDs permitidos. Si es una llave foránea dinámica (ej. `banco_id`), validar solo con `@IsInt()` y `@Type(() => Number)`.
   - **Rangos de Fechas (`_inicio` y `_fin`):** Si la tabla maneja fechas de negocio, incluir los pares `_inicio` y `_fin` aplicando obligatoriamente la transformación `@Transform(({ value }) => (value ? formatOnlyDate(value) : value))` y la validación `@IsDateString()`.
3. **Parámetro de Búsqueda Global (`q`):**
   - Siempre debe incluirse para soportar la barra de búsqueda de la interfaz.
   - Debe incorporar obligatoriamente la función de seguridad: `@Transform(({ value }) => (typeof value === 'string' ? validateSafeText(value) : value))` acompañado de `@IsString()`.
4. **Parámetros de Paginación y Ordenamiento Estándar (Obligatorios al final):**
   - `offset`: `@IsOptional()`, `@Type(() => Number)`, `@IsInt()`, `@Min(0)`
   - `limit`: `@IsOptional()`, `@Type(() => Number)`, `@IsInt()`, `@Min(1)`
   - `sortField`: `@IsOptional()`, `@IsString()`
   - `sortOrder`: `@IsOptional()`, `@Type(() => Number)`, `@IsInt()`, `@IsIn([1, -1])`
5. **Formato de Importaciones:** CADA importación debe ir estrictamente en una sola línea, sin saltos de línea intermedios.

-- ================================================================================================
-- Paso 8. Generar [nombre-entidad]-response.dto.ts

ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND EXPERTO EN NESTJS, TYPESCRIPT Y CLASS-TRANSFORMER.

Tu tarea es generar el archivo de respuesta `[nombre-entidad]-response.dto.ts` para un módulo específico, basándote en la estructura de la tabla SQL y el siguiente ejemplo oficial de referencia.

---

### EJEMPLO DE REFERENCIA OFICIAL:
// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\tipo-cambio-response.dto.ts
import { Expose, Type, Transform } from 'class-transformer';
import { DominioResponseDto } from '../../dominios/dto/dominio-response.dto';
import { BancoResponseDto } from '../../bancos/dto/banco-response.dto';
import { formatLocalDate, formatOnlyDate } from '@/common/utils/date-formatter.util';

export class TipoCambioResponseDto {
    @Expose() tipo_cambio_id!: number;
    @Expose() moneda_origen_id!: number;
    @Expose() moneda_destino_id!: number;
    @Expose() banco_id!: number;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
    factor_compra!: number;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
    factor_venta!: number;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_cotizacion!: string | null;

    @Expose() estado_id!: number;

    @Expose()
    @Type(() => DominioResponseDto)
    monedaOrigen?: DominioResponseDto;

    @Expose()
    @Type(() => DominioResponseDto)
    monedaDestino?: DominioResponseDto;

    @Expose()
    @Type(() => BancoResponseDto)
    banco?: BancoResponseDto;

    @Expose()
    @Type(() => DominioResponseDto)
    estado?: DominioResponseDto;

    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number;
    @Expose() usuario_id_baja?: number;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose() estadoAbreviatura?: string;
}

---

### REGLAS OBLIGATORIAS PARA GENERAR EL DTO DE RESPUESTA (`[nombre-entidad]-response.dto.ts`):

1. **Decorador Base `@Expose()`:**
   - Absolutamente **todas** las propiedades expuestas en la respuesta deben llevar el decorador `@Expose()`.

2. **Manejo de Tipos Numéricos y Decimales (`DECIMAL`, `NUMERIC`):**
   - Los campos numéricos decimales devuelven strings por defecto en TypeORM/PostgreSQL. Deben transformarse obligatoriamente con:
     ```typescript
     @Expose()
     @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
     nombre_campo!: number;
     ```

3. **Manejo de Fechas y Marcas de Tiempo (`DATE` vs `TIMESTAMPTZ`):**
   - **Para fechas simples (`DATE`):** Usar la utilidad `@Transform(({ value }) => formatOnlyDate(value))`.
   - **Para fechas y horas con zona horaria (`TIMESTAMPTZ` o auditorías como `fecha_registro`, `ultima_ejecucion`, `proxima_ejecucion`):** Deben transformarse obligatoriamente usando la utilidad de fecha y hora local:
     ```typescript
     @Expose()
     @Transform(({ value }) => formatLocalDate(value))
     nombre_campo!: string | null; // o opcional con ? si permite nulos en base de datos
     ```

4. **Manejo de Relaciones (FKs a Dominios u otras Tablas):**
   - Si la propiedad es un objeto relacional cargado (ej. `dominio`, `banco`, `estado`), se debe mapear usando `@Type(() => [NombreDto]ResponseDto)` apuntando al DTO de respuesta correspondiente de ese módulo.

5. **Campos de Texto Simples, Opcionales o Propiedades Calculadas:**
   - Campos como `lugar`, `eslogan`, `descripcion` o alias calculados (`estadoAbreviatura`) se exponen de forma directa o con tipado opcional (`?`), sin transformaciones complejas si ya vienen formateados:
     ```typescript
     @Expose() lugar?: string;
     @Expose() eslogan?: string;
     @Expose() descripcion?: string;
     ```

6. **Formato de Importaciones:** CADA importación debe ir estrictamente en una sola línea, sin saltos de línea intermedios.

-- ================================================================================================
