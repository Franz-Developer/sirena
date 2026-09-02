-- ================================================================================================
-- Paso 9. Generar [nombre-entidad]-.entity.ts

Actúa como un Arquitecto de Software experto en NestJS, TypeORM y TypeScript.

### ⚠️ REGLA CRÍTICAMENTE OBLIGATORIA DE SEPARACIÓN:
NUNCA generes ambos archivos (ni múltiples archivos) en un solo bloque de código ni juntos. Cada archivo solicitado DEBE entregarse estrictamente en su propia ventana o bloque de código independiente (bloque markdown separado con backticks ```typescript ... ```), aislado uno del otro y comenzando obligatoriamente con el comentario de su ruta absoluta en la primera línea.

A partir del código DDL (SQL) de una tabla de PostgreSQL que te proporcionaré, tu tarea es generar exclusivamente el archivo de entidad de TypeORM (`[nombre-entidad].entity.ts`), respetando estrictamente las columnas, tipos de datos, restricciones, índices únicos condicionales y relaciones que se desprenden del DDL, siguiendo de forma idéntica las convenciones y ejemplos oficiales del proyecto 'sirena-backend'.

### REGLAS Y CONVENCIONES OBLIGATORIAS:

1. **Ruta, Nombre de Archivo y Comentario Inicial:** 
   - La primera línea del archivo generado debe ser estrictamente un comentario con la ruta absoluta del archivo, **sin saltos de línea previos**, con el formato: `// C:\sirena\sirena-backend\src\modules\[nombre_modulo_en_plural]\entities\[nombre-entidad-singular].entity.ts`
   - El nombre de la clase debe estar en PascalCase en singular y heredar obligatoriamente de `BaseAuditEntity` (ej: `export class Sucursal extends BaseAuditEntity`).

2. **Decorador @Entity e Índices (@Index):**
   - El decorador principal debe ser `@Entity({ name: '[nombre_tabla_en_plural]' })`.
   - Por cada índice único definido en el DDL (especialmente los condicionales del tipo `WHERE estado_id IN (...)`), debes declararlo explícitamente sobre la clase usando `@Index`, replicando exactamente el nombre, las columnas y la cláusula `where` (ej: `@Index('uix_suc_sucursal', ['empresa_id', 'sucursal'], { unique: true, where: 'estado_id IN (1000, 1002)' })`).

3. **Llave Primaria (@PrimaryGeneratedColumn):**
- La columna de la llave primaria debe usar `@PrimaryGeneratedColumn('increment', { name: '[nombre_pk_id]', type: 'bigint' })` (o `integer` según corresponda en el DDL) y usar el operador de afirmación definida `!` (ej: `banco_id!: number;`).

4. **Mapeo de Columnas (@Column):**
   - Cada campo de la tabla (excepto las columnas de auditoría heredadas de `BaseAuditEntity` como `estado_id` si se maneja como relación, `usuario_id_registro`, `fecha_registro`, etc., a menos que no formen parte de la auditoría base) debe mapearse con `@Column()`.
   - **Tipos de datos:** Mapear correctamente según PostgreSQL (`varchar`, `integer`, `bigint`, `decimal`, `date`, `timestamp`, etc.). Si es `decimal`, incluir precisión y escala (`precision: 10, scale: 2`).
   - **Nulabilidad y Defaults:** 
     - Si es `NOT NULL` sin default: `nullable: false` y usar afirmación definida `!`.
     - Si tiene `DEFAULT`, especificar `default: [valor]`.
     - Si es `NULL` (opcional): `nullable: true` y usar el tipo opcional con soporte a nulos `? string | null;` o `? number | null;`.

5. **Mapeo de Relaciones (ManyToOne / JoinColumn):**
   - Si la columna es una llave foránea que apunta a otra entidad (como `estado_id` hacia `Dominio` o `empresa_id` hacia `Empresa`), debes definir tanto la columna plana como la propiedad de relación:
     - Definir la columna si es requerida por lógica de negocio (ej: `empresa_id!: number;` con su `@Column`).
     - Definir la relación con `@ManyToOne(() => [EntidadDestino], { nullable: false, eager: false })`.
     - Vincularla con `@JoinColumn({ name: '[nombre_fk_id]', referencedColumnName: '[pk_tabla_destino_id]' })`.
     - Nombrar la propiedad en singular (ej: `estado!: Dominio;`, `empresa!: Empresa;`).

6. **Formato de Salida y Ventana Independiente:**
   - Devuelve el código TypeScript limpio, estructurado e indentado dentro de un **único bloque de código independiente (comillas invertidas / backticks ```typescript ... ```)**, comenzando estrictamente en la primera línea con el comentario de la ruta.

---
### EJEMPLO DE REFERENCIA OFICIAL:
// C:\sirena\sirena-backend\src\modules\sucursales\entities\sucursal.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Empresa } from '../../empresas/entities/empresa.entity';
import { Dominio } from '../../dominios/entities/dominio.entity';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'sucursales' })
@Index('uix_suc_sucursal', ['empresa_id', 'sucursal'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_suc_codigo', ['empresa_id', 'codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class Sucursal extends BaseAuditEntity {
    @PrimaryGeneratedColumn('increment', { name: 'sucursal_id', type: 'bigint' })
    sucursal_id!: number;

    @Column({ name: 'empresa_id', type: 'bigint', nullable: false, default: 1 })
    empresa_id!: number;

    @Column({ name: 'sucursal', type: 'varchar', length: 2000, nullable: false })
    sucursal!: string;

    @Column({ name: 'telefono', type: 'varchar', length: 100, nullable: true })
    telefono?: string | null;

    @Column({ name: 'factor_venta', type: 'decimal', precision: 10, scale: 2, nullable: false, default: 1.50 })
    factor_venta!: number;

    @ManyToOne(() => Empresa, { nullable: false, eager: false })
    @JoinColumn({ name: 'empresa_id', referencedColumnName: 'empresa_id' })
    empresa!: Empresa;

    @ManyToOne(() => Dominio, { nullable: false, eager: false })
    @JoinColumn({ name: 'estado_id', referencedColumnName: 'dominio_id' })
    estado!: Dominio;
}

-- ================================================================================================
-- Paso 10. Generar [nombre-entidad]-validator.service.ts

Actúa como un Arquitecto de Software experto en NestJS, TypeORM y TypeScript.

A partir del código DDL (SQL) de la tabla principal y una lista opcional de tablas hijas (dependencias) que te proporcionaré, tu tarea es generar exclusivamente el servicio de validación (`[nombre-entidad]-validator.service.ts`), siguiendo de forma estricta la estructura, patrones y convenciones del proyecto 'sirena-backend'.

### REGLAS Y CONVENCIONES OBLIGATORIAS:

1. **Ruta, Nombre de Archivo y Comentario Inicial:** 
   - La primera línea del archivo generado debe ser estrictamente un comentario con la ruta absoluta del archivo, **sin saltos de línea previos**, con el formato: `// C:\sirena\sirena-backend\src\common\validators\[nombre-entidad-en-plural]-validator.service.ts`
   - El nombre de la clase debe estar en PascalCase en plural seguido de `ValidatorService` (ej: `export class BancosValidatorService`).

2. **Inyección de Dependencias y Catálogos:**
   - Debe usar `@Injectable()`.
   - Inyectar el repositorio de la entidad usando `@InjectRepository([Entidad])` con visibilidad `private readonly`.
   - Inyectar `CatalogoDominioConfigService` para obtener los IDs dinámicos de estado (`ACTIVO_ID`, `HISTORICO_ID`).
   - Declarar getters privados para los estados estándar:
     ```typescript
     private get ACTIVO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
     private get HISTORICO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }
     ```

3. **Métodos de Validación Estándar Requeridos:**
   - **`validar[EntidadSingular]Activo(id: number): Promise<void>`**: Verifica que el registro exista (lanza `BadRequestException` si no existe) y que su `estado_id` sea igual a `ACTIVO_ID`.
   - **`validar[EntidadSingular]Historico(id: number): Promise<void>`**: Verifica existencia y que su `estado_id` sea igual a `HISTORICO_ID`.
   - **`validar[EntidadSingular]ActivoOHistorico(id: number): Promise<void>`**: Verifica existencia y que su `estado_id` se encuentre dentro de `[ACTIVO_ID, HISTORICO_ID]`.
   - **`validar[EntidadSingular]SinDependencias(id: number): Promise<void>`**: 
     - Verifica existencia primero seleccionando el campo principal identificador/nombre (ej: `banco`, `empresa`, etc.).
     - Si se proporcionan tablas hijas o relaciones dependientes en la entrada, construye una consulta SQL raw sumando los `COUNT(1)` de cada tabla hija donde la llave foránea coincida con el ID y el `estado_id` esté en `($2, $3)` (ACTIVO e HISTORICO).
     - Si el total de dependencias es mayor a 0, lanza un `BadRequestException` claro indicando que no se puede eliminar por registros asociados.

4. **Formato de Salida y Ventana Independiente:**
   - Devuelve únicamente el código TypeScript limpio, estructurado e indentado dentro de un **único bloque de código independiente (comillas invertidas / backticks ```typescript ... ```)**, comenzando en la primera línea con el comentario de la ruta.
   - Mensajes de error en español, claros y orientados al usuario.

---
### EJEMPLO DE REFERENCIA OFICIAL:
// C:\sirena\sirena-backend\src\common\validators\bancos-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Banco } from '../../modules/bancos/entities/banco.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class BancosValidatorService {
    constructor(
        @InjectRepository(Banco)
        private readonly bancoRepository: Repository<Banco>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    async validarBancoActivo(bancoId: number): Promise<void> {
        const bancoGeneral = await this.bancoRepository.findOne({
            where: { banco_id: bancoId },
            select: ['banco', 'estado_id']
        });

        if (!bancoGeneral) { throw new BadRequestException(`El banco indicado no existe en el sistema.`); }
        if (bancoGeneral.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`El banco "${bancoGeneral.banco}" no se encuentra en estado Activo.`); }
    }

    async validarBancoHistorico(bancoId: number): Promise<void> {
        const bancoGeneral = await this.bancoRepository.findOne({
            where: { banco_id: bancoId },
            select: ['banco', 'estado_id']
        });

        if (!bancoGeneral) { throw new BadRequestException(`El banco indicado no existe en el sistema.`); }
        if (bancoGeneral.estado_id !== this.HISTORICO_ID) { throw new BadRequestException(`El banco "${bancoGeneral.banco}" no se encuentra en estado Histórico.`); }
    }

    async validarBancoActivoOHistorico(bancoId: number): Promise<void> {
        const bancoGeneral = await this.bancoRepository.findOne({
            where: { banco_id: bancoId },
            select: ['banco', 'estado_id']
        });

        if (!bancoGeneral) { throw new BadRequestException(`El banco indicado no existe en el sistema.`); }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(bancoGeneral.estado_id)) { throw new BadRequestException(`El banco "${bancoGeneral.banco}" no se encuentra en un estado válido para la consulta.`); }
    }

    async validarBancoSinDependencias(bancoId: number): Promise<void> {
        const bancoGeneral = await this.bancoRepository.findOne({
            where: { banco_id: bancoId },
            select: ['banco']
        });

        if (!bancoGeneral) { throw new BadRequestException(`El banco indicado no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM tipos_cambios WHERE banco_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM empresas_cuentas WHERE banco_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM clientes WHERE banco_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM comprobantes_pagos WHERE banco_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.bancoRepository.query(query, [bancoId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar el banco "${bancoGeneral.banco}" porque tiene registros asociados en estado Activo o Histórico.`);
        }
    }
}

---
### ENTRADA (DDL Y TABLAS HIJAS):