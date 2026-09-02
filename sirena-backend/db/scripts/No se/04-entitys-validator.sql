-- ================================================================================================
-- Paso 9. Generar [nombre-entidad]-.entity.ts

ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND EXPERTO EN NESTJS, TYPESCRIPT Y TYPEORM.

Tu tarea es generar el archivo de entidad `[nombre-entidad].entity.ts` para un módulo específico, basándote en la estructura de la tabla SQL y el siguiente ejemplo oficial de referencia.
Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

---

### EJEMPLO DE REFERENCIA OFICIAL:
// C:\sirena\sirena-backend\src\modules\tipos-cambios\entities\tipo-cambio.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Dominio } from '../../dominios/entities/dominio.entity';
import { Banco } from '../../bancos/entities/banco.entity';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'tipos_cambios' })
@Index('uix_tpc_cotizacion_vigente', ['moneda_origen_id', 'moneda_destino_id', 'banco_id', 'fecha_cotizacion'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('idx_tpc_busqueda', ['moneda_origen_id', 'moneda_destino_id', 'banco_id', 'fecha_cotizacion'], { where: 'estado_id IN (1000, 1002)' })
export class TipoCambio extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ type: 'bigint', name: 'tipo_cambio_id', })
    tipo_cambio_id!: number;

    @Column({ name: 'moneda_origen_id', type: 'integer', nullable: false, default: 2300 })
    moneda_origen_id!: number;

    @ManyToOne(() => Dominio, { nullable: false })
    @JoinColumn({ name: 'moneda_origen_id' })
    monedaOrigen!: Dominio;

    @Column({ name: 'moneda_destino_id', type: 'integer', nullable: false, default: 2300 })
    moneda_destino_id!: number;

    @ManyToOne(() => Dominio, { nullable: false })
    @JoinColumn({ name: 'moneda_destino_id' })
    monedaDestino!: Dominio;

    @Column({
        name: 'banco_id',
        type: 'bigint',
        nullable: false,
        default: 1,
        transformer: {
            to: (value: number) => value,
            from: (value: string) => (value ? Number(value) : value),
        },
    })
    banco_id!: number;

    @ManyToOne(() => Banco, { nullable: false })
    @JoinColumn({ name: 'banco_id' })
    banco!: Banco;

    @Column({
        name: 'factor_compra',
        type: 'decimal',
        precision: 12,
        scale: 4,
        nullable: false,
        default: 1.0000,
        transformer: {
            to: (value: number) => value,
            from: (value: string) => (value ? Number(value) : value),
        },
    })
    factor_compra!: number;

    @Column({
        name: 'factor_venta',
        type: 'decimal',
        precision: 12,
        scale: 4,
        nullable: false,
        default: 1.0000,
        transformer: {
            to: (value: number) => value,
            from: (value: string) => (value ? Number(value) : value),
        },
    })
    factor_venta!: number;

    @Column({ name: 'fecha_cotizacion', type: 'date', nullable: false })
    fecha_cotizacion!: string;

    @ManyToOne(() => Dominio, { nullable: false })
    @JoinColumn({ name: 'estado_id' })
    estado!: Dominio;
}

---

### REGLAS OBLIGATORIAS PARA GENERAR LA ENTIDAD (`[nombre-entidad].entity.ts`):

1. **Herencia de Auditoría Base:**
   - La clase debe extender obligatoriamente de `BaseAuditEntity` (`export class NombreEntidad extends BaseAuditEntity`).
   - Declarar explícitamente la relación del estado si aplica:
     ```typescript
     @ManyToOne(() => Dominio, { nullable: false })
     @JoinColumn({ name: 'estado_id' })
     estado!: Dominio;
     ```

2. **Llave Primaria (`PrimaryGeneratedColumn`):**
   - Configurada como `bigint` con su nombre exacto:
     ```typescript
     @PrimaryGeneratedColumn({ type: 'bigint', name: 'nombre_id' })
     nombre_id!: number;
     ```

3. **Manejo de Tipos Especiales con Transformadores (`bigint` y `decimal`):**
   - Aplicar obligatoriamente el objeto `transformer` para castear de `string` a `number` desde la base de datos:
     ```typescript
     transformer: {
         to: (value: number) => value,
         from: (value: string) => (value ? Number(value) : value),
     }
     ```

4. **Manejo de Tipos de Datos Específicos (`JSONB` y `TIMESTAMPTZ`):**
   - **Campos JSON (`JSONB`):** Mapeados como objetos libres o genéricos de TypeScript, permitiendo valores nulos:
     ```typescript
     @Column({ name: 'parametros', type: 'jsonb', nullable: true })
     parametros?: Record<string, any> | null;
     ```
   - **Marcas de Tiempo con Zona Horaria (`TIMESTAMPTZ`):** Mapeadas típicamente como cadenas (`string`) o fechas de tipo texto/Date según se requiera, permitiendo nulidad si aplica:
     ```typescript
     @Column({ name: 'ultima_ejecucion', type: 'timestamptz', nullable: true })
     ultima_ejecucion?: string | null;

     @Column({ name: 'proxima_ejecucion', type: 'timestamptz', nullable: true })
     proxima_ejecucion?: string | null;
     ```

5. **Campos de Texto (`VARCHAR`):**
   - **Obligatorios:** `@Column({ name: 'codigo', type: 'varchar', length: 10, nullable: false }) codigo!: string;`
   - **Opcionales / Nulos:** `@Column({ name: 'descripcion', type: 'varchar', length: 1500, nullable: true }) descripcion?: string | null;`

6. **Índices en el Decorador de la Clase (`@Index`):**
   - Si la tabla define índices únicos o de búsqueda condicionales, agregarlos arriba de la clase:
     ```typescript
     @Index('nombre_indice', ['campo1', 'campo2'], { unique: true/false, where: 'estado_id IN (1000, 1002)' })
     ```

7. **Formato de Importaciones:** CADA importación debe ir estrictamente en una sola línea, sin saltos de línea intermedios.

8. **Recuerda no incluir 
	@Column({ name: 'estado_id', type: 'integer', nullable: false, default: 1000 })
    estado_id!: number;
	Por que ya esta en import { BaseAuditEntity } from '../../../common/base/base-audit.entity';
	
9. Pero si se debe incluir 
	@ManyToOne(() => Dominio, { nullable: false, eager: false })
    @JoinColumn({ name: 'estado_id', referencedColumnName: 'dominio_id' })
    estado!: Dominio;

10. Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

-- ================================================================================================
-- Paso 10. Generar [nombre-entidad]-validator.service.ts

ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND EXPERTO EN NESTJS, TYPESCRIPT Y TYPEORM.

Tu tarea es generar el archivo de servicio de validación `[nombre-modulo]-validator.service.ts` para un módulo específico, basándote en los requerimientos del módulo y tomando como referencia los siguientes ejemplos oficiales.

---

### EJEMPLOS DE REFERENCIA OFICIAL:

#### 1. Referencia: Validación de Entidad Simple y Verificación de Dependencias Cruzadas por SQL
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
            throw new BadRequestException(`No se puede eliminar el banco "${bancoGeneral.banco}" porque tiene registros asociados (tipos de cambio, cuentas, clientes o comprobantes) en estado Activo o Histórico.`);
        }
    }
}

#### 2. Referencia: Validación de Reglas de Negocio Cruzadas (DTOs / Atributos)
// C:\sirena\sirena-backend\src\common\validators\tipos-cambios-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TipoCambio } from '../../modules/tipos-cambios/entities/tipo-cambio.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class TiposCambiosValidatorService {
    constructor(
        @InjectRepository(TipoCambio)
        private readonly tipoCambioRepository: Repository<TipoCambio>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }
	
	async validarRegistroProtegido(id: number): Promise<void> {
		if (id === 1) {
			throw new BadRequestException('Esta operación no está permitida para el registro protegido del sistema (ID 1).');
		}
	}
	
    async validarTipoCambioActivo(tipoCambioId: number): Promise<void> {
        const tipoCambio = await this.tipoCambioRepository.findOne({
            where: { tipo_cambio_id: tipoCambioId },
            select: ['tipo_cambio_id', 'estado_id']
        });

        if (!tipoCambio) { throw new BadRequestException(`El tipo de cambio indicado no existe en el sistema.`); }
        if (tipoCambio.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`El tipo de cambio con ID ${tipoCambioId} no se encuentra en estado Activo.`); }
    }

    async validarReglasNegocio(dto: { moneda_origen_id: number; moneda_destino_id: number; factor_compra: number; factor_venta: number }): Promise<void> {
        if (dto.moneda_origen_id === dto.moneda_destino_id) {
            throw new BadRequestException(`La moneda de origen y la moneda de destino no pueden ser iguales.`);
        }
        if (dto.factor_compra > dto.factor_venta) {
            throw new BadRequestException(`El factor de compra (${dto.factor_compra}) no puede ser mayor que el factor de venta (${dto.factor_venta}).`);
        }
    }
}

---

### REGLAS OBLIGATORIAS PARA GENERAR EL SERVICIO DE VALIDACIÓN (`[nombre-modulo]-validator.service.ts`):

1. **Estructura y Decoradores Base:**
   - La clase debe llevar obligatoriamente el decorador `@Injectable()`.
   - Inyectar el repositorio correspondiente mediante `@InjectRepository(Entidad)` y el servicio de catálogos global `CatalogoDominioConfigService`.

2. **Getters de Estados del Sistema:**
   - Declarar siempre los accesores privados para estandarizar los IDs de estado dinámicos extraídos de la configuración:
     ```typescript
     private get ACTIVO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
     private get HISTORICO_ID() { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }
     ```

3. **Métodos de Validación de Existencia y Estado (`validar[Entidad]Activo`, etc.):**
   - Verificar si el registro existe en base de datos. Si no existe, lanzar un `BadRequestException` indicando que el registro no existe.
   - Validar que su `estado_id` corresponda al estado requerido (Activo, Histórico, o combinación de ambos con `.includes()`). De lo contrario, lanzar un `BadRequestException` con un mensaje descriptivo que incluya el nombre, código o identificador clave del registro.

4. **Validaciones de Dependencias Cruzadas (`validar[Entidad]SinDependencias`):**
   - Si la entidad puede tener registros dependientes en otras tablas del sistema al momento de un borrado o desactivación, ejecutar una consulta SQL optimizada mediante `repository.query()` sumando los conteos `COUNT(1)` donde el ID coincida y el estado esté Activo o Histórico.
   - Si `total > 0`, bloquear la operación lanzando un `BadRequestException` listando explícitamente las tablas o módulos afectados.

5. **Validaciones de Negocio Específicas (`validarReglasNegocio`):**
   - Implementar métodos de validación lógica basados en los atributos del DTO (comparaciones matemáticas, rangos, restricciones cruzadas de campos) lanzando `BadRequestException` ante cualquier inconsistencia.
   - Se debe Implementar todos los CHECK del DDL de la tabla.
   - Se debe Implementar todos los UNIQUE INDEX
   - Se debe Implementar todas las fechas que tengan NOT NULL

6. **Formato de Importaciones:** CADA importación debe ir estrictamente en una sola línea, sin saltos de línea intermedios.

7. Se debe disponer de las tablas que son dependientes (HIJAS) para GENERAR EL SERVICIO DE VALIDACIÓN si no se cuenta con ese dato no 
	se puede GENERAR EL SERVICIO DE VALIDACIÓN por lo tanto solicitar las tablas que son dependientes (HIJAS)
	Si la tabla no tiene tablas dependientes (HIJAS) se debe obviar la funcion `validar[Entidad]SinDependencias`.

8. Siempre se debe poner para porteger 
	/**
     * Valida si el registro está protegido (ID 1). 
     * Aplica de manera obligatoria para operaciones de update, remove, archivar y desarchivar.
     */
    async validarRegistroProtegido(pruebaId: number): Promise<void> {
        if (Number(pruebaId) === 1) {
            throw new BadRequestException('Esta operación no está permitida para el registro protegido del sistema (ID 1).');
        }
    }
	
9. Los nombres de las funciones deben terminar con la letra o 

// ❌ INCORRECTO
await this.pruebasValidator.validarPruebaActiva(id);
await this.pruebasValidator.validarPruebaActivaOHistorica(id);
await this.pruebasValidator.validarPruebaHistorica(id);

// ✅ CORRECTO
await this.pruebasValidator.validarPruebaActivo(id);
await this.pruebasValidator.validarPruebaActivoOHistorico(id);
await this.pruebasValidator.validarPruebaHistorico(id);

10. Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

11. Si en el DDL existe fechas y restricciones tipo 
fecha_cotizacion DATE NOT NULL,
fecha_inicio DATE NOT NULL,
fecha_fin DATE NULL,
fecha_prueba TIMESTAMPTZ NULL,
fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
el control de las fecha se debe definir en validarReglasNegocio
if (dto.fecha_prueba && dto.fecha_inicio) {
		const fechaPrueba = new Date(dto.fecha_prueba);
		const fechaInicio = new Date(dto.fecha_inicio);
		if (fechaPrueba < fechaInicio) {
			throw new BadRequestException('La fecha de prueba no puede ser anterior a la fecha de inicio.');
		}
	}

	if (dto.fecha_prueba && dto.fecha_cotizacion) {
		const fechaPrueba = new Date(dto.fecha_prueba);
		const fechaCotizacion = new Date(dto.fecha_cotizacion);
		if (fechaPrueba < fechaCotizacion) {
			throw new BadRequestException('La fecha de prueba no puede ser anterior a la fecha de cotización.');
		}
	}

	if (dto.fecha_hora && dto.fecha_inicio) {
		const fechaHora = new Date(dto.fecha_hora);
		const fechaInicio = new Date(dto.fecha_inicio);
		if (fechaHora < fechaInicio) {
			throw new BadRequestException('La fecha y hora no puede ser anterior a la fecha de inicio.');
		}
	}

-- ================================================================================================
