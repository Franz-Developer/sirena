CREATE TABLE roles_permisos_tablas (
    rol_permiso_tabla_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL,
    tabla_id BIGINT NOT NULL,
    leer SMALLINT NOT NULL DEFAULT 0,
    crear SMALLINT NOT NULL DEFAULT 0,
    editar SMALLINT NOT NULL DEFAULT 0,
    eliminar SMALLINT NOT NULL DEFAULT 0,
    anular SMALLINT NOT NULL DEFAULT 0,
    archivar SMALLINT NOT NULL DEFAULT 0,
    desarchivar SMALLINT NOT NULL DEFAULT 0,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rpt_rol FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT fk_rpt_tabla FOREIGN KEY (tabla_id) REFERENCES tablas(tabla_id),
    CONSTRAINT chk_rpt_estado CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_rpt_leer CHECK (leer IN (0, 1)),
    CONSTRAINT chk_rpt_crear CHECK (crear IN (0, 1)),
    CONSTRAINT chk_rpt_editar CHECK (editar IN (0, 1)),
    CONSTRAINT chk_rpt_eliminar CHECK (eliminar IN (0, 1)),
    CONSTRAINT chk_rpt_anular CHECK (anular IN (0, 1)),
    CONSTRAINT chk_rpt_archivar CHECK (archivar IN (0, 1)),
    CONSTRAINT chk_rpt_desarchivar CHECK (desarchivar IN (0, 1)),
    CONSTRAINT chk_rpt_no_vacio CHECK (
        leer = 1 OR crear = 1 OR editar = 1 OR
        eliminar = 1 OR anular = 1 OR archivar = 1 OR
        desarchivar = 1
    )
);
CREATE UNIQUE INDEX uix_rpt_unique ON roles_permisos_tablas (rol_id, tabla_id) WHERE estado_id = 1000;

// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts
// ==========================================
// INTERFAZ GENERAL PARA CONSTANTES PARAMÉTRICOS
// ==========================================
export interface ConstanteMetadata {
    id: number;
    abreviatura: string;
    prefijo: string | null;
    valor: number;
    descripcion: string;
}

// ==========================================
// ESTADO
// ==========================================
export enum Estado {
    ACTIVO = 1000,
    BORRADO = 1001,
    HISTORICO = 1002,
    ANULADO = 1003,
}

export const ESTADO_ACTIVO = Estado.ACTIVO;
export const ESTADO_HISTORICO = Estado.HISTORICO;
export const ESTADO_BORRADO = Estado.BORRADO;
export const ESTADO_ANULADO = Estado.ANULADO;

export const ESTADOS_CONSULTA = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_PERMITIDOS = [
    Estado.ACTIVO,
    Estado.BORRADO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    Estado.ACTIVO,
    Estado.HISTORICO
	] as const;

export const ESTADOS_VIVOS_ESPECIAL = [
Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO
] as const;

export const ESTADO_METADATA: Record<Estado, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};

// ==========================================
// TIPO OPERACION ALMACEN
// ==========================================
export enum TipoOperacionAlmacen {
    LOGISTICA_INTERNA = 4050,
    VENTA_DIRECTA = 4051,
}

export const TIPO_OPERACION_ALMACEN_METADATA: Record<TipoOperacionAlmacen, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoOperacionAlmacen.LOGISTICA_INTERNA]: { id: TipoOperacionAlmacen.LOGISTICA_INTERNA, abreviatura: 'LOGISTICA_INTERNA', prefijo: 'LI', valor: 0, descripcion: 'Almacén destinado a depósito general, tránsito o reabastecimiento interno sin venta directa. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoOperacionAlmacen.VENTA_DIRECTA]: { id: TipoOperacionAlmacen.VENTA_DIRECTA, abreviatura: 'VENTA_DIRECTA', prefijo: 'VD', valor: 1, descripcion: 'Almacén vinculado a un punto de venta donde las transacciones afectan directamente el stock operativo.' },
};

// ==========================================
// TIPO ALMACEN
// ==========================================
export enum TipoAlmacen {
    NORMAL = 1700,
    REFRIGERADO = 1701,
    CONGELADO = 1702,
    ESPECIAL = 1703,
    TRANSITO = 1704,
    MATERIAL_MEDICO = 1705,
    COSMETICA = 1706,
    ALIMENTOS = 1707,
    MATERIA_PRIMA = 1708,
    RECEPCION = 1709,
    DEVOLUCIONES = 1710,
    DESPACHO = 1711,
    CUARENTENA = 1712,
}

export const TIPOS_ALMACEN_VENTA_DIRECTA = [
    TipoAlmacen.NORMAL,
    TipoAlmacen.REFRIGERADO,
    TipoAlmacen.CONGELADO,
    TipoAlmacen.ESPECIAL,
    TipoAlmacen.MATERIAL_MEDICO,
    TipoAlmacen.COSMETICA,
    TipoAlmacen.ALIMENTOS,
    TipoAlmacen.MATERIA_PRIMA,
] as const;

export const TIPOS_ALMACEN_LOGISTICA_INTERNA = [
    TipoAlmacen.TRANSITO,
	TipoAlmacen.RECEPCION,
	TipoAlmacen.DEVOLUCIONES,
	TipoAlmacen.DESPACHO,
	TipoAlmacen.CUARENTENA,
] as const;

export const TIPO_ALMACEN_METADATA: Record<TipoAlmacen, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAlmacen.NORMAL]: { id: TipoAlmacen.NORMAL, abreviatura: 'NORMAL', prefijo: null, valor: 0, descripcion: 'Almacén de temperatura ambiente, para productos que no requieren condiciones especiales de conservación. Aplica para la mayoría de medicamentos de venta libre y productos de consumo regular. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAlmacen.REFRIGERADO]: { id: TipoAlmacen.REFRIGERADO, abreviatura: 'REFRIGERADO', prefijo: null, valor: 0, descripcion: 'Almacén refrigerado con temperatura controlada. Para vacunas, insulinas, biológicos y medicamentos termolábiles que requieren cadena de frío.' },
    [TipoAlmacen.CONGELADO]: { id: TipoAlmacen.CONGELADO, abreviatura: 'CONGELADO', prefijo: null, valor: 0, descripcion: 'Almacén congelado con temperatura controlada. Para productos biológicos, hemoderivados y medicamentos que requieren congelación profunda para su conservación.' },
    [TipoAlmacen.ESPECIAL]: { id: TipoAlmacen.ESPECIAL, abreviatura: 'ESPECIAL', prefijo: null, valor: 0, descripcion: 'Almacén de alta seguridad para productos controlados (psicotrópicos, estupefacientes, sustancias fiscalizadas).' },
    [TipoAlmacen.TRANSITO]: { id: TipoAlmacen.TRANSITO, abreviatura: 'TRANSITO', prefijo: null, valor: 0, descripcion: 'Almacén temporal para mercadería en tránsito entre sucursales o en proceso de distribución. Productos con estado de "en movimiento" que no están disponibles para venta hasta su recepción en destino.' },
    [TipoAlmacen.MATERIAL_MEDICO]: { id: TipoAlmacen.MATERIAL_MEDICO, abreviatura: 'MATERIAL_MEDICO', prefijo: null, valor: 0, descripcion: 'Almacén para material médico-quirúrgico, dispositivos médicos, insumos descartables (jeringas, guantes, gasas) y equipos de diagnóstico. No requiere condiciones especiales de temperatura.' },
    [TipoAlmacen.COSMETICA]: { id: TipoAlmacen.COSMETICA, abreviatura: 'COSMETICA', prefijo: null, valor: 0, descripcion: 'Almacén para productos cosméticos, de cuidado personal, higiene y belleza. Incluye cremas, lociones, shampoos, perfumes y productos de maquillaje.' },
    [TipoAlmacen.ALIMENTOS]: { id: TipoAlmacen.ALIMENTOS, abreviatura: 'ALIMENTOS', prefijo: null, valor: 0, descripcion: 'Almacén para suplementos nutricionales, alimentos funcionales, vitaminas, minerales y productos dietéticos. Requiere condiciones de humedad controlada y protección contra contaminación cruzada.' },
    [TipoAlmacen.MATERIA_PRIMA]: { id: TipoAlmacen.MATERIA_PRIMA, abreviatura: 'MATERIA_PRIMA', prefijo: null, valor: 0, descripcion: 'Almacén para materias primas utilizadas en farmacia magistral o preparación de fórmulas personalizadas. Incluye principios activos, excipientes, vehículos y materiales de acondicionamiento.' },
    [TipoAlmacen.RECEPCION]: { id: TipoAlmacen.RECEPCION, abreviatura: 'RECEPCION', prefijo: null, valor: 0, descripcion: 'Área de recepción de mercadería y control de calidad. Zona de tránsito para productos que ingresan al sistema, pendientes de verificación, conteo y asignación a su almacén definitivo.' },
    [TipoAlmacen.DEVOLUCIONES]: { id: TipoAlmacen.DEVOLUCIONES, abreviatura: 'DEVOLUCIONES', prefijo: null, valor: 0, descripcion: 'Área para productos en proceso de devolución a proveedores o clientes. Incluye productos defectuosos, vencidos, dañados o en espera de gestión de devolución.' },
    [TipoAlmacen.DESPACHO]: { id: TipoAlmacen.DESPACHO, abreviatura: 'DESPACHO', prefijo: null, valor: 0, descripcion: 'Área de despacho, consolidación de pedidos y preparación de entregas. Productos que han sido seleccionados (picking) y están listos para distribución a clientes o traslado entre sucursales.' },
    [TipoAlmacen.CUARENTENA]: { id: TipoAlmacen.CUARENTENA, abreviatura: 'CUARENTENA', prefijo: null, valor: 0, descripcion: 'Área de cuarentena sanitaria para productos en revisión, análisis o evaluación. Incluye productos sospechosos de contaminación, lotes en investigación o productos pendientes de liberación por control de calidad.' },
};

export const TIPOS_ALMACEN_VENTA_DIRECTA_METADATA = Object.fromEntries(TIPOS_ALMACEN_VENTA_DIRECTA.map(id => [id, TIPO_ALMACEN_METADATA[id]]));
export const TIPOS_ALMACEN_LOGISTICA_INTERNA_METADATA = Object.fromEntries(TIPOS_ALMACEN_LOGISTICA_INTERNA.map(id => [id, TIPO_ALMACEN_METADATA[id]]));

// C:\sirena\sirena-backend\src\modules\almacenes\dto\create-almacen.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateAlmacenDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number = 1;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'almacen debe ser un texto.' })
    @IsNotEmpty({ message: 'almacen es obligatorio.' })
    @MinLength(1, { message: 'almacen debe tener al menos 1 carácter.' })
    @MaxLength(200, { message: 'almacen no puede exceder los 200 caracteres.' })
    @IsSafeText()
    almacen: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'codigo debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo es obligatorio.' })
    @MinLength(3, { message: 'codigo debe tener al menos 3 caracteres.' })
    @MaxLength(60, { message: 'codigo no puede exceder los 60 caracteres.' })
    @Matches(/^[A-Z0-9_-]+$/, { message: 'codigo debe contener solo letras mayúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    codigo: string;

    @IsInt({ message: 'tipo_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoAlmacen), {
        message: createEnumMessage(TIPO_ALMACEN_METADATA, getEnumValues(TipoAlmacen), 'tipo_almacen_id')
    })
    tipo_almacen_id: number;

    @IsInt({ message: 'tipo_operacion_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoOperacionAlmacen), {
        message: createEnumMessage(TIPO_OPERACION_ALMACEN_METADATA, getEnumValues(TipoOperacionAlmacen), 'tipo_operacion_almacen_id')
    })
    tipo_operacion_almacen_id: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(500, { message: 'descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}

// C:\sirena\sirena-backend\src\modules\almacenes\dto\update-almacen.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateAlmacenDto } from './create-almacen.dto';

export class UpdateAlmacenDto extends PartialType(CreateAlmacenDto) {}

// C:\sirena\sirena-backend\src\modules\almacenes\entities\almacen.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'almacenes' })
@Check('chk_almacenes_tipoalmacenid', `
    tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)
    AND (
        (tipo_operacion_almacen_id = 4050 AND tipo_almacen_id IN (1704, 1709, 1710, 1711, 1712))
        OR
        (tipo_operacion_almacen_id = 4051 AND tipo_almacen_id IN (1700, 1701, 1702, 1703, 1705, 1706, 1707, 1708))
    )
`)
@Check('chk_almacenes_tipooperacionalmacenid', 'tipo_operacion_almacen_id IN (4050, 4051)')
@Check('chk_almacenes_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_almacenes_almacen_notempty', "TRIM(almacen) <> ''")
@Check('chk_almacenes_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_almacenes_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_almacenes_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_almacenes_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Index('uix_almacenes_sucursalid_almacenid_unique', ['sucursal_id', 'almacen_id'], { unique: true })
@Index('uix_almacenes_sucursalid_almacen_unique', ['sucursal_id', 'almacen'], { unique: true, where: "estado_id IN (1000, 1002)" })
@Index('uix_almacenes_sucursalid_codigo_unique', ['sucursal_id', 'codigo'], { unique: true, where: "estado_id IN (1000, 1002)" })
export class Almacen extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'almacen_id', type: 'bigint' })
    almacen_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'almacen', type: 'varchar', length: 200, nullable: false })
    almacen!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'tipo_almacen_id', type: 'smallint', nullable: false, default: 1700 })
    tipo_almacen_id!: number;

    @Column({ name: 'tipo_operacion_almacen_id', type: 'smallint', nullable: false, default: 4050 })
    tipo_operacion_almacen_id!: number;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string | null;
}

// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA, TIPOS_ALMACEN_VENTA_DIRECTA, TIPOS_ALMACEN_LOGISTICA_INTERNA, TIPO_ALMACEN_METADATA, TipoAlmacen } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateAlmacenDto } from './dto/create-almacen.dto';
import { AlmacenResponseDto } from './dto/almacen-response.dto';
import { FindAlmacenesQueryDto } from './dto/find-almacenes-query.dto';
import { UpdateAlmacenDto } from './dto/update-almacen.dto';
import { Almacen } from './entities/almacen.entity';

@Injectable()
export class AlmacenesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'almacenes',
        nombreEntidad: 'Almacen',
        campoPK: 'almacen_id',
        alias: 't',
        responseDto: AlmacenResponseDto,
        camposBusquedaEnQ: FindAlmacenesQueryDto.getCamposParaQ(),
        tablasDependientes: FindAlmacenesQueryDto.getDependencias(),
        joins: [
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = t.sucursal_id',
                selectColumns: [
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'sucursal_id',
                nombreColumna: 'sucursal_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_almacen_id',
                nombreColumna: 'tipo_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_operacion_almacen_id',
                nombreColumna: 'tipo_operacion_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'almacen_id',
            camposPermitidosParaOrdenar: FindAlmacenesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindAlmacenesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    private validarCombinacionTipoAlmacen(
        tipoOperacionId: number,
        tipoAlmacenId: number
    ): void {
        const combinacionesValidas: Record<number, number[]> = {
            [TipoOperacionAlmacen.LOGISTICA_INTERNA]: [
                ...TIPOS_ALMACEN_LOGISTICA_INTERNA
            ],
            [TipoOperacionAlmacen.VENTA_DIRECTA]: [
                ...TIPOS_ALMACEN_VENTA_DIRECTA
            ],
        };

        const tiposPermitidos = combinacionesValidas[tipoOperacionId];
        if (!tiposPermitidos) {
            const operacionesValidas = Object.keys(combinacionesValidas)
                .map(id => {
                    const meta = TIPO_OPERACION_ALMACEN_METADATA[Number(id) as TipoOperacionAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');
            throw new DomainException(
                `tipo_operacion_almacen_id "${tipoOperacionId}" no es válido. ` +
                `Valores permitidos: ${operacionesValidas}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (!tiposPermitidos.includes(tipoAlmacenId)) {
            const operacionMeta = TIPO_OPERACION_ALMACEN_METADATA[tipoOperacionId as TipoOperacionAlmacen];
            const operacionNombre = operacionMeta?.abreviatura ?? 'DESCONOCIDO';

            const tiposPermitidosStr = tiposPermitidos
                .map(id => {
                    const meta = TIPO_ALMACEN_METADATA[id as TipoAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');

            throw new DomainException(
                `Combinación inválida: tipo_operacion_almacen_id "${tipoOperacionId}" (${operacionNombre}) ` +
                `no permite tipo_almacen_id "${tipoAlmacenId}". ` +
                `Tipos permitidos: ${tiposPermitidosStr}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'almacen', valor: dto.almacen },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'codigo', valor: dto.codigo },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                })
            ]);

            this.validarCombinacionTipoAlmacen(
                dto.tipo_operacion_almacen_id,
                dto.tipo_almacen_id
            );

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    almacen,
                    codigo,
                    tipo_almacen_id,
                    tipo_operacion_almacen_id,
                    descripcion,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.almacen,
                dto.codigo,
                dto.tipo_almacen_id,
                dto.tipo_operacion_almacen_id,
                dto.descripcion || null,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];

            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] ?? 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al insertar el almacén.',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const almacenActual = await manager.findOne(Almacen, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!almacenActual) {
                throw new DomainException(
                    `Almacén no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindAlmacenesQueryDto.getDependencias(),
                FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id)
                );
            }

            if (
                (dto.almacen !== undefined && dto.almacen !== almacenActual.almacen) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen', valor: dto.almacen ?? almacenActual.almacen },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (
                (dto.codigo !== undefined && dto.codigo !== almacenActual.codigo) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'codigo', valor: dto.codigo ?? almacenActual.codigo },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            const operacionId = dto.tipo_operacion_almacen_id ?? almacenActual.tipo_operacion_almacen_id;
            const tipoId = dto.tipo_almacen_id ?? almacenActual.tipo_almacen_id;

            if (dto.tipo_operacion_almacen_id !== undefined || dto.tipo_almacen_id !== undefined) {
                this.validarCombinacionTipoAlmacen(operacionId, tipoId);
            }

            Object.assign(almacenActual, dto);
            almacenActual.update(usuarioId);

            try {
                await manager.save(almacenActual);

                const updatedRecord = await manager.findOne(Almacen, {
                    where: { [this.campoPK]: id }
                });

                if (!updatedRecord) {
                    throw new DomainException('No se pudo recuperar el registro actualizado.', {
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    });
                }

                const responseDto = new AlmacenResponseDto();
                Object.assign(responseDto, updatedRecord);

                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}

esta bien se valida y se controla la unicidad 
