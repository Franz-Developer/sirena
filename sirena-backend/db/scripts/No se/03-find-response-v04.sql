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
[AQUÍ PEGÁS EL DDL DE TU TABLA]

-- ================================================================================================
-- Paso 8. Generar [nombre-entidad]-response.dto.ts

Actúa como un Arquitecto de Software experto en NestJS, TypeScript y transformación de datos usando 'class-transformer'.

A partir del código DDL (SQL) de una tabla de PostgreSQL que te proporcionaré, tu tarea es generar exclusivamente el archivo de DTO de respuesta (`[nombre-entidad]-response.dto.ts`), siguiendo de forma estricta la estructura, tipos, decoradores y convenciones del proyecto 'sirena-backend'.

### REGLAS Y CONVENCIONES OBLIGATORIAS:

1. **Ruta, Nombre de Archivo y Comentario Inicial:** 
   - La primera línea del archivo generado debe ser estrictamente un comentario con la ruta absoluta del archivo, **sin saltos de línea previos**, con el formato: `// C:\sirena\sirena-backend\src\modules\[nombre_modulo_en_plural]\dto\[nombre-entidad-singular]-response.dto.ts`
   - El nombre de la clase DTO debe ser en PascalCase en singular seguido de `ResponseDto` (ej: si la tabla es 'bancos', la clase es `BancoResponseDto`).

2. **Mapeo de Columnas Base y Tipos de Datos:**
   - **Campos obligatorios (`NOT NULL` sin default o con valor requerido):** Usar el operador de afirmación definida `!` (ej: `@Expose() dominio_id!: number;`).
   - **Campos opcionales (`NULL` o con `DEFAULT` opcional):** Usar el signo de interrogación `?` y permitir `null` si corresponde (ej: `@Expose() prefijo?: string | null;`).
   - **Tipos numéricos (DECIMAL, NUMERIC, FLOAT, REAL):** Si la columna es un número decimal o de precisión, aplicar transformación numérica obligatoria:
     ```typescript
     @Expose()
     @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
     [nombre_campo]!: number; // o tipo opcional según corresponda
     ```

3. **Manejo de Fechas y Timestamps:**
   - Por cada columna de tipo fecha o timestamp (`DATE`, `TIMESTAMP`, `TIMESTAMPTZ`):
     - Si es tipo `DATE` (ej: `fecha_cotizacion`), usar el formateador `formatOnlyDate`:
       ```typescript
       @Expose()
       @Transform(({ value }) => formatOnlyDate(value))
       [nombre_campo]!: string | null;
       ```
     - Si son campos de auditoría de fecha (`fecha_registro`, `fecha_actualizacion`, `fecha_baja`), usar obligatoriamente `formatLocalDate`:
       ```typescript
       @Expose()
       @Transform(({ value }) => formatLocalDate(value))
       fecha_registro!: string | null; // o el sufijo correspondiente
       ```
   - Asegúrate de incluir las importaciones de utilidades de fecha al inicio del archivo:
     `import { formatLocalDate, formatOnlyDate } from '@/common/utils/date-formatter.util';` (según aplique).

4. **Manejo de Claves Foráneas (FKs) y Relaciones:**
   - Para las columnas FK crudas (ej: `estado_id`, `banco_id`, `moneda_origen_id`), mapearlas normalmente como propiedades numéricas con `@Expose()`.
   - Si la tabla detecta relaciones comunes (como `estado_id` que apunta a dominios, o claves que relacionan catálogos/entidades), incluye opcionalmente las propiedades anidadas tipadas con su respectivo DTO de respuesta y el decorador `@Type(() => [Entidad]ResponseDto)` (ej: `estado?: DominioResponseDto;`, `banco?: BancoResponseDto;`).
   - Añade siempre al final de las propiedades de relación o auditoría el campo virtual común de apoyo si aplica: `@Expose() estadoAbreviatura?: string;`.

5. **Regla Especial para `empresa_id`:**
   - Si la tabla analizada incluye la columna `empresa_id` (por ejemplo, `empresa_id BIGINT NOT NULL DEFAULT 1`), debes agregar de forma obligatoria los campos planos representativos de la empresa relacionados en la respuesta para evitar joins complejos o mostrar su contexto:
     ```typescript
     @Expose() empresaEmpresa?: string;
     @Expose() empresaCodigo?: string;
     ```

6. **Regla Especial para Campos de tipo Logo (`logo`):**
   - Si la tabla analizada incluye la columna `logo` (por ejemplo, `logo VARCHAR(255) NOT NULL`), debes aplicarle obligatoriamente el siguiente bloque de transformación dinámico de URL:
     ```typescript
     @Expose()
     @Transform(({ value }) => {
         if (!value) return null;
         if (value.startsWith('http')) return value;
         const port = process.env['PORT'] || 3010;
         const host = process.env['APP_URL'] || `http://localhost:${port}`;
         return `${host}/api/logos/${value}`;
     })
     logo!: string; // o tipo opcional según corresponda
     ```

7. **Formato de Salida:**
   - Devuelve únicamente el código TypeScript limpio, estructurado e indentado, comenzando de inmediato con el comentario de la ruta.

8. ** Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

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
	@Expose() empresa_id!: number;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
    factor_compra!: number;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : value))
    factor_venta!: number;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_cotizacion!: string | null;
	
	@Expose()
    @Transform(({ value }) => {
        if (!value) return null;
        if (value.startsWith('http')) return value;
        const port = process.env['PORT'] || 3010;
        const host = process.env['APP_URL'] || `http://localhost:${port}`;
        return `${host}/api/logos/${value}`;
    })
    logo!: string;
	
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

	@Expose() empresaEmpresa?: string;
    @Expose() empresaCodigo?: string;
	
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
### DDL DE ENTRADA:
