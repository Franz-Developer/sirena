**B. `[entidad-singular]-response.dto.ts`:**
- **Interfaz `[EntidadSingular]RawResult`:**
  - Debe reflejar los tipos de datos primitivos exactos devueltos por la consulta SQL pura (PostgreSQL/TypeORM Raw Query), considerando que los tipos `BIGINT`, `TIMESTAMPTZ` y agregados pueden llegar como `string`, `number`, `Date` o `null`.
  - Debe incluir los campos de la tabla principal, campos del sistema (`estado_registro`, `usuario_operacion`, `tiene_dependencias`, `campos_protegidos`) y las columnas seleccionadas de las tablas secundarias (JOINS).
- **Clase `[EntidadSingular]ResponseDto`:**
  - Aplica `@Expose()` en cada propiedad y `@Transform()` para transformaciones de datos.
  - **Regla de Selección de Campos:**
    - **Tabla Principal:** Incluye TODOS los campos propios de la entidad.
    - **Tablas Relacionadas (FKs / Tablas Dependientes):** Incluye SOLO las columnas informativas más representativas (ej: `rol`, `codigo` de `roles`; `suceso`, `codigo` de `sucesos`; contadores o permisos clave de `roles_permisos_tablas`). **NUNCA** incluyas la totalidad de los campos auditables ni metadatos secundarios de las tablas relacionales.
- **Transformadores OBLIGATORIOS:**
  - **Estados:** Helper `transformEstado` que extrae la abreviatura o descripción usando `ESTADO_METADATA` de `estados.constant.ts`.
  - **Fechas:** Transforma todas las columnas de fecha (`TIMESTAMPTZ` / `DATE`) aplicando `formatLocalDate`.
  - **Números / IDs:** Transforma los IDs de `BIGINT` (que llegan como string desde Postgres) a `number` donde corresponda.
  
  
  falta especificar 
  si la tabla tiene campos que son constantes y hace referencia al archivo estados.constant.ts 
  en [entidad-singular]-response.dto.ts debe haber algo asi 
  
  // C:\sirena\sirena-backend\src\modules\clientes\dto\cliente-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoCliente, TIPO_CLIENTE_METADATA, TipoDocumento, TIPO_DOCUMENTO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: ClienteRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoCliente = (tipoClienteId: unknown) => {
    const id = Number(tipoClienteId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_CLIENTE_METADATA[id as TipoCliente];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

const transformTipoDocumento = (tipoDocumentoId: unknown) => {
    const id = Number(tipoDocumentoId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_DOCUMENTO_METADATA[id as TipoDocumento];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface ClienteRawResult {
    cliente_id: string | number;
    tipo_cliente_id: string | number;
    cliente: string;
    nit?: string | null;
    razon_social?: string | null;
    documento: string;
    documento_complemento?: string | null;
    tipo_documento_id: string | number;
    direccion?: string | null;
    telefono?: string | null;
    email?: string | null;
    banco_base_id: string | number;
    banco_base_nombre?: string | null;
    banco_base_abreviatura?: string | null;
    numero_cuenta?: string | null;
    habilitado_ventas: string | number;
    limite_credito: string | number;
    estado_id: string | number;
    estado_registro: string;
    usuario_operacion: string;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number | null;
    usuario_id_baja?: string | number | null;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date | null;
    fecha_baja?: string | Date | null;
    total_count?: string | number;
    tiene_dependencias?: boolean;
    campos_protegidos?: string[];
}

export class ClienteResponseDto {
    @Expose() cliente_id!: number;
    @Expose() tipo_cliente_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoCliente(obj.tipo_cliente_id))
    tipo_cliente!: {
        abreviatura: string;
        descripcion: string;
    };

    @Expose() cliente!: string;
    @Expose() nit?: string | null;
    @Expose() razon_social?: string | null;
    @Expose() documento!: string;
    @Expose() documento_complemento?: string | null;

    @Expose() tipo_documento_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoDocumento(obj.tipo_documento_id))
    tipo_documento!: {
        abreviatura: string;
        prefijo: string;
    };

    @Expose() direccion?: string | null;
    @Expose() telefono?: string | null;
    @Expose() email?: string | null;
    @Expose() banco_base_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.banco_base_nombre || null)
    banco_base_nombre?: string | null;

    @Expose()
    @Transform(({ obj }) => obj.banco_base_abreviatura || null)
    banco_base_abreviatura?: string | null;

    @Expose() numero_cuenta?: string | null;

    @Expose()
    @Transform(({ value }) => Number(value))
    habilitado_ventas!: number;

    @Expose()
    @Transform(({ value }) => Number(value))
    limite_credito!: number;

    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose() usuario_operacion!: string;
    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number | null;
    @Expose() usuario_id_baja?: number | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose() tiene_dependencias!: boolean;
    @Expose() campos_protegidos?: string[];
}

CREATE TABLE clientes (
    cliente_id BIGSERIAL PRIMARY KEY,
    tipo_cliente_id SMALLINT NOT NULL DEFAULT 1150,     -- 1150=NATURAL, 1151=JURIDICA
    cliente VARCHAR(100) NOT NULL,
    nit VARCHAR(20) NULL,
	razon_social VARCHAR(150) NULL,
    documento VARCHAR(30) NOT NULL,
    documento_complemento VARCHAR(10) NULL,
    tipo_documento_id SMALLINT NOT NULL DEFAULT 2200,   -- 2200=CEDULA_IDENTIDAD, 2201=CEDULA_IDENTIDAD_EXTRANJERO, 2202=PASAPORTE, 2203=OTRO, 2204=NIT
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    banco_base_id BIGINT NOT NULL DEFAULT 1,
    numero_cuenta VARCHAR(50) NULL,
    habilitado_ventas SMALLINT NOT NULL DEFAULT 1,
    limite_credito DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_clientes_banco_base_id FOREIGN KEY (banco_base_id) REFERENCES bancos(banco_id),
    CONSTRAINT chk_clientes_tipoclienteid CHECK (tipo_cliente_id IN (1150, 1151)),
    CONSTRAINT chk_clientes_tipodocumentoid CHECK (tipo_documento_id IN (2200, 2201, 2202, 2203, 2204)),
    CONSTRAINT chk_clientes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_clientes_cliente_notempty CHECK (TRIM(cliente) <> ''),
    CONSTRAINT chk_clientes_cliente_minlength CHECK (LENGTH(TRIM(cliente)) >= 3),
    CONSTRAINT chk_clientes_nit_notempty CHECK (nit IS NULL OR TRIM(nit) <> ''),
    CONSTRAINT chk_clientes_razonsocial_notempty CHECK (razon_social IS NULL OR TRIM(razon_social) <> ''),
    CONSTRAINT chk_clientes_documento_notempty CHECK (TRIM(documento) <> ''),
    CONSTRAINT chk_clientes_documento_minlength CHECK (LENGTH(TRIM(documento)) >= 1),
    CONSTRAINT chk_clientes_documentocomplemento_notempty CHECK (documento_complemento IS NULL OR TRIM(documento_complemento) <> ''),
    CONSTRAINT chk_clientes_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_clientes_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_clientes_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_clientes_numerocuenta_notempty CHECK (numero_cuenta IS NULL OR TRIM(numero_cuenta) <> ''),
    CONSTRAINT chk_clientes_habilitadoventas CHECK (habilitado_ventas IN (0, 1)),
    CONSTRAINT chk_clientes_limitecredito CHECK (limite_credito >= 0.00),
    CONSTRAINT chk_clientes_coherencia CHECK (
        (limite_credito = 0.00) OR
        (limite_credito > 0.00 AND habilitado_ventas = 1)
    )
);
CREATE UNIQUE INDEX uix_clientes_tipodocumentoid_documento_unique ON clientes (tipo_documento_id, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NULL;
CREATE UNIQUE INDEX uix_clientes_varios_unique ON clientes (tipo_documento_id, documento_complemento, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NOT NULL;
CREATE INDEX idx_clientes_documento_cliente_busqueda ON clientes (documento, cliente) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_clientes_bancoid ON clientes (banco_base_id);
  
  
  
  