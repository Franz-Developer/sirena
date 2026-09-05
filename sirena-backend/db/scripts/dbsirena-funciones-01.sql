-- ================================================================================================
-- Funciones

/**
 * @function fn_validar_reglas_negocio
 * @description Valida TODAS las reglas de negocio del sistema en un solo lugar
 *
 * ?? CONTEXTOS SOPORTADOS:
 *   - 'KARDEX': Validación de cabecera de transacción
 *   - 'KARDEX_PRODUCTO': Validación de detalle de transacción
 *   - 'DOMINIO': Validación de dominios protegidos
 *
 * ?? REGLAS DE NEGOCIO APLICADAS:
 *   - R.1: Registro Inicial Comodín (ID=1) no modificable
 *   - R.2: Control de Estados (ACTIVO, BORRADO, HISTORICO, ANULADO)
 *   - R.8: Ventas al contado (estado_financiero_id = 2400)
 *   - R.9: Crédito a proveedores (estado_financiero_id 2400-2402)
 *   - R.14: Matriz de integridad de entidades por evento
 *   - R.16: Validación de estado de traspaso (OBS. 04)
 *   - R.17: Validación de estado de pedido
 *   - R.18: Validación de tipo de despacho
 *   - R.19: Validación de devoluciones (OBS. 11)
 *   - R.G.6: Dominios protegidos (es_protegido = 1)
 *
 * ================================================================================================
 *
 * @param {VARCHAR} p_contexto - Contexto de validación
 *   - 'KARDEX': Validación de cabecera de transacción
 *   - 'KARDEX_PRODUCTO': Validación de detalle de transacción
 *   - 'DOMINIO': Validación de dominios protegidos
 *
 * @param {INTEGER} p_evento_id - ID del evento (dominio EventoID 1050-1070)
 *   - 1050: COMPRA
 *   - 1051: VENTA
 *   - 1052: PROFORMA
 *   - 1053: EGRESO_TRASPASO
 *   - 1054: INGRESO_TRASPASO
 *   - 1055: ANULACION
 *   - 1056: AJUSTE_INGRESO
 *   - 1057: AJUSTE_EGRESO
 *   - 1058: SOLICITUD_COMPRA
 *   - 1059: VENTA_RESERVA
 *   - 1060: DEVOLUCION_CLIENTE ?? (requiere lote real > 1, tipo_pago_id = 1406)
 *   - 1061: DEVOLUCION_PROVEEDOR ?? (requiere lote real > 1)
 *   - 1062: ROBO
 *   - 1063: PERDIDA_CADUCIDAD
 *   - 1064: MERMA_ROTURA
 *   - 1065: INVENTARIO_FISICO_SOBRANTE
 *   - 1066: INVENTARIO_FISICO_FALTANTE
 *   - 1067: CONVERSION_UNIDADES ?? (requiere cantidad > 0 Y cantidad_salida > 0)
 *   - 1068: RETIRO_CUARENTENA ?? (evento de ajuste)
 *
 * @param {BIGINT} p_cliente_id - ID del cliente (tabla clientes)
 *   - 1: Cliente comodín (anónimo / sin identificar)
 *   - >1: Cliente registrado
 *
 * @param {BIGINT} p_proveedor_id - ID del proveedor (tabla proveedores)
 *   - 1: Proveedor comodín
 *   - >1: Proveedor registrado
 *
 * @param {INTEGER} p_estado_financiero_id - Estado financiero (dominio 2400-2404)
 *   - 2400: CANCELADO (transacción completamente pagada)
 *   - 2401: PENDIENTE (sin abonos registrados)
 *   - 2402: PARCIAL (con abonos parciales)
 *   - 2403: NINGUNO (sin estado financiero definido)
 *   - 2404: DEVOLUCION_GENERADA ? NUEVO (OBS. 14)
 *
 * @param {DECIMAL(12,2)} p_total_venta - Total de venta sin factura (precio base)
 * @param {DECIMAL(12,2)} p_total_venta_factura - Total de venta con factura (con IVA)
 *
 * @param {INTEGER} p_estado_id - Estado del registro (dominio EstadoID 1000-1003)
 *   - 1000: ACTIVO (registro operativo y vigente)
 *   - 1001: BORRADO (baja lógica definitiva)
 *   - 1002: HISTORICO (registro archivado e inmutable)
 *   - 1003: ANULADO (transacción cancelada e irreversible)
 *
 * @param {BIGINT} p_kardex_origen_id - ID del origen (para traspasos - OBS. 03)
 *   - Obligatorio para INGRESO_TRASPASO (1054)
 *   - Debe ser NULL para EGRESO_TRASPASO (1053)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_referencia_id - ID de la transacción original (para devoluciones)
 *   - Obligatorio para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_sucursal_id - ID de la sucursal origen
 * @param {BIGINT} p_sucursal_destino_id - ID de la sucursal destino
 *   - Obligatorio para traspasos (1053, 1054)
 *   - Debe ser diferente a sucursal_id
 *
 * @param {INTEGER} p_estado_traspaso_id - Estado del traspaso (dominio 2100-2103 - OBS. 04)
 *   - 2100: EN_TRANSITO (estado inicial para INGRESO_TRASPASO - OBS. 13)
 *   - 2101: RECIBIDO
 *   - 2102: RECHAZADO
 *   - 2103: NO_APLICA (para eventos que no son traspasos)
 *
 * @param {BIGINT} p_kardex_pedido_compra_id - ID del pedido de compra (OBS. 14)
 *   - Obligatorio para SOLICITUD_COMPRA (1058)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_id - ID de la cabecera (tabla kardex)
 *   - Obligatorio para contexto 'KARDEX_PRODUCTO'
 *
 * @param {DECIMAL(12,2)} p_cantidad - Cantidad de entrada
 *   - Debe ser > 0 para eventos de ingreso (1050, 1054, 1056, 1060, 1065, 1069)
 *   - Debe ser = 0 para eventos de egreso (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
 *   - Debe ser > 0 para CONVERSION_UNIDADES (1067)
 *
 * @param {DECIMAL(12,2)} p_cantidad_salida - Cantidad de salida
 *   - Debe ser = 0 para eventos de ingreso
 *   - Debe ser > 0 para eventos de egreso (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
 *   - Debe ser > 0 para CONVERSION_UNIDADES (1067)
 *
 * @param {DECIMAL(12,2)} p_pcompra - Precio de compra unitario
 *   - Debe ser > 0 para COMPRA (1050)
 *   - Debe ser = 0 para ajustes y traspasos
 *
 * @param {DECIMAL(12,2)} p_precio_venta - Precio de venta sin factura
 *   - Debe ser > 0 para VENTA (1051) y VENTA_RESERVA (1059)
 *   - Debe ser = 0 para compras, ajustes y traspasos
 *
 * @param {DECIMAL(12,2)} p_precio_venta_factura - Precio de venta con factura (con IVA)
 *   - Debe ser > 0 para VENTA (1051) y VENTA_RESERVA (1059)
 *   - Debe ser = 0 para compras, ajustes y traspasos
 *
 * @param {BIGINT} p_tipo_pago_id - Tipo de pago (dominio 1400-1409 - OBS. 06)
 *   - 1400: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1401-1409: Tipos definidos solo para VENTA (1051)
 *   - 1406: SIN_PAGO (obligatorio para DEVOLUCION_CLIENTE - OBS. 05)
 *
 * @param {INTEGER} p_tipo_venta_id - Tipo de venta (dominio 1350-1352 - OBS. 07)
 *   - 1350: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1351: CON_FACTURA (solo para VENTA)
 *   - 1352: SIN_FACTURA (solo para VENTA)
 *
 * @param {BIGINT} p_lote_id - ID del lote afectado (tabla lotes_productos - OBS. 01)
 *   - Debe ser > 1 para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser el mismo que el origen para INGRESO_TRASPASO (1054 - OBS. 09)
 *   - Puede ser 1 (comodín) para otros eventos
 *
 * @param {DECIMAL(12,2)} p_costo_venta - Costo de venta (OBS. 16)
 *   - Debe ser 0 para INGRESO_TRASPASO (1054)
 *   - Debe ser > 0 para VENTA (1051)
 *   - Debe ser = costo_venta de la venta original para DEVOLUCION_CLIENTE (OBS. 16)
 *
 * @param {BIGINT} p_sucursal_detalle_id - ID de la sucursal en detalle (OBS. 10)
 *   - Debe coincidir con sucursal_id para EGRESO_TRASPASO (1053)
 *   - Debe coincidir con sucursal_destino_id para INGRESO_TRASPASO (1054)
 *
 * @param {DECIMAL(12,2)} p_descuento - Descuento aplicado (OBS. 10)
 *   - Solo permitido para VENTA (1051)
 *   - Debe ser 0 para ajustes, traspasos y otros eventos
 *   - Debe ser 0 para DEVOLUCION_CLIENTE (OBS. 06)
 *
 * @param {INTEGER} p_motivo_anulacion_id - Motivo de anulación (dominio 2450-2455 - OBS. 13)
 *   - 2450-2454: Motivos permitidos solo para ANULACION (1055)
 *   - 2455: NINGUNO para otros eventos
 *   - Debe ser 2455 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 09)
 *
 * @param {INTEGER} p_motivo_devolucion_id - Motivo de devolución (dominio 3500-3508 - OBS. 12)
 *   - 3500: PRODUCTO_VENCIDO
 *   - 3501: PRODUCTO_DAÑADO
 *   - 3502: ERROR_PEDIDO
 *   - 3503: EXCESO_STOCK
 *   - 3504: DESCONTINUADO
 *   - 3505: DEVOLUCION_CLIENTE
 *   - 3506: NINGUNO (para ajustes y otros eventos)
 *   - 3507: PRODUCTO_NO_SOLICITADO ? NUEVO
 *   - 3508: PRODUCTO_DEFECTUOSO ? NUEVO
 *   - Debe ser distinto de 3506 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {VARCHAR} p_comprobante_referencia - Comprobante de referencia (OBS. 11)
 *   - Obligatorio para DEVOLUCION_CLIENTE
 *   - Debe ser NULL para otros eventos
 *
 * @param {DECIMAL(12,2)} p_total_compra - Total de compra
 *   - Debe ser > 0 para COMPRA (1050)
 *   - Debe ser >= 0 para DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {BIGINT} p_dominio_id - ID del dominio a validar (tabla dominios)
 *   - Obligatorio para contexto 'DOMINIO'
 *   - Verifica que es_protegido != 1 (R.G.6)
 *
 * @returns {VOID} - No retorna valor
 *
 * @throws {EXCEPTION} Con mensajes descriptivos en los siguientes casos:
 *   - Evento no válido para el contexto
 *   - Cantidades inconsistentes con el tipo de evento (OBS. 05)
 *   - Precios incorrectos para el tipo de evento (OBS. 11)
 *   - Tipos de pago/venta no permitidos (OBS. 06, 07)
 *   - Descuento no permitido para ajustes (OBS. 10)
 *   - Descuento no permitido para DEVOLUCION_CLIENTE (OBS. 06)
 *   - Motivos de anulación/devolución no permitidos (OBS. 12, 13)
 *   - Lote comodín usado en devoluciones (OBS. 01)
 *   - Lote incorrecto en traspasos (OBS. 09)
 *   - Sucursal incorrecta en traspasos (OBS. 10)
 *   - costo_venta incorrecto en traspasos (OBS. 16)
 *   - Estado de traspaso incorrecto (OBS. 04, 13)
 *   - kardex_pedido_compra_id incorrecto (OBS. 14)
 *   - kardex_referencia_id obligatorio en devoluciones (OBS. 11)
 *   - comprobante_referencia obligatorio en DEVOLUCION_CLIENTE (OBS. 11)
 *   - Dominio protegido (es_protegido = 1 - R.G.6)
 *   - Contexto desconocido
 *
 * @since 4.3
 * @see kardex, kardex_productos, dominios
 * @see Reglas de Negocio R.1 a R.21 en la documentación
 *
 */

CREATE FUNCTION fn_validar_reglas_negocio(
    -- Contexto
    p_contexto VARCHAR,

    -- Parámetros para KARDEX (Cabecera)
    p_evento_id INTEGER DEFAULT NULL,
    p_cliente_id BIGINT DEFAULT NULL,
    p_proveedor_id BIGINT DEFAULT NULL,
    p_estado_financiero_id INTEGER DEFAULT NULL,
    p_total_venta DECIMAL(12,2) DEFAULT NULL,
    p_total_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_estado_id INTEGER DEFAULT NULL,

    -- Parámetros para TRASPASOS
    p_kardex_origen_id BIGINT DEFAULT NULL,
    p_sucursal_id BIGINT DEFAULT NULL,
    p_sucursal_destino_id BIGINT DEFAULT NULL,
    p_estado_traspaso_id INTEGER DEFAULT NULL,
    p_kardex_pedido_compra_id BIGINT DEFAULT NULL,
    p_kardex_referencia_id BIGINT DEFAULT NULL,
    p_comprobante_referencia VARCHAR DEFAULT NULL,
    p_total_compra DECIMAL(12,2) DEFAULT NULL,

    -- Parámetros para KARDEX_PRODUCTO (Detalle)
    p_kardex_id BIGINT DEFAULT NULL,
    p_cantidad DECIMAL(12,2) DEFAULT NULL,
    p_cantidad_salida DECIMAL(12,2) DEFAULT NULL,
    p_pcompra DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_tipo_pago_id BIGINT DEFAULT NULL,
    p_tipo_venta_id INTEGER DEFAULT NULL,
    p_lote_id BIGINT DEFAULT NULL,
    p_costo_venta DECIMAL(12,2) DEFAULT NULL,
    p_sucursal_detalle_id BIGINT DEFAULT NULL,

    -- Parámetros adicionales
    p_descuento DECIMAL(12,2) DEFAULT NULL,
    p_motivo_anulacion_id INTEGER DEFAULT NULL,
    p_motivo_devolucion_id INTEGER DEFAULT NULL,

    -- Parámetros para DOMINIO
    p_dominio_id BIGINT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_evento_id INTEGER;
    v_es_protegido INTEGER;
    v_estado_actual INTEGER;
    v_origen_evento_id INTEGER;
    v_origen_estado_id INTEGER;
    v_origen_sucursal_id BIGINT;
    v_origen_lote_id BIGINT;
    v_origen_costo_venta DECIMAL(12,2);
    v_referencia_tipo INTEGER;
    v_monto_devolucion DECIMAL(12,2);
BEGIN
    ------------------------------------------------------------------
    -- CONTEXTO 1: VALIDACIÓN PARA KARDEX (CABECERA)
    ------------------------------------------------------------------
    IF p_contexto = 'KARDEX' THEN

        -- ============================================================
        -- 1.1: VALIDACIÓN DE EVENTOS DE AJUSTE
        -- ============================================================
        IF p_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_total_venta <> 0 OR p_total_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere total_venta = 0 y total_venta_factura = 0', p_evento_id;
            END IF;
            IF p_cliente_id <> 1 OR p_proveedor_id <> 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere cliente_id = 1 y proveedor_id = 1', p_evento_id;
            END IF;
            IF p_motivo_devolucion_id IS NOT NULL AND p_motivo_devolucion_id <> 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_devolucion_id', p_evento_id;
            END IF;
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id <> 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_anulacion_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 1.2: VENTA debe ser CANCELADO
        -- ============================================================
        IF p_evento_id = 1051 AND p_estado_financiero_id <> 2400 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: VENTA (1051) requiere estado_financiero_id = 2400 (CANCELADO)';
        END IF;

        -- ============================================================
        -- 1.3: COMPRA puede tener cualquier estado financiero
        -- ============================================================
        IF p_evento_id = 1050 AND p_estado_financiero_id NOT IN (2400, 2401, 2402) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: COMPRA (1050) requiere estado_financiero_id en (2400, 2401, 2402)';
        END IF;

        -- ============================================================
        -- 1.4: OTROS EVENTOS deben tener estado_financiero_id = 2403
        -- ============================================================
        IF p_evento_id NOT IN (1050, 1051) AND p_estado_financiero_id <> 2403 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere estado_financiero_id = 2403 (NINGUNO)', p_evento_id;
        END IF;

        -- ============================================================
        -- 1.5: VALIDACIÓN DE ESTADOS
        -- ============================================================
        IF p_estado_id IS NOT NULL AND p_estado_id NOT IN (1000, 1001, 1002, 1003) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Estado % no válido', p_estado_id;
        END IF;

        -- ============================================================
        -- ? 1.6: VALIDACIÓN DE ESTADO_TRASPASO_ID (OBS. 04)
        -- ============================================================
        IF p_evento_id IN (1053, 1054) THEN
            IF p_estado_traspaso_id IS NULL OR p_estado_traspaso_id NOT IN (2100, 2101, 2102) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso % requiere estado_traspaso_id en (2100, 2101, 2102)', p_evento_id;
            END IF;
        ELSE
            IF p_estado_traspaso_id IS NOT NULL AND p_estado_traspaso_id != 2103 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % debe tener estado_traspaso_id = 2103 (NO_APLICA)', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- ? 1.7: VALIDACIÓN DE KARDEX_PEDIDO_COMPRA_ID (OBS. 14)
        -- ============================================================
        IF p_evento_id = 1058 THEN
            IF p_kardex_pedido_compra_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: SOLICITUD_COMPRA (1058) requiere kardex_pedido_compra_id no nulo';
            END IF;
            -- Validar que el pedido exista y sea una solicitud de compra
            IF NOT EXISTS (
                SELECT 1 FROM kardex
                WHERE kardex_id = p_kardex_pedido_compra_id
                AND evento_id = 1058
                AND estado_id = 1000
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_pedido_compra_id % debe ser una SOLICITUD_COMPRA (1058) activa',
                    p_kardex_pedido_compra_id;
            END IF;
        ELSE
            IF p_kardex_pedido_compra_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_pedido_compra_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- ? 1.8: VALIDACIÓN DE TRASPASOS (OBS. 03 y 13)
        -- ============================================================

        -- Solo traspasos pueden tener origen y sucursal_destino
        IF p_evento_id NOT IN (1053, 1054) THEN
            IF p_kardex_origen_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_origen_id', p_evento_id;
            END IF;
            IF p_sucursal_destino_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener sucursal_destino_id', p_evento_id;
            END IF;
        END IF;

        -- Traspasos requieren sucursal_destino_id diferente
        IF p_evento_id IN (1053, 1054) THEN
            IF p_sucursal_destino_id IS NULL OR p_sucursal_destino_id = p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso requiere sucursal_destino_id diferente a sucursal_id';
            END IF;
            IF NOT EXISTS (SELECT 1 FROM sucursales WHERE sucursal_id = p_sucursal_destino_id AND estado_id = 1000) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal destino % no existe o no está ACTIVA', p_sucursal_destino_id;
            END IF;
        END IF;

        -- ? INGRESO_TRASPASO (1054) - OBS. 13: Debe empezar en EN_TRANSITO (2100)
        IF p_evento_id = 1054 THEN
            -- Validar que el estado sea EN_TRANSITO al crear
            IF p_estado_traspaso_id != 2100 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) debe crearse con estado_traspaso_id = 2100 (EN_TRANSITO)';
            END IF;

            -- Validar origen
            IF p_kardex_origen_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) requiere kardex_origen_id no nulo';
            END IF;

            SELECT evento_id, estado_id, sucursal_id
            INTO v_origen_evento_id, v_origen_estado_id, v_origen_sucursal_id
            FROM kardex
            WHERE kardex_id = p_kardex_origen_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % no existe', p_kardex_origen_id;
            END IF;

            IF v_origen_evento_id != 1053 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % debe ser EGRESO_TRASPASO (1053). Es %',
                    p_kardex_origen_id, v_origen_evento_id;
            END IF;

            IF v_origen_estado_id != 1000 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % debe estar ACTIVO (1000). Está %',
                    p_kardex_origen_id, v_origen_estado_id;
            END IF;

            IF v_origen_sucursal_id = p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal origen % no puede ser igual a destino %',
                    v_origen_sucursal_id, p_sucursal_destino_id;
            END IF;

            IF (
                SELECT 1 FROM kardex
                WHERE kardex_origen_id = p_kardex_origen_id
                AND evento_id = 1054
                AND estado_id != 1001
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % ya vinculado a otro INGRESO_TRASPASO',
                    p_kardex_origen_id;
            END IF;
        END IF;

        -- EGRESO_TRASPASO (1053) NO debe tener origen
        IF p_evento_id = 1053 AND p_kardex_origen_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO (1053) no debe tener kardex_origen_id';
        END IF;

        -- ============================================================
        -- ? 1.9: VALIDACIÓN DE DEVOLUCIONES (OBS. 11)
        -- ============================================================

        -- DEVOLUCION_CLIENTE (1060)
        IF p_evento_id = 1060 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una VENTA (1051)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1051 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una VENTA (1051). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar comprobante_referencia
            IF p_comprobante_referencia IS NULL OR TRIM(p_comprobante_referencia) = '' THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere comprobante_referencia no nulo';
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_venta < 0 OR p_total_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere totales >= 0';
            END IF;

            -- Validar tipo_pago_id (OBS. 05)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.5)

            -- Validar descuento (OBS. 06)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.4)

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;

            -- Validar estado_financiero_id (OBS. 14)
            IF p_estado_financiero_id IS NOT NULL AND p_estado_financiero_id != 2404 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere estado_financiero_id = 2404 (DEVOLUCION_GENERADA)';
            END IF;
        END IF;

        -- DEVOLUCION_PROVEEDOR (1061)
        IF p_evento_id = 1061 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una COMPRA (1050)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1050 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una COMPRA (1050). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_compra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere total_compra >= 0';
            END IF;

            -- Validar tipo_pago_id (OBS. 05)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.5)

            -- Validar descuento (OBS. 06)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.4)

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;

            -- Validar estado_financiero_id (OBS. 14)
            IF p_estado_financiero_id IS NOT NULL AND p_estado_financiero_id != 2404 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere estado_financiero_id = 2404 (DEVOLUCION_GENERADA)';
            END IF;
        END IF;

        -- OTROS EVENTOS: no deben tener kardex_referencia_id
        IF p_evento_id NOT IN (1060, 1061) AND p_kardex_referencia_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_referencia_id', p_evento_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO 2: VALIDACIÓN PARA KARDEX_PRODUCTOS (DETALLE)
    ------------------------------------------------------------------
    ELSIF p_contexto = 'KARDEX_PRODUCTO' THEN
        -- 2.1: Obtener el evento_id y estado_id de la cabecera
        SELECT evento_id, estado_id INTO v_evento_id, v_estado_actual
        FROM kardex
        WHERE kardex_id = p_kardex_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Cabecera con ID % no existe', p_kardex_id;
        END IF;

        -- 2.2: No permitir modificar ANULADAS
        IF v_estado_actual = 1003 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: No se puede modificar transacción ANULADA (estado_id = 1003)';
        END IF;

        -- ============================================================
        -- 2.3: ? VALIDACIÓN DE CANTIDADES POR EVENTO (OBS. 05)
        -- ============================================================

        -- INGRESO (1050, 1054, 1056, 1060, 1065, 1069)
        IF v_evento_id IN (1050, 1056, 1060, 1065, 1069) OR v_evento_id = 1054 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (INGRESO) requiere cantidad > 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- EGRESO (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
        ELSIF v_evento_id IN (1051, 1057, 1062, 1063, 1064, 1066, 1068) OR v_evento_id = 1053 OR v_evento_id = 1061 THEN
            -- 1061 (DEVOLUCION_PROVEEDOR) es egreso
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (EGRESO) requiere cantidad = 0 y cantidad_salida > 0', v_evento_id;
            END IF;

        -- PROFORMA (1052), SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id IN (1052, 1058) THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidad = 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA (1059) requiere cantidad = 0 y cantidad_salida > 0';
            END IF;

        -- MIXTOS (1055, 1061) - 1061 ya está en EGRESO
        ELSIF v_evento_id IN (1055) THEN
            IF p_cantidad < 0 OR p_cantidad_salida < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidades >= 0', v_evento_id;
            END IF;
            IF p_cantidad = 0 AND p_cantidad_salida = 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere al menos una cantidad > 0', v_evento_id;
            END IF;

        -- CONVERSION_UNIDADES (1067)
        ELSIF v_evento_id = 1067 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: CONVERSION_UNIDADES (1067) requiere cantidad > 0 y cantidad_salida > 0';
            END IF;

        -- Evento desconocido
        ELSE
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % no contemplado. Solo cantidades = 0', v_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.4: ? VALIDACIÓN DE PRECIOS POR EVENTO (OBS. 11)
        -- ============================================================

        -- COMPRA (1050)
        IF v_evento_id = 1050 THEN
            IF p_pcompra <= 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: COMPRA (1050) requiere pcompra > 0 y precios venta = 0';
            END IF;

        -- VENTA (1051)
        ELSIF v_evento_id = 1051 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere precios > 0';
            END IF;

        -- TRASPASOS (1053, 1054) - OBS. 11: precios deben ser 0
        ELSIF v_evento_id IN (1053, 1054) THEN
            IF p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % requiere precio_venta = 0 y precio_venta_factura = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % no permite descuentos', v_evento_id;
            END IF;

        -- AJUSTES INTERNOS
        ELSIF v_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % requiere TODOS los precios = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % no permite descuentos', v_evento_id;
            END IF;

        -- PROFORMA (1052)
        ELSIF v_evento_id = 1052 THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA (1052) requiere TODOS los precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA no permite descuentos';
            END IF;

        -- SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id = 1058 THEN
            IF p_pcompra < 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA requiere pcompra >= 0 y demás precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA no permite descuentos';
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere precios > 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA no permite descuentos';
            END IF;

        -- DEVOLUCION_CLIENTE (1060)
        ELSIF v_evento_id = 1060 THEN
            IF p_precio_venta < 0 OR p_precio_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE requiere precios >= 0';
            END IF;
            -- ? OBS. 06: Descuento debe ser 0
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE no permite descuentos. Debe ser 0.00';
            END IF;
            -- ? OBS. 05: tipo_pago_id debe ser 1406 (SIN_PAGO)
            -- Se valida en 2.5

        -- DEVOLUCION_PROVEEDOR (1061)
        ELSIF v_evento_id = 1061 THEN
            IF p_pcompra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR requiere pcompra >= 0';
            END IF;
            -- ? OBS. 06: Descuento debe ser 0
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR no permite descuentos. Debe ser 0.00';
            END IF;
            -- ? OBS. 05: tipo_pago_id debe ser 1400 (NINGUNO)
            -- Se valida en 2.5

        -- ANULACION (1055)
        ELSIF v_evento_id = 1055 THEN
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: ANULACION no permite descuentos';
            END IF;
        END IF;

        -- ============================================================
        -- 2.5: ? VALIDACIÓN DE TIPOS DE PAGO Y VENTA (OBS. 06 y 07)
        -- ============================================================

        -- Eventos NEUTRALES (incluye traspasos)
        IF v_evento_id IN (1052, 1053, 1054, 1055, 1056, 1057, 1058, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_pago_id = 1400', v_evento_id;
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_venta_id = 1350', v_evento_id;
            END IF;
        END IF;

        -- VENTA (1051): tipos definidos
        IF v_evento_id = 1051 THEN
            IF p_tipo_pago_id = 1400 OR p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere tipo_pago_id != 1400 y tipo_venta_id != 1350';
            END IF;
        END IF;

        -- VENTA_RESERVA (1059)
        IF v_evento_id = 1059 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_pago_id = 1400';
            END IF;
            IF p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_venta_id != 1350';
            END IF;
        END IF;

        -- ? DEVOLUCION_CLIENTE (1060) - OBS. 05
        IF v_evento_id = 1060 THEN
            IF p_tipo_pago_id <> 1406 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_pago_id = 1406 (SIN_PAGO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- ? DEVOLUCION_PROVEEDOR (1061) - OBS. 05
        IF v_evento_id = 1061 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_pago_id = 1400 (NINGUNO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- ============================================================
        -- ? 2.6: VALIDACIÓN DE SUCURSAL_ID EN DETALLE (OBS. 10)
        -- ============================================================
        IF v_evento_id = 1053 THEN
            -- EGRESO_TRASPASO: sucursal del detalle debe ser la sucursal origen
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: EGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_id origen (%)',
                    p_sucursal_id;
            END IF;
        END IF;

        IF v_evento_id = 1054 THEN
            -- INGRESO_TRASPASO: sucursal del detalle debe ser la sucursal destino
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_destino_id (%)',
                    p_sucursal_destino_id;
            END IF;
        END IF;

        -- ============================================================
        -- ? 2.7: VALIDACIÓN DE LOTE_ID (OBS. 09)
        -- ============================================================
        IF v_evento_id = 1054 AND p_kardex_origen_id IS NOT NULL THEN
            -- Obtener el lote del origen
            SELECT kp.lote_id INTO v_origen_lote_id
            FROM kardex_productos kp
            WHERE kp.kardex_id = p_kardex_origen_id
            LIMIT 1;

            IF v_origen_lote_id IS NOT NULL AND p_lote_id IS NOT NULL AND v_origen_lote_id != p_lote_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO debe usar el mismo lote que el origen (%). Lote destino: %',
                    v_origen_lote_id, p_lote_id;
            END IF;
        END IF;

        -- ============================================================
        -- ? 2.8: VALIDACIÓN DE COSTO_VENTA (OBS. 16)
        -- ============================================================
        IF v_evento_id = 1054 THEN
            IF p_costo_venta IS NOT NULL AND p_costo_venta != 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO (1054) requiere costo_venta = 0. Recibido: %',
                    p_costo_venta;
            END IF;
        END IF;

        -- ============================================================
        -- ? 2.9: VALIDACIÓN DE LOTE_ID Y MOTIVO PARA DEVOLUCIONES (OBS. 01)
        -- ============================================================
        -- DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
        -- DEBEN usar un lote REAL (id > 1), NO el comodín (id = 1)
        -- Y DEBEN tener un motivo_devolucion_id válido (3500-3505, 3507, 3508)
        -- ============================================================
        IF v_evento_id IN (1060, 1061) THEN
            -- Validar que el lote no sea el comodín (1)
            IF p_lote_id IS NULL OR p_lote_id = 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devolución (%) requiere un lote real (lote_id > 1). No puede usar el lote comodín (1)',
                    v_evento_id;
            END IF;

            -- Validar que el lote exista y esté ACTIVO y VIGENTE
            IF NOT EXISTS (
                SELECT 1 FROM lotes_productos
                WHERE lote_id = p_lote_id
                AND estado_id = 1000
                AND estado_lote_id = 2500  -- VIGENTE
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: El lote % no existe, no está ACTIVO o no está VIGENTE',
                    p_lote_id;
            END IF;

            -- ? Validar motivo_devolucion_id para DEVOLUCIONES
            -- 3500: PRODUCTO_VENCIDO
            -- 3501: PRODUCTO_DAÑADO
            -- 3502: ERROR_PEDIDO
            -- 3503: EXCESO_STOCK
            -- 3504: DESCONTINUADO
            -- 3505: DEVOLUCION_CLIENTE
            -- 3507: PRODUCTO_NO_SOLICITADO ? NUEVO
            -- 3508: PRODUCTO_DEFECTUOSO ? NUEVO
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id NOT IN (3500, 3501, 3502, 3503, 3504, 3505, 3507, 3508) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devolución (%) requiere motivo_devolucion_id válido (3500-3505, 3507, 3508). Recibido: %',
                    v_evento_id, p_motivo_devolucion_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.10: ? VALIDACIÓN DE STOCK PARA VENTAS
        -- ============================================================
        -- NOTA: Se implementa en el backend para evitar dependencias cíclicas
        -- Verificar cantidad_salida <= cantidad_actual del lote

    ------------------------------------------------------------------
    -- CONTEXTO 3: VALIDACIÓN DE DOMINIOS PROTEGIDOS
    ------------------------------------------------------------------
    ELSIF p_contexto = 'DOMINIO' THEN
        SELECT es_protegido INTO v_es_protegido
        FROM dominios
        WHERE dominio_id = p_dominio_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % no existe', p_dominio_id;
        END IF;

        IF v_es_protegido = 1 THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % está protegido (es_protegido = 1)', p_dominio_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO DESCONOCIDO
    ------------------------------------------------------------------
    ELSE
        RAISE EXCEPTION 'Regla de Negocio: Contexto desconocido: %. Contextos válidos: KARDEX, KARDEX_PRODUCTO, DOMINIO', p_contexto;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_validar_coherencia_promocion
 * @description Valida las reglas de negocio y restricciones paramétricas para la creación
 *              y configuración de promociones y descuentos en el sistema de ventas/inventario.
 *              Asegura que los valores numéricos, porcentajes y cantidades requeridas/bonificadas
 *              sean consistentes según la modalidad del beneficio otorgado.
 *
 * @param {INTEGER} p_tipo_beneficio_id - Modalidad del beneficio (1501: PORCENTAJE, 1502: MONTO_FIJO, 1503: CANTIDAD/3x2, 1504: NINGUNO).
 * @param {INTEGER} p_cantidad_requerida - Cantidad mínima de unidades a comprar para activar la promoción.
 * @param {INTEGER} p_cantidad_beneficio - Cantidad de unidades bonificadas o regaladas otorgadas por la promoción.
 * @param {NUMERIC} p_valor_beneficio - Monto escalar o porcentaje del descuento aplicado.
 *
 * @returns {BOOLEAN} Retorna TRUE si todos los parámetros cumplen con las restricciones del tipo de beneficio.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `tipo_beneficio_id = 1503` (CANTIDAD) y `p_cantidad_requerida` o `p_cantidad_beneficio` son <= 0.
 * - Si `tipo_beneficio_id = 1501` (PORCENTAJE) y `p_valor_beneficio` es <= 0 o > 100.
 * - Si `tipo_beneficio_id = 1502` (MONTO_FIJO) y `p_valor_beneficio` es <= 0.
 * - Si `tipo_beneficio_id = 1504` (NINGUNO) y cualquiera de los parámetros de cantidad o valor es distinto de 0.
 *
 * @reglas_de_negocio
 * 1. Promoción por Cantidad / Combo (1503): Exige volúmenes de compra y regales estrictamente positivos (ej. compra X unidades, lleva Y).
 * 2. Promoción por Porcentaje (1501): Restringe el valor del descuento al rango contable válido entre `1.00%` y `100.00%`.
 * 3. Promoción por Monto Fijo (1502): Exige que la deducción monetaria directa sea estrictamente mayor a 0.
 * 4. Sin Promoción / Ninguno (1504): Blinda los campos obligando a resetear a 0 cualquier métrica de descuento/cantidad.
 *
 * @properties
 * IMMUTABLE: La función no realiza consultas a tablas y depende exclusivamente de sus argumentos de entrada.
 *
 * @example
 * -- Retorna TRUE (Descuento del 15%)
 * SELECT fn_validar_coherencia_promocion(1501, 0, 0, 15.00);
 *
 * -- Retorna TRUE (Promoción 3x2: requiere 3, beneficia 1)
 * SELECT fn_validar_coherencia_promocion(1503, 3, 1, 0.00);
 *
 * -- Dispara EXCEPTION (Porcentaje superior a 100)
 * SELECT fn_validar_coherencia_promocion(1501, 0, 0, 120.00);
 */
CREATE FUNCTION fn_liberar_reservas_expiradas()
RETURNS INTEGER AS $$
DECLARE
    v_reserva RECORD;
    v_nuevo_kardex_id BIGINT;
    v_contador INTEGER := 0;
BEGIN
    -- Recorrer todas las reservas/proformas pendientes cuya fecha de expiración ya se cumplió
    FOR v_reserva IN
        SELECT kardex_id, sucursal_id, cliente_id, proveedor_id, codigo
        FROM kardex
        WHERE evento_id = 1059 -- VENTA_RESERVA
          AND estado_proforma_id = 4001 -- PENDIENTE
          AND fecha_expiracion IS NOT NULL
          AND fecha_expiracion < CURRENT_TIMESTAMP
          AND estado_id = 1000
    LOOP
        -- A. Actualizar el estado de la reserva original a EXPIRADA (4003)
        UPDATE kardex
        SET estado_proforma_id = 4003,
            fecha_actualizacion = CURRENT_TIMESTAMP,
            usuario_id_actualizacion = 1 -- O sistema
        WHERE kardex_id = v_reserva.kardex_id;

        -- B. Generar un nuevo registro en el kardex con evento LIBERACION_RESERVA (1070)
        -- para devolver formalmente las cantidades al stock disponible.
        INSERT INTO kardex (
            tipo_comprobante_id, cliente_id, proveedor_id, sucursal_id,
            kardex_origen_id, evento_id, codigo, comprobante,
            fecha_kardex, estado_proforma_id, estado_id, usuario_id_registro
        ) VALUES (
            1103, v_reserva.cliente_id, v_reserva.proveedor_id, v_reserva.sucursal_id,
            v_reserva.kardex_id, 1070, 'LIB-' || v_reserva.codigo,
            'Liberación automática por expiración de TTL de la reserva: ' || v_reserva.codigo,
            CURRENT_TIMESTAMP, 4000, 1000, 1
        ) RETURNING kardex_id INTO v_nuevo_kardex_id;

        -- C. Copiar los detalles asociados desde kardex_productos invirtiendo o liberando el stock apartado
        INSERT INTO kardex_productos (
            kardex_id, producto_id, sucursal_id, lote_id, presentacion_id,
            tipo_pago_id, tipo_venta_id, cantidad, cantidad_unidad_base,
            cantidad_salida, pcompra, factor_venta, factor_facturacion,
            precio_venta, precio_venta_factura, costo_venta, descuento,
            estado_id, usuario_id_registro
        )
        SELECT
            v_nuevo_kardex_id, producto_id, sucursal_id, lote_id, presentacion_id,
            1400, 1350, cantidad, cantidad_unidad_base,
            0.00, -- Cantidad salida en 0 para reingresar/liberar el stock apartado
            pcompra, factor_venta, factor_facturacion,
            precio_venta, precio_venta_factura, costo_venta, descuento,
            1000, 1
        FROM kardex_productos
        WHERE kardex_id = v_reserva.kardex_id
          AND estado_id = 1000;

        v_contador := v_contador + 1;
    END LOOP;

    RETURN v_contador;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_validar_coherencia_promocion
 * @description Valida las reglas de negocio y restricciones paramétricas para la creación
 *              y configuración de promociones y descuentos en el sistema de ventas/inventario.
 *              Asegura que los valores numéricos, porcentajes y cantidades requeridas/bonificadas
 *              sean consistentes según la modalidad del beneficio otorgado.
 *
 * @param {INTEGER} p_tipo_beneficio_id - Modalidad del beneficio (1501: PORCENTAJE, 1502: MONTO_FIJO, 1503: CANTIDAD/3x2, 1504: NINGUNO).
 * @param {INTEGER} p_cantidad_requerida - Cantidad mínima de unidades a comprar para activar la promoción.
 * @param {INTEGER} p_cantidad_beneficio - Cantidad de unidades bonificadas o regaladas otorgadas por la promoción.
 * @param {NUMERIC} p_valor_beneficio - Monto escalar o porcentaje del descuento aplicado.
 *
 * @returns {BOOLEAN} Retorna TRUE si todos los parámetros cumplen con las restricciones del tipo de beneficio.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `tipo_beneficio_id = 1503` (CANTIDAD) y `p_cantidad_requerida` o `p_cantidad_beneficio` son <= 0.
 * - Si `tipo_beneficio_id = 1501` (PORCENTAJE) y `p_valor_beneficio` es <= 0 o > 100.
 * - Si `tipo_beneficio_id = 1502` (MONTO_FIJO) y `p_valor_beneficio` es <= 0.
 * - Si `tipo_beneficio_id = 1504` (NINGUNO) y cualquiera de los parámetros de cantidad o valor es distinto de 0.
 *
 * @reglas_de_negocio
 * 1. Promoción por Cantidad / Combo (1503): Exige volúmenes de compra y regales estrictamente positivos (ej. compra X unidades, lleva Y).
 * 2. Promoción por Porcentaje (1501): Restringe el valor del descuento al rango contable válido entre `1.00%` y `100.00%`.
 * 3. Promoción por Monto Fijo (1502): Exige que la deducción monetaria directa sea estrictamente mayor a 0.
 * 4. Sin Promoción / Ninguno (1504): Blinda los campos obligando a resetear a 0 cualquier métrica de descuento/cantidad.
 *
 * @properties
 * IMMUTABLE: La función no realiza consultas a tablas y depende exclusivamente de sus argumentos de entrada.
 *
 * @example
 * -- Retorna TRUE (Descuento del 15%)
 * SELECT fn_validar_coherencia_promocion(1501, 0, 0, 15.00);
 *
 * -- Retorna TRUE (Promoción 3x2: requiere 3, beneficia 1)
 * SELECT fn_validar_coherencia_promocion(1503, 3, 1, 0.00);
 *
 * -- Dispara EXCEPTION (Porcentaje superior a 100)
 * SELECT fn_validar_coherencia_promocion(1501, 0, 0, 120.00);
 */
CREATE FUNCTION fn_validar_coherencia_promocion(
    p_tipo_beneficio_id INTEGER,
    p_cantidad_requerida INTEGER,
    p_cantidad_beneficio INTEGER,
    p_valor_beneficio NUMERIC
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_beneficio_id = 1503 AND (p_cantidad_requerida <= 0 OR p_cantidad_beneficio <= 0) THEN
        RAISE EXCEPTION 'Promociones de tipo CANTIDAD requieren cantidades mayores a cero.';
    END IF;

    IF p_tipo_beneficio_id = 1501 AND (p_valor_beneficio <= 0 OR p_valor_beneficio > 100) THEN
        RAISE EXCEPTION 'Promociones de tipo PORCENTAJE requieren valor entre 1 y 100.';
    END IF;

    IF p_tipo_beneficio_id = 1502 AND p_valor_beneficio <= 0 THEN
        RAISE EXCEPTION 'Promociones de tipo MONTO_FIJO requieren valor mayor a cero.';
    END IF;

    IF p_tipo_beneficio_id = 1504 AND (p_cantidad_requerida <> 0 OR p_cantidad_beneficio <> 0 OR p_valor_beneficio <> 0) THEN
        RAISE EXCEPTION 'Promociones de tipo NINGUNO no deben tener cantidades ni valores.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_validar_coherencia_metrica
 * @description Garantiza la compatibilidad cruzada entre el tipo de algoritmo de analítica/machine learning,
 *              su métrica de precisión específica y la presencia del factor de estacionalidad.
 *              Especialmente diseñado para validar parámetros en modelos de pronóstico de series
 *              temporales (ej. ARIMA/SARIMA) frente a otros paradigmas de aprendizaje automático.
 *
 * @param {INTEGER} p_tipo_metricas_id - Tipo de modelo (3100: REGRESIÓN, 3101: CLASIFICACIÓN, 3102: CLUSTERING, 3103: NINGUNO).
 * @param {INTEGER} p_metrica_precision_id - Identificador del catálogo de métricas de precisión (3600..3603: Regresión, 3604: Clasificación, 3605: NINGUNO).
 * @param {INTEGER} p_factor_estacionalidad_id - Identificador del factor o ciclo estacional configurado para la serie.
 *
 * @returns {BOOLEAN} Retorna TRUE si la combinación de tipo, métrica y factor de estacionalidad es coherente.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `tipo_metricas_id = 3100` (REGRESIÓN) y la métrica de precisión no pertenece a `{3600, 3601, 3602, 3603, 3605}`.
 * - Si `tipo_metricas_id = 3101` (CLASIFICACIÓN) y la métrica de precisión no pertenece a `{3604, 3605}`.
 * - Si `tipo_metricas_id` es `3102` (CLUSTERING) o `3103` (NINGUNO) y la métrica no es `3605` (NINGUNO).
 * - Si `tipo_metricas_id = 3100` (REGRESIÓN/SERIES TEMPORALES) y `p_factor_estacionalidad_id` es NULL.
 * - Si `tipo_metricas_id` NO es regresión (`3101, 3102, 3103`) y posee un `p_factor_estacionalidad_id` asignado.
 *
 * @reglas_de_negocio
 * 1. Modelos Continuos / Pronóstico (3100): Exigen definir obligatoriamente un factor de estacionalidad (clave para SARIMA/demanda temporal) y restringir el catálogo a métricas de error continuo (ej. MAE, RMSE, MAPE).
 * 2. Modelos Discretos o No Supervisados (3101, 3102, 3103): Prohíben la presencia de factores de estacionalidad (exclusivos de series temporales) y fuerzan métricas compatibles o el comodín NINGUNO (`3605`).
 *
 * @properties
 * IMMUTABLE: Función pura que no consulta tablas de la base de datos y evalúa únicamente los parámetros escalares suministrados.
 *
 * @example
 * -- Retorna TRUE (Modelo de Regresión/Pronóstico con métrica y estacionalidad válidas)
 * SELECT fn_validar_coherencia_metrica(3100, 3601, 12);
 *
 * -- Dispara EXCEPTION (Intento de asignar factor de estacionalidad a Clasificación)
 * SELECT fn_validar_coherencia_metrica(3101, 3604, 12);
 *
 * -- Dispara EXCEPTION (Regresión sin factor de estacionalidad)
 * SELECT fn_validar_coherencia_metrica(3100, 3600, NULL);
 */
CREATE FUNCTION fn_validar_coherencia_metrica(
    p_tipo_metricas_id INTEGER,
    p_metrica_precision_id INTEGER,
    p_factor_estacionalidad_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_metricas_id = 3100 AND p_metrica_precision_id NOT IN (3600, 3601, 3602, 3603, 3605) THEN
        RAISE EXCEPTION 'El tipo de métrica REGRESION (3100) no es coherente con la precisión seleccionada (%)', p_metrica_precision_id;
    END IF;

    IF p_tipo_metricas_id = 3101 AND p_metrica_precision_id NOT IN (3604, 3605) THEN
        RAISE EXCEPTION 'El tipo de métrica CLASIFICACION (3101) no es coherente con la precisión seleccionada (%)', p_metrica_precision_id;
    END IF;

    IF p_tipo_metricas_id = 3102 AND p_metrica_precision_id <> 3605 THEN
        RAISE EXCEPTION 'El tipo de métrica CLUSTERING (3102) requiere precisión NINGUNO (3605).';
    END IF;

    IF p_tipo_metricas_id = 3103 AND p_metrica_precision_id <> 3605 THEN
        RAISE EXCEPTION 'El tipo de métrica NINGUNO (3103) requiere precisión NINGUNO (3605).';
    END IF;

    IF p_tipo_metricas_id = 3100 AND p_factor_estacionalidad_id IS NULL THEN
        RAISE EXCEPTION 'Los modelos de REGRESION (3100) requieren obligatoriamente un factor de estacionalidad definido.';
    END IF;

    IF p_tipo_metricas_id IN (3101, 3102, 3103) AND p_factor_estacionalidad_id IS NOT NULL THEN
        RAISE EXCEPTION 'Los modelos que no son de regresión (clasificación, clustering o ninguno) no deben tener un factor de estacionalidad asignado.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_validar_registros_entrenamiento
 * @description Valida la coherencia de la volumetría de datos procesados durante el ciclo
 *              de entrenamiento de modelos predictivos (ej. estimaciones ARIMA/SARIMA).
 *              Garantiza que un proceso de machine learning/estadístico marcado como 
 *              completado haya operado sobre un conjunto real de datos.
 *
 * @param {INTEGER} p_estado_ejecucion_id - Estado actual del proceso de entrenamiento (3051: COMPLETADO).
 * @param {BIGINT} p_registros_procesados - Cantidad total de registros del dataset evaluados o procesados en la ejecución.
 *
 * @returns {BOOLEAN} Retorna TRUE si la validación volumétrica es congruente con el estado de la ejecución.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `p_estado_ejecucion_id = 3051` (COMPLETADO) y los registros procesados son NULL o menores o iguales a cero (0).
 * - Si `p_registros_procesados` es menor que cero en cualquier estado de ejecución (valores negativos prohibidos).
 *
 * @reglas_de_negocio
 * 1. Consistencia de Éxito (3051): Un entrenamiento de modelo de pronóstico no puede considerarse exitoso/completado si no analizó información de entrada (histórico de demanda). Exige una muestra poblacional estrictamente mayor a 0.
 * 2. Integridad Numérica Universal: Bloquea a nivel de motor de base de datos la persistencia de valores negativos para los contadores de registros, independientemente del estado de ejecución.
 *
 * @properties
 * IMMUTABLE: La función es pura; no consulta tablas del esquema y su resultado lógico depende únicamente de las entradas escalares proporcionadas.
 *
 * @example
 * -- Retorna TRUE (Entrenamiento completado de forma válida con 1200 registros)
 * SELECT fn_validar_registros_entrenamiento(3051, 1200);
 *
 * -- Retorna TRUE (Entrenamiento en progreso, registros en NULL permitidos)
 * SELECT fn_validar_registros_entrenamiento(3050, NULL);
 *
 * -- Dispara EXCEPTION (Entrenamiento completado sin haber procesado registros)
 * SELECT fn_validar_registros_entrenamiento(3051, 0);
 *
 * -- Dispara EXCEPTION (Se proveen registros negativos)
 * SELECT fn_validar_registros_entrenamiento(3050, -50);
 */
CREATE FUNCTION fn_validar_registros_entrenamiento(
    p_estado_ejecucion_id INTEGER,
    p_registros_procesados BIGINT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Si el entrenamiento está completado (3051), exige obligatoriamente registros procesados mayores a 0
    IF p_estado_ejecucion_id = 3051 AND (p_registros_procesados IS NULL OR p_registros_procesados <= 0) THEN
        RAISE EXCEPTION 'Un entrenamiento completado (3051) debe registrar obligatoriamente una cantidad de registros procesados mayor a cero. Valor actual: %', p_registros_procesados;
    END IF;

    -- Validación opcional para asegurar que no existan negativos en otros estados si se proveen
    IF p_registros_procesados IS NOT NULL AND p_registros_procesados < 0 THEN
        RAISE EXCEPTION 'La cantidad de registros procesados no puede ser un valor negativo (%)', p_registros_procesados;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_validar_metricas_rendimiento
 * @description Evalúa y garantiza la consistencia de las métricas de rendimiento registradas para
 *              modelos de ciencia de datos y pronóstico de demanda (como ARIMA/SARIMA, regresión,
 *              clasificación o agrupación). Asegura que los campos requeridos para cada tipo
 *              de modelo matemático contengan datos cuantitativos o cualitativos válidos.
 *
 * @param {INTEGER} p_tipo_metricas_id - Tipo de modelo/métrica (3100: REGRESIÓN, 3101: CLASIFICACIÓN, 3102: CLUSTERING, 3103: NINGUNO).
 * @param {INTEGER} p_metrica_precision_id - Identificador de la métrica de precisión específica (ej. 3604, 3605).
 * @param {NUMERIC} p_error_absoluto_medio - MAE (Mean Absolute Error) del modelo predictivo.
 * @param {NUMERIC} p_raiz_error_cuadratico_medio - RMSE (Root Mean Squared Error) del modelo predictivo.
 * @param {NUMERIC} p_score_principal - Puntuación global o métrica principal del modelo (ej. R², Silhouette score).
 * @param {TEXT} p_detalles_metricas - Estructura en texto/JSON con detalles adicionales o métricas no estructuradas.
 *
 * @returns {BOOLEAN} Retorna TRUE si las métricas registradas son coherentes con la naturaleza del modelo.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `tipo_metricas_id = 3100` (REGRESIÓN) y no se registra al menos un indicador de error o score (MAE, RMSE o score principal).
 * - Si `tipo_metricas_id = 3101` (CLASIFICACIÓN) y no posee un ID de métrica de precisión válido (3604, 3605) ni un score principal.
 * - Si `tipo_metricas_id = 3102` (CLUSTERING) y carece tanto de score principal como de detalles de métricas.
 * - Si `tipo_metricas_id = 3103` (NINGUNO) y no incluye información en el campo de detalles de métricas.
 *
 * @reglas_de_negocio
 * 1. Modelos Continuos / Regresión (3100): Exigen evaluar la magnitud del error cuadrático o absoluto (utilizados en modelos ARIMA/SARIMA de series temporales).
 * 2. Modelos Discretos / Clasificación (3101): Requieren registrar la métrica de desempeño (ej. Accuracy, Precision, Recall, F1) mediante catálogo o score explícito.
 * 3. Modelos No Supervisados / Agrupación (3102): Validan la coherencia del cluster mediante métricas de silueta, cohesión o payload en texto/JSON.
 * 4. Modelos Genéricos / Métrica Ninguno (3103): Exigen documentar las razones o métricas personalizadas en el campo descriptivo.
 *
 * @properties
 * IMMUTABLE: Función pura que no consulta tablas en la base de datos y depende estrictamente de sus argumentos de entrada.
 *
 * @example
 * -- Retorna TRUE (Modelo de Regresión con MAE y RMSE calculados)
 * SELECT fn_validar_metricas_rendimiento(3100, NULL, 2.45, 3.12, 0.91, NULL);
 *
 * -- Dispara EXCEPTION (Modelo de Clasificación sin métricas)
 * SELECT fn_validar_metricas_rendimiento(3101, NULL, NULL, NULL, NULL, NULL);
 */
CREATE FUNCTION fn_validar_metricas_rendimiento(
    p_tipo_metricas_id INTEGER,
    p_metrica_precision_id INTEGER,
    p_error_absoluto_medio NUMERIC,
    p_raiz_error_cuadratico_medio NUMERIC,
    p_score_principal NUMERIC,
    p_detalles_metricas TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validación para REGRESION (3100)
    IF p_tipo_metricas_id = 3100 AND (p_error_absoluto_medio IS NULL AND p_raiz_error_cuadratico_medio IS NULL AND p_score_principal IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo REGRESION (3100) deben registrar al menos una métrica válida (error_absoluto_medio, raiz_error_cuadratico_medio o score_principal).';
    END IF;

    -- Validación para CLASIFICACION (3101)
    IF p_tipo_metricas_id = 3101 AND (p_metrica_precision_id NOT IN (3604, 3605) AND p_score_principal IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo CLASIFICACION (3101) requieren una métrica de precisión válida o un score principal.';
    END IF;

    -- Validación para CLUSTERING (3102)
    IF p_tipo_metricas_id = 3102 AND (p_score_principal IS NULL AND p_detalles_metricas IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo CLUSTERING (3102) requieren un score principal o detalles de métricas.';
    END IF;

    -- Validación para NINGUNO (3103)
    IF p_tipo_metricas_id = 3103 AND p_detalles_metricas IS NULL THEN
        RAISE EXCEPTION 'Los modelos con tipo de métrica NINGUNO (3103) deben registrar detalles en la estructura de métricas.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_validar_outlier_con_error
 * @description Garantiza la consistencia en el módulo de predicción de demanda de inventarios.
 *              Valida que cuando un modelo predictivo (como ARIMA/SARIMA) entra en estado de fallo
 *              o anomalía (ERROR), exista la justificación cualitativa correspondiente del outlier.
 *
 * @param {INTEGER} p_estado_pronostico_id - Identificador del estado del pronóstico (1552: ERROR / ANOMALÍA).
 * @param {INTEGER} p_motivo_outlier_id - Identificador del catálogo de motivos de outlier (1907: NINGUNO).
 *
 * @returns {BOOLEAN} Retorna TRUE si el estado y el motivo asignado guardan coherencia técnica.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `estado_pronostico_id = 1552` (ERROR) y el motivo de outlier es NULL o igual a `1907` (NINGUNO).
 * - Si `p_motivo_outlier_id` contiene un valor negativo fuera de catálogo.
 *
 * @reglas_de_negocio
 * 1. Trazabilidad de Fallos: Un pronóstico fallido o con inconsistencia estadística exige clasificar la causa raíz (ej. cambio abrupto de demanda, quiebre de stock, evento atípico).
 * 2. Restricción de Valor Por Defecto: Prohíbe mantener el valor comodín `1907` (NINGUNO) cuando el modelo fue marcado explícitamente en estado de error.
 * 3. Dominio de Datos: Asegura que las referencias numéricas a dominios de parámetros sean IDs válidos no negativos.
 *
 * @properties
 * IMMUTABLE: Función pura que no realiza lecturas en tablas de la base de datos y depende únicamente de los parámetros suministrados.
 *
 * @example
 * -- Retorna TRUE (Pronóstico en error con motivo de outlier asignado)
 * SELECT fn_validar_outlier_con_error(1552, 1901);
 *
 * -- Dispara EXCEPTION (Error sin justificación válida)
 * SELECT fn_validar_outlier_con_error(1552, 1907);
 */
CREATE FUNCTION fn_validar_outlier_con_error(
    p_estado_pronostico_id INTEGER,
    p_motivo_outlier_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Si el estado del pronóstico es ERROR (1552), exige un motivo de outlier diferente de NINGUNO (1907)
    IF p_estado_pronostico_id = 1552 AND (p_motivo_outlier_id IS NULL OR p_motivo_outlier_id = 1907) THEN
        RAISE EXCEPTION 'Un pronóstico en estado de ERROR (1552) requiere obligatoriamente especificar un motivo de outlier válido distinto de NINGUNO (1907).';
    END IF;

    -- Validación opcional para asegurar integridad si el motivo no es nulo
    IF p_motivo_outlier_id IS NOT NULL AND p_motivo_outlier_id < 0 THEN
        RAISE EXCEPTION 'El identificador del motivo de outlier no puede ser un valor negativo (%)', p_motivo_outlier_id;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_actualizar_rating_proveedor
 * @description Evalúa el desempeño de calidad de un proveedor analizando el historial de 
 *              compras y devoluciones en la tabla 'kardex' durante los últimos 12 meses, 
 *              actualizando su clasificación (rating) en la tabla 'proveedores'.
 *
 * @param {BIGINT} p_proveedor_id - Identificador único del proveedor a evaluar.
 * @returns {INTEGER} Retorna el ID del nuevo rating de calidad asignado (catálogo 2050 - 2054).
 *
 * @reglas_de_negocio
 * 1. Ventana de Evaluación: Mapea eventos en 'kardex' con estado_id = 1000 en los últimos 365 días.
 * 2. Eventos Evaluados:
 *    - Compra (evento_id = 1050).
 *    - Devolución (evento_id = 1061).
 * 3. Escala de Calificación por Porcentaje de Devoluciones:
 *    - > 30% : 2050 (PESIMO)
 *    - > 20% : 2051 (DEFICIENTE)
 *    - > 10% : 2052 (REGULAR)
 *    - > 5%  : 2053 (BUENO)
 *    - <= 5% : 2054 (EXCELENTE)
 * 4. Si el proveedor no registra compras (v_total_compras = 0), se asigna 2054 (EXCELENTE) por defecto.
 *
 * @auditoria
 * Actualiza en 'proveedores':
 * - rating_calidad_id
 * - ultima_evaluacion (fecha actual)
 * - fecha_actualizacion / usuario_id_actualizacion
 *
 * @example
 * SELECT fn_actualizar_rating_proveedor(102);
 */
CREATE FUNCTION fn_actualizar_rating_proveedor(
    p_proveedor_id BIGINT
) RETURNS INTEGER AS $$
DECLARE
    v_total_compras INTEGER;
    v_devoluciones INTEGER;
    v_porcentaje_devoluciones DECIMAL(5,2);
    v_rating_actual INTEGER;
    v_nuevo_rating INTEGER;
BEGIN
    -- Contar compras y devoluciones de los últimos 12 meses
    SELECT
        COUNT(*) FILTER (WHERE evento_id = 1050),
        COUNT(*) FILTER (WHERE evento_id = 1061)
    INTO v_total_compras, v_devoluciones
    FROM kardex
    WHERE proveedor_id = p_proveedor_id
      AND estado_id = 1000
      AND fecha_kardex >= CURRENT_DATE - INTERVAL '12 months';

    -- Calcular porcentaje de devoluciones
    IF v_total_compras > 0 THEN
        v_porcentaje_devoluciones := (v_devoluciones::DECIMAL / v_total_compras) * 100;
    ELSE
        v_porcentaje_devoluciones := 0;
    END IF;

    -- Determinar nuevo rating
    IF v_porcentaje_devoluciones > 30 THEN
        v_nuevo_rating := 2050;  -- PESIMO
    ELSIF v_porcentaje_devoluciones > 20 THEN
        v_nuevo_rating := 2051;  -- DEFICIENTE
    ELSIF v_porcentaje_devoluciones > 10 THEN
        v_nuevo_rating := 2052;  -- REGULAR
    ELSIF v_porcentaje_devoluciones > 5 THEN
        v_nuevo_rating := 2053;  -- BUENO
    ELSE
        v_nuevo_rating := 2054;  -- EXCELENTE
    END IF;

    -- Actualizar proveedor
    UPDATE proveedores
    SET rating_calidad_id = v_nuevo_rating,
        ultima_evaluacion = CURRENT_DATE,
        fecha_actualizacion = CURRENT_TIMESTAMP,
        usuario_id_actualizacion = 1
    WHERE proveedor_id = p_proveedor_id;

    RETURN v_nuevo_rating;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_validar_coherencia_cierre_caja
 * @description Garantiza la integridad de datos en el ciclo de vida de una caja de efectivo.
 *              Valida que los campos relacionados con la liquidación y cierre (fecha, monto final y usuario)
 *              cumplan de forma estricta con el estado operativo de la caja (ABIERTA vs CERRADA).
 *
 * @param {INTEGER} p_estado_caja_id - Estado de la caja (2650: ABIERTA, 2651: CERRADA).
 * @param {TIMESTAMPTZ} p_fecha_cierre - Marca de tiempo en que se efectuó el cierre de caja.
 * @param {DECIMAL(12,2)} p_monto_final_real - Arqueo de efectivo final reportado en caja.
 * @param {BIGINT} p_usuario_id_cierre - Identificador del usuario que autorizó/ejecutó el cierre.
 *
 * @returns {BOOLEAN} Retorna TRUE si los campos mantienen coherencia estricta con el estado.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `estado_caja_id = 2650` (ABIERTA) y se asigna fecha, monto final o usuario de cierre (deben ser NULL).
 * - Si `estado_caja_id = 2651` (CERRADA) y falta alguno de los campos de cierre (fecha, monto final o usuario).
 *
 * @reglas_de_negocio
 * 1. Caja ABIERTA (2650): Prohibida la persistencia prematura de datos de cierre.
 * 2. Caja CERRADA (2651): Exige obligatoriedad absoluta (NOT NULL) en auditoría y arqueo de cierre.
 * 3. Transición de Estado: Previene incoherencias en disparadores (triggers) o validaciones de esquemas.
 *
 * @properties
 * IMMUTABLE: La función depende únicamente de los parámetros recibidos y no realiza consultas de base de datos.
 *
 * @example
 * -- Retorna TRUE (Caja Abierta válida)
 * SELECT fn_validar_coherencia_cierre_caja(2650, NULL, NULL, NULL);
 *
 * -- Retorna TRUE (Caja Cerrada válida)
 * SELECT fn_validar_coherencia_cierre_caja(2651, NOW(), 1500.50, 4);
 *
 * -- Dispara EXCEPTION (Monto en caja abierta)
 * SELECT fn_validar_coherencia_cierre_caja(2650, NULL, 500.00, NULL);
 */
CREATE FUNCTION fn_validar_coherencia_cierre_caja(
    p_estado_caja_id INTEGER,
    p_fecha_cierre TIMESTAMPTZ,
    p_monto_final_real DECIMAL(12,2),
    p_usuario_id_cierre BIGINT
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_estado_caja_id = 2650 AND (p_fecha_cierre IS NOT NULL OR p_monto_final_real IS NOT NULL OR p_usuario_id_cierre IS NOT NULL) THEN
        RAISE EXCEPTION 'Una caja abierta (2650) no debe tener fecha de cierre, monto final real ni usuario de cierre.';
    END IF;

    IF p_estado_caja_id = 2651 AND (p_fecha_cierre IS NULL OR p_monto_final_real IS NULL OR p_usuario_id_cierre IS NULL) THEN
        RAISE EXCEPTION 'Una caja cerrada (2651) requiere obligatoriamente fecha de cierre, monto final real y usuario de cierre.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_validar_coherencia_saldo_movimiento
 * @description Valida que la ecuación de balance contable de un movimiento sea consistente
 *              según su naturaleza (Ingreso vs Egreso). Lanza una excepción controlada
 *              si se detecta una discrepancia entre el saldo previo, el monto y el saldo resultante.
 *
 * @param {INTEGER} p_tipo_movimiento_id - Identificador del tipo de movimiento (2600: INGRESO, 2601: EGRESO).
 * @param {DECIMAL(12,2)} p_saldo_antes - Saldo contable existente antes de la transacción.
 * @param {DECIMAL(12,2)} p_monto - Monto de la operación a aplicar.
 * @param {DECIMAL(12,2)} p_saldo_despues - Saldo resultante registrado en la transacción.
 *
 * @returns {BOOLEAN} Retorna TRUE si la suma o resta aritmética es exacta.
 *
 * @throws {RAISE_EXCEPTION}
 * - Si `tipo_movimiento_id = 2600` (INGRESO) y `p_saldo_despues <> p_saldo_antes + p_monto`.
 * - Si `tipo_movimiento_id = 2601` (EGRESO) y `p_saldo_despues <> p_saldo_antes - p_monto`.
 *
 * @reglas_de_negocio
 * 1. Operación INGRESO (2600): Exige la fórmula estricta `Saldo Después = Saldo Antes + Monto`.
 * 2. Operación EGRESO (2601): Exige la fórmula estricta `Saldo Después = Saldo Antes - Monto`.
 * 3. Otros Tipos: Si se pasa un tipo distinto, omite las validaciones y retorna TRUE.
 *
 * @properties
 * IMMUTABLE: La función no consulta la base de datos y depende únicamente de sus argumentos de entrada.
 *
 * @example
 * -- Retorna TRUE
 * SELECT fn_validar_coherencia_saldo_movimiento(2600, 100.00, 50.00, 150.00);
 * 
 * -- Dispara EXCEPTION
 * SELECT fn_validar_coherencia_saldo_movimiento(2601, 100.00, 50.00, 80.00);
 */
CREATE FUNCTION fn_validar_coherencia_saldo_movimiento(
    p_tipo_movimiento_id INTEGER,
    p_saldo_antes DECIMAL(12,2),
    p_monto DECIMAL(12,2),
    p_saldo_despues DECIMAL(12,2)
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_movimiento_id = 2600 AND p_saldo_despues <> (p_saldo_antes + p_monto) THEN
        RAISE EXCEPTION 'El saldo despues (%) no coincide con el ingreso esperado (%) para el movimiento tipo INGRESO (2600).', p_saldo_despues, (p_saldo_antes + p_monto);
    END IF;

    IF p_tipo_movimiento_id = 2601 AND p_saldo_despues <> (p_saldo_antes - p_monto) THEN
        RAISE EXCEPTION 'El saldo despues (%) no coincide con el egreso esperado (%) para el movimiento tipo EGRESO (2601).', p_saldo_despues, (p_saldo_antes - p_monto);
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * @function fn_cerrar_planes_pago
 * @description Recorre y evalúa masivamente los planes de pago de compras con saldo pendiente o parcial.
 *              Si todas las cuotas asociadas a una compra se encuentran pagadas o saldadas,
 *              actualiza el estado financiero de la transacción y marca las cuotas como cerradas.
 *
 * @returns {INTEGER} Retorna la cantidad total de planes de pago/compras que fueron liquidados y cerrados en la ejecución.
 *
 * @reglas_de_negocio
 * 1. Criterios de Selección:
 *    - Transacciones en 'kardex' tipo COMPRA (`evento_id = 1050`).
 *    - Estado financiero activo (`estado_financiero_id IN (2401, 2402)` -> PENDIENTE o PARCIAL).
 *    - Registros vigentes en 'planes_pagos' (`estado_id = 1000`).
 * 2. Condición de Cierre:
 *    - Se verifica que el total de cuotas registradas sea igual al total de cuotas con estado de pago saldado (`estado_pago_id IN (2552, 2553)`).
 * 3. Acciones de Cierre:
 *    - Transición en 'kardex': `estado_financiero_id` pasa a `2400` (CANCELADO/PAGADO).
 *    - Transición en 'planes_pagos': `estado_pago_id` pasa a `2553` (CERRADO).
 *
 * @auditoria
 * Registra fecha de actualización (`CURRENT_TIMESTAMP`) y usuario de auditoría (`usuario_id_actualizacion = 1`) en 'kardex' y 'planes_pagos'.
 *
 * @example
 * SELECT fn_cerrar_planes_pago();
 */
CREATE FUNCTION fn_cerrar_planes_pago()
RETURNS INTEGER AS $$
DECLARE
    v_plan RECORD;
    v_total_cuotas INTEGER;
    v_cuotas_pagadas INTEGER;
    v_contador INTEGER := 0;
BEGIN
    FOR v_plan IN
        SELECT DISTINCT pp.kardex_id
        FROM planes_pagos pp
        JOIN kardex k ON k.kardex_id = pp.kardex_id
        WHERE k.evento_id = 1050  -- COMPRA
          AND k.estado_financiero_id IN (2401, 2402)  -- PENDIENTE o PARCIAL
          AND pp.estado_id = 1000
    LOOP
        -- Contar cuotas totales y pagadas
        SELECT COUNT(*), COUNT(*) FILTER (WHERE estado_pago_id IN (2552, 2553))
        INTO v_total_cuotas, v_cuotas_pagadas
        FROM planes_pagos
        WHERE kardex_id = v_plan.kardex_id
          AND estado_id = 1000;

        -- Si todas las cuotas están pagadas, cerrar el plan
        IF v_cuotas_pagadas = v_total_cuotas THEN
            -- Actualizar estado financiero de la compra
            UPDATE kardex
            SET estado_financiero_id = 2400,  -- CANCELADO
                fecha_actualizacion = CURRENT_TIMESTAMP,
                usuario_id_actualizacion = 1
            WHERE kardex_id = v_plan.kardex_id;

            -- Marcar todas las cuotas como CERRADAS
            UPDATE planes_pagos
            SET estado_pago_id = 2553,  -- CERRADO
                fecha_actualizacion = CURRENT_TIMESTAMP,
                usuario_id_actualizacion = 1
            WHERE kardex_id = v_plan.kardex_id
              AND estado_id = 1000;

            v_contador := v_contador + 1;
        END IF;
    END LOOP;

    RETURN v_contador;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_puedo_eliminar_usuario
 * @description Evalúa si un usuario puede ser dado de baja lógicamente (estado 1001).
 *
 * @param {BIGINT} p_usuario_id - Identificador del usuario.
 * @returns {BOOLEAN} TRUE si se puede dar de baja, FALSE si falla alguna regla.
 *
 * Reglas de negocio evaluadas:
 * - Protege ID=1 y 'ADMIN'.
 * - Requiere que el usuario esté en estado ACTIVO (1000).
 * - Verifica ausencia de transacciones en proceso (estado 1000, 1002) en movimientos e historial.
 */
CREATE OR REPLACE FUNCTION fn_puedo_eliminar_usuario(p_usuario_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    v_login VARCHAR(10);
    v_estado_id INTEGER;
BEGIN
    -- 1. Protecciones críticas del sistema (Semilla ID=1)
    IF p_usuario_id = 1 THEN
        RETURN FALSE;
    END IF;

    -- 2. Validar existencia y estado ACTIVO (1000)
    SELECT login, estado_id INTO v_login, v_estado_id 
    FROM usuarios 
    WHERE usuario_id = p_usuario_id;

    IF NOT FOUND OR v_estado_id <> 1000 THEN
        RETURN FALSE;
    END IF;

    -- 3. Inmutabilidad de ADMIN
    IF v_login = 'ADMIN' THEN
        RETURN FALSE;
    END IF;

    -- 4. Validar operaciones activas/pendientes asignadas (1000, 1002)
    IF EXISTS (
        SELECT 1 FROM movimientos 
        WHERE usuario_id = p_usuario_id AND estado_id IN (1000, 1002)
        
        UNION ALL
        
        SELECT 1 FROM ubicaciones_historial 
        WHERE usuario_id = p_usuario_id AND estado_id IN (1000, 1002)
    ) THEN
        RETURN FALSE;
    END IF;

    -- Cumple con todas las condiciones para la baja lógica
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================================================

/**
 * @function fn_verificar_dependencias
 * 
 * @param {VARCHAR} p_table_name - Nombre de la tabla padre objetivo (ej: 'bancos', 'almacenes').
 * @param {INTEGER} p_id - Identificador único (ID) del registro padre a verificar.
 * @param {BOOLEAN} [p_solo_activos=FALSE] - Si es TRUE, cuenta únicamente dependencias en estado 'Activo' (1000).
 *                                           Si es FALSE, cuenta dependencias en estado 'Activo' (1000) e 'Histórico' (1001).
 *
 * @returns {TABLE}
 * @returns {BIGINT} total_dependencias - Cantidad total acumulada de registros dependientes encontrados.
 * @returns {TEXT} detalle_dependencias - Cadena formateada con el desglose de tablas, columnas y número de registros afectados.
 *
 * @example
 * -- Verificar dependencias totales (Activos e Históricos) para el Banco con ID 5
 * SELECT * FROM fn_verificar_dependencias('bancos', 5);
 *
 * @example
 * -- Verificar únicamente dependencias en estado Activo para el Almacén con ID 2
 * SELECT * FROM fn_verificar_dependencias('almacenes', 2, TRUE);
 */
CREATE OR REPLACE FUNCTION fn_verificar_dependencias(
    p_table_name VARCHAR,
    p_id INTEGER,
    p_solo_activos BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    total_dependencias BIGINT,
    detalle_dependencias TEXT
) AS $$
DECLARE
    v_total BIGINT := 0;
    v_detalle TEXT := '';
    v_count BIGINT;
    v_row RECORD;
    v_estado_activo CONSTANT INTEGER := 1000;
    v_estado_historico CONSTANT INTEGER := 1001;
BEGIN
    FOR v_row IN 
        SELECT 
            cl_child.relname AS tabla_hija,
            att_child.attname AS columna_hija
        FROM pg_constraint c
        JOIN pg_class cl_child ON c.conrelid = cl_child.oid
        JOIN pg_class cl_parent ON c.confrelid = cl_parent.oid
        JOIN pg_attribute att_child ON att_child.attrelid = cl_child.oid 
            AND att_child.attnum = ANY(c.conkey)
        JOIN pg_namespace nsp ON cl_child.relnamespace = nsp.oid
        WHERE c.contype = 'f' 
          AND cl_parent.relname = p_table_name
          AND cl_child.relname != p_table_name
          AND nsp.nspname = 'public'
    LOOP
        IF p_solo_activos THEN
            EXECUTE format(
                'SELECT COUNT(1) FROM %I WHERE %I = $1 AND estado_id = $2',
                v_row.tabla_hija, v_row.columna_hija
            ) INTO v_count USING p_id, v_estado_activo;
        ELSE
            EXECUTE format(
                'SELECT COUNT(1) FROM %I WHERE %I = $1 AND estado_id IN ($2, $3)',
                v_row.tabla_hija, v_row.columna_hija
            ) INTO v_count USING p_id, v_estado_activo, v_estado_historico;
        END IF;
        
        IF v_count > 0 THEN
            v_total := v_total + v_count;
            v_detalle := v_detalle || 
                format('- Tabla "%s".%s: %s registro(s)\n', 
                    v_row.tabla_hija, 
                    v_row.columna_hija, 
                    v_count
                );
        END IF;
    END LOOP;

    RETURN QUERY SELECT v_total, v_detalle;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================================================
-- FUNCION MEJORADA 

-- ================================================================================================
-- Función: fn_validar_reglas_negocio (CORREGIDA)
-- ================================================================================================

/**
 * @function fn_validar_reglas_negocio
 * @description Valida TODAS las reglas de negocio del sistema en un solo lugar
 *
 * ?? CONTEXTOS SOPORTADOS:
 *   - 'KARDEX': Validaci?n de cabecera de transacci?n
 *   - 'KARDEX_PRODUCTO': Validaci?n de detalle de transacci?n
 *   - 'DOMINIO': Validaci?n de dominios protegidos
 *
 * ?? REGLAS DE NEGOCIO APLICADAS:
 *   - R.1: Registro Inicial Comod?n (ID=1) no modificable
 *   - R.2: Control de Estados (ACTIVO, BORRADO, HISTORICO, ANULADO)
 *   - R.8: Ventas al contado (estado_financiero_id = 2400)
 *   - R.9: Cr?dito a proveedores (estado_financiero_id 2400-2402)
 *   - R.14: Matriz de integridad de entidades por evento
 *   - R.16: Validaci?n de estado de traspaso (OBS. 04)
 *   - R.17: Validaci?n de estado de pedido
 *   - R.18: Validaci?n de tipo de despacho
 *   - R.19: Validaci?n de devoluciones (OBS. 11)
 *   - R.G.6: Dominios protegidos (es_protegido = 1)
 *   - R.42: Validaci?n de tipo_pago_id para DEVOLUCION_CLIENTE (OBS. 05)
 *   - R.45: Validaci?n de tipo_pago_id para DEVOLUCION_PROVEEDOR (OBS. 05)
 *   - R.32: Validaci?n de descuento en DEVOLUCION_CLIENTE (OBS. 06)
 *   - R.35: Validaci?n de descuento en DEVOLUCION_PROVEEDOR (OBS. 06)
 *   - R.38: Validaci?n de costo_venta en INGRESO_TRASPASO (OBS. 16)
 *
 * ================================================================================================
 *
 * @param {VARCHAR} p_contexto - Contexto de validaci?n
 *   - 'KARDEX': Validaci?n de cabecera de transacci?n
 *   - 'KARDEX_PRODUCTO': Validaci?n de detalle de transacci?n
 *   - 'DOMINIO': Validaci?n de dominios protegidos
 *
 * @param {INTEGER} p_evento_id - ID del evento (dominio EventoID 1050-1070)
 *   - 1050: COMPRA
 *   - 1051: VENTA
 *   - 1052: PROFORMA
 *   - 1053: EGRESO_TRASPASO
 *   - 1054: INGRESO_TRASPASO
 *   - 1055: ANULACION
 *   - 1056: AJUSTE_INGRESO
 *   - 1057: AJUSTE_EGRESO
 *   - 1058: SOLICITUD_COMPRA
 *   - 1059: VENTA_RESERVA
 *   - 1060: DEVOLUCION_CLIENTE
 *   - 1061: DEVOLUCION_PROVEEDOR
 *   - 1062: ROBO
 *   - 1063: PERDIDA_CADUCIDAD
 *   - 1064: MERMA_ROTURA
 *   - 1065: INVENTARIO_FISICO_SOBRANTE
 *   - 1066: INVENTARIO_FISICO_FALTANTE
 *   - 1067: CONVERSION_UNIDADES
 *   - 1068: RETIRO_CUARENTENA
 *
 * @param {BIGINT} p_cliente_id - ID del cliente (tabla clientes)
 *   - 1: Cliente comod?n (an?nimo / sin identificar)
 *   - >1: Cliente registrado
 *
 * @param {BIGINT} p_proveedor_id - ID del proveedor (tabla proveedores)
 *   - 1: Proveedor comod?n
 *   - >1: Proveedor registrado
 *
 * @param {INTEGER} p_estado_financiero_id - Estado financiero (dominio 2400-2404)
 *   - 2400: CANCELADO
 *   - 2401: PENDIENTE
 *   - 2402: PARCIAL
 *   - 2403: NINGUNO
 *   - 2404: DEVOLUCION_GENERADA (NUEVO)
 *
 * @param {DECIMAL(12,2)} p_total_venta - Total de venta sin factura
 * @param {DECIMAL(12,2)} p_total_venta_factura - Total de venta con factura
 *
 * @param {INTEGER} p_estado_id - Estado del registro (dominio EstadoID 1000-1003)
 *   - 1000: ACTIVO
 *   - 1001: BORRADO
 *   - 1002: HISTORICO
 *   - 1003: ANULADO
 *
 * @param {BIGINT} p_kardex_origen_id - ID del origen (para traspasos - OBS. 03)
 *   - Obligatorio para INGRESO_TRASPASO (1054)
 *   - Debe ser NULL para EGRESO_TRASPASO (1053)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_referencia_id - ID de la transacci?n original (para devoluciones)
 *   - Obligatorio para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_sucursal_id - ID de la sucursal origen
 * @param {BIGINT} p_sucursal_destino_id - ID de la sucursal destino
 *   - Obligatorio para traspasos (1053, 1054)
 *   - Debe ser diferente a sucursal_id
 *
 * @param {INTEGER} p_estado_traspaso_id - Estado del traspaso (dominio 2100-2103 - OBS. 04)
 *   - 2100: EN_TRANSITO
 *   - 2101: RECIBIDO
 *   - 2102: RECHAZADO
 *   - 2103: NO_APLICA
 *
 * @param {BIGINT} p_kardex_pedido_compra_id - ID del pedido de compra (OBS. 14)
 *   - Obligatorio para SOLICITUD_COMPRA (1058)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_id - ID de la cabecera (tabla kardex)
 *   - Obligatorio para contexto 'KARDEX_PRODUCTO'
 *
 * @param {DECIMAL(12,2)} p_cantidad - Cantidad de entrada
 * @param {DECIMAL(12,2)} p_cantidad_salida - Cantidad de salida
 * @param {DECIMAL(12,2)} p_pcompra - Precio de compra unitario
 * @param {DECIMAL(12,2)} p_precio_venta - Precio de venta sin factura
 * @param {DECIMAL(12,2)} p_precio_venta_factura - Precio de venta con factura (con IVA)
 * @param {BIGINT} p_tipo_pago_id - Tipo de pago (dominio 1400-1409 - OBS. 06)
 *   - 1400: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1401-1409: Tipos definidos solo para VENTA (1051)
 *   - 1406: SIN_PAGO (obligatorio para DEVOLUCION_CLIENTE - OBS. 05)
 *
 * @param {INTEGER} p_tipo_venta_id - Tipo de venta (dominio 1350-1352 - OBS. 07)
 *   - 1350: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1351: CON_FACTURA (solo para VENTA)
 *   - 1352: SIN_FACTURA (solo para VENTA)
 *
 * @param {BIGINT} p_lote_id - ID del lote afectado (tabla lotes_productos - OBS. 01)
 *   - Debe ser > 1 para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser el mismo que el origen para INGRESO_TRASPASO (1054 - OBS. 09)
 *   - Puede ser 1 (comod?n) para otros eventos
 *
 * @param {DECIMAL(12,2)} p_costo_venta - Costo de venta (OBS. 16)
 *   - Debe ser 0 para INGRESO_TRASPASO (1054)
 *   - Debe ser > 0 para VENTA (1051)
 *   - Debe ser = costo_venta de la venta original para DEVOLUCION_CLIENTE (OBS. 16)
 *
 * @param {BIGINT} p_sucursal_detalle_id - ID de la sucursal en detalle (OBS. 10)
 *   - Debe coincidir con sucursal_id para EGRESO_TRASPASO (1053)
 *   - Debe coincidir con sucursal_destino_id para INGRESO_TRASPASO (1054)
 *
 * @param {DECIMAL(12,2)} p_descuento - Descuento aplicado (OBS. 10)
 *   - Solo permitido para VENTA (1051)
 *   - Debe ser 0 para ajustes, traspasos y otros eventos
 *   - Debe ser 0 para DEVOLUCION_CLIENTE (OBS. 06) y DEVOLUCION_PROVEEDOR (OBS. 06)
 *
 * @param {INTEGER} p_motivo_anulacion_id - Motivo de anulaci?n (dominio 2450-2455 - OBS. 13)
 *   - 2450-2454: Motivos permitidos solo para ANULACION (1055)
 *   - 2455: NINGUNO para otros eventos
 *   - Debe ser 2455 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 09)
 *
 * @param {INTEGER} p_motivo_devolucion_id - Motivo de devoluci?n (dominio 3500-3508 - OBS. 12)
 *   - 3500: PRODUCTO_VENCIDO
 *   - 3501: PRODUCTO_DA?ADO
 *   - 3502: ERROR_PEDIDO
 *   - 3503: EXCESO_STOCK
 *   - 3504: DESCONTINUADO
 *   - 3505: DEVOLUCION_CLIENTE
 *   - 3506: NINGUNO (para ajustes y otros eventos)
 *   - 3507: PRODUCTO_NO_SOLICITADO
 *   - 3508: PRODUCTO_DEFECTUOSO
 *   - Debe ser distinto de 3506 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {VARCHAR} p_comprobante_referencia - Comprobante de referencia (OBS. 11)
 *   - Obligatorio para DEVOLUCION_CLIENTE
 *   - Debe ser NULL para otros eventos
 *
 * @param {DECIMAL(12,2)} p_total_compra - Total de compra
 *   - Debe ser > 0 para COMPRA (1050)
 *   - Debe ser >= 0 para DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {BIGINT} p_dominio_id - ID del dominio a validar (tabla dominios)
 *   - Obligatorio para contexto 'DOMINIO'
 *   - Verifica que es_protegido != 1 (R.G.6)
 *
 * @returns {VOID} - No retorna valor
 *
 * @throws {EXCEPTION} Con mensajes descriptivos en los siguientes casos:
 *   - Evento no v?lido para el contexto
 *   - Cantidades inconsistentes con el tipo de evento (OBS. 05)
 *   - Precios incorrectos para el tipo de evento (OBS. 11)
 *   - Tipos de pago/venta no permitidos (OBS. 06, 07)
 *   - Descuento no permitido para ajustes (OBS. 10)
 *   - Descuento no permitido para DEVOLUCION_CLIENTE (OBS. 06)
 *   - Descuento no permitido para DEVOLUCION_PROVEEDOR (OBS. 06)
 *   - Motivos de anulaci?n/devoluci?n no permitidos (OBS. 12, 13)
 *   - Lote comod?n usado en devoluciones (OBS. 01)
 *   - Lote incorrecto en traspasos (OBS. 09)
 *   - Sucursal incorrecta en traspasos (OBS. 10)
 *   - costo_venta incorrecto en traspasos (OBS. 16)
 *   - Estado de traspaso incorrecto (OBS. 04, 13)
 *   - kardex_pedido_compra_id incorrecto (OBS. 14)
 *   - kardex_referencia_id obligatorio en devoluciones (OBS. 11)
 *   - comprobante_referencia obligatorio en DEVOLUCION_CLIENTE (OBS. 11)
 *   - Dominio protegido (es_protegido = 1 - R.G.6)
 *   - Contexto desconocido
 *
 * @since 4.3
 * @see kardex, kardex_productos, dominios
 * @see Reglas de Negocio R.1 a R.21 en la documentaci?n
 */
CREATE OR REPLACE FUNCTION fn_validar_reglas_negocio(
    -- Contexto
    p_contexto VARCHAR,

    -- Par?metros para KARDEX (Cabecera)
    p_evento_id INTEGER DEFAULT NULL,
    p_cliente_id BIGINT DEFAULT NULL,
    p_proveedor_id BIGINT DEFAULT NULL,
    p_estado_financiero_id INTEGER DEFAULT NULL,
    p_total_venta DECIMAL(12,2) DEFAULT NULL,
    p_total_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_estado_id INTEGER DEFAULT NULL,

    -- Par?metros para TRASPASOS
    p_kardex_origen_id BIGINT DEFAULT NULL,
    p_sucursal_id BIGINT DEFAULT NULL,
    p_sucursal_destino_id BIGINT DEFAULT NULL,
    p_estado_traspaso_id INTEGER DEFAULT NULL,
    p_kardex_pedido_compra_id BIGINT DEFAULT NULL,
    p_kardex_referencia_id BIGINT DEFAULT NULL,
    p_comprobante_referencia VARCHAR DEFAULT NULL,
    p_total_compra DECIMAL(12,2) DEFAULT NULL,

    -- Par?metros para KARDEX_PRODUCTO (Detalle)
    p_kardex_id BIGINT DEFAULT NULL,
    p_cantidad DECIMAL(12,2) DEFAULT NULL,
    p_cantidad_salida DECIMAL(12,2) DEFAULT NULL,
    p_pcompra DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_tipo_pago_id BIGINT DEFAULT NULL,
    p_tipo_venta_id INTEGER DEFAULT NULL,
    p_lote_id BIGINT DEFAULT NULL,
    p_costo_venta DECIMAL(12,2) DEFAULT NULL,
    p_sucursal_detalle_id BIGINT DEFAULT NULL,

    -- Par?metros adicionales
    p_descuento DECIMAL(12,2) DEFAULT NULL,
    p_motivo_anulacion_id INTEGER DEFAULT NULL,
    p_motivo_devolucion_id INTEGER DEFAULT NULL,

    -- Par?metros para DOMINIO
    p_dominio_id BIGINT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_evento_id INTEGER;
    v_es_protegido INTEGER;
    v_estado_actual INTEGER;
    v_origen_evento_id INTEGER;
    v_origen_estado_id INTEGER;
    v_origen_sucursal_id BIGINT;
    v_origen_lote_id BIGINT;
    v_origen_costo_venta DECIMAL(12,2);
    v_referencia_tipo INTEGER;
    v_monto_devolucion DECIMAL(12,2);
BEGIN
    ------------------------------------------------------------------
    -- CONTEXTO 1: VALIDACI?N PARA KARDEX (CABECERA)
    ------------------------------------------------------------------
    IF p_contexto = 'KARDEX' THEN

        -- ============================================================
        -- 1.1: VALIDACI?N DE EVENTOS DE AJUSTE
        -- ============================================================
        IF p_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_total_venta <> 0 OR p_total_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere total_venta = 0 y total_venta_factura = 0', p_evento_id;
            END IF;
            IF p_cliente_id <> 1 OR p_proveedor_id <> 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere cliente_id = 1 y proveedor_id = 1', p_evento_id;
            END IF;
            IF p_motivo_devolucion_id IS NOT NULL AND p_motivo_devolucion_id <> 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_devolucion_id', p_evento_id;
            END IF;
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id <> 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_anulacion_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 1.2: VENTA debe ser CANCELADO
        -- ============================================================
        IF p_evento_id = 1051 AND p_estado_financiero_id <> 2400 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: VENTA (1051) requiere estado_financiero_id = 2400 (CANCELADO)';
        END IF;

        -- ============================================================
        -- 1.3: COMPRA puede tener cualquier estado financiero
        -- ============================================================
        IF p_evento_id = 1050 AND p_estado_financiero_id NOT IN (2400, 2401, 2402) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: COMPRA (1050) requiere estado_financiero_id en (2400, 2401, 2402)';
        END IF;

        -- ============================================================
        -- 1.4: DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR deben tener estado_financiero_id = 2404
        -- ============================================================
        IF p_evento_id IN (1060, 1061) AND p_estado_financiero_id <> 2404 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Devoluci?n % requiere estado_financiero_id = 2404 (DEVOLUCION_GENERADA)', p_evento_id;
        END IF;

        -- ============================================================
        -- 1.5: OTROS EVENTOS deben tener estado_financiero_id = 2403
        -- ============================================================
        IF p_evento_id NOT IN (1050, 1051, 1060, 1061) AND p_estado_financiero_id <> 2403 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere estado_financiero_id = 2403 (NINGUNO)', p_evento_id;
        END IF;

        -- ============================================================
        -- 1.6: VALIDACI?N DE ESTADOS
        -- ============================================================
        IF p_estado_id IS NOT NULL AND p_estado_id NOT IN (1000, 1001, 1002, 1003) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Estado % no v?lido', p_estado_id;
        END IF;

        -- ============================================================
        -- 1.7: VALIDACI?N DE ESTADO_TRASPASO_ID (OBS. 04)
        -- ============================================================
        IF p_evento_id IN (1053, 1054) THEN
            IF p_estado_traspaso_id IS NULL OR p_estado_traspaso_id NOT IN (2100, 2101, 2102) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso % requiere estado_traspaso_id en (2100, 2101, 2102)', p_evento_id;
            END IF;
        ELSE
            IF p_estado_traspaso_id IS NOT NULL AND p_estado_traspaso_id != 2103 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % debe tener estado_traspaso_id = 2103 (NO_APLICA)', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 1.8: VALIDACI?N DE KARDEX_PEDIDO_COMPRA_ID (OBS. 14)
        -- ============================================================
        IF p_evento_id = 1058 THEN
            IF p_kardex_pedido_compra_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: SOLICITUD_COMPRA (1058) requiere kardex_pedido_compra_id no nulo';
            END IF;
            -- Validar que el pedido exista y sea una solicitud de compra
            IF NOT EXISTS (
                SELECT 1 FROM kardex
                WHERE kardex_id = p_kardex_pedido_compra_id
                AND evento_id = 1058
                AND estado_id = 1000
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_pedido_compra_id % debe ser una SOLICITUD_COMPRA (1058) activa',
                    p_kardex_pedido_compra_id;
            END IF;
        ELSE
            IF p_kardex_pedido_compra_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_pedido_compra_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 1.9: VALIDACI?N DE TRASPASOS (OBS. 03 y 13)
        -- ============================================================
        -- Solo traspasos pueden tener origen y sucursal_destino
        IF p_evento_id NOT IN (1053, 1054) THEN
            IF p_kardex_origen_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_origen_id', p_evento_id;
            END IF;
            IF p_sucursal_destino_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener sucursal_destino_id', p_evento_id;
            END IF;
        END IF;

        -- Traspasos requieren sucursal_destino_id diferente
        IF p_evento_id IN (1053, 1054) THEN
            IF p_sucursal_destino_id IS NULL OR p_sucursal_destino_id = p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso requiere sucursal_destino_id diferente a sucursal_id';
            END IF;
            IF NOT EXISTS (SELECT 1 FROM sucursales WHERE sucursal_id = p_sucursal_destino_id AND estado_id = 1000) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal destino % no existe o no est? ACTIVA', p_sucursal_destino_id;
            END IF;
        END IF;

        -- INGRESO_TRASPASO (1054) - OBS. 13: Debe empezar en EN_TRANSITO (2100)
        IF p_evento_id = 1054 THEN
            -- Validar que el estado sea EN_TRANSITO al crear
            IF p_estado_traspaso_id != 2100 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) debe crearse con estado_traspaso_id = 2100 (EN_TRANSITO)';
            END IF;

            -- Validar origen
            IF p_kardex_origen_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) requiere kardex_origen_id no nulo';
            END IF;

            SELECT evento_id, estado_id, sucursal_id
            INTO v_origen_evento_id, v_origen_estado_id, v_origen_sucursal_id
            FROM kardex
            WHERE kardex_id = p_kardex_origen_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % no existe', p_kardex_origen_id;
            END IF;

            IF v_origen_evento_id != 1053 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % debe ser EGRESO_TRASPASO (1053). Es %',
                    p_kardex_origen_id, v_origen_evento_id;
            END IF;

            IF v_origen_estado_id != 1000 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % debe estar ACTIVO (1000). Est? %',
                    p_kardex_origen_id, v_origen_estado_id;
            END IF;

            IF v_origen_sucursal_id = p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal origen % no puede ser igual a destino %',
                    v_origen_sucursal_id, p_sucursal_destino_id;
            END IF;

            IF (
                SELECT 1 FROM kardex
                WHERE kardex_origen_id = p_kardex_origen_id
                AND evento_id = 1054
                AND estado_id != 1001
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % ya vinculado a otro INGRESO_TRASPASO',
                    p_kardex_origen_id;
            END IF;
        END IF;

        -- EGRESO_TRASPASO (1053) NO debe tener origen
        IF p_evento_id = 1053 AND p_kardex_origen_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO (1053) no debe tener kardex_origen_id';
        END IF;

        -- ============================================================
        -- 1.10: VALIDACI?N DE DEVOLUCIONES (OBS. 11)
        -- ============================================================
        -- DEVOLUCION_CLIENTE (1060)
        IF p_evento_id = 1060 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una VENTA (1051)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1051 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una VENTA (1051). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar comprobante_referencia
            IF p_comprobante_referencia IS NULL OR TRIM(p_comprobante_referencia) = '' THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere comprobante_referencia no nulo';
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_venta < 0 OR p_total_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere totales >= 0';
            END IF;

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;
        END IF;

        -- DEVOLUCION_PROVEEDOR (1061)
        IF p_evento_id = 1061 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una COMPRA (1050)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1050 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una COMPRA (1050). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_compra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere total_compra >= 0';
            END IF;

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;
        END IF;

        -- OTROS EVENTOS: no deben tener kardex_referencia_id
        IF p_evento_id NOT IN (1060, 1061) AND p_kardex_referencia_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_referencia_id', p_evento_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO 2: VALIDACI?N PARA KARDEX_PRODUCTOS (DETALLE)
    ------------------------------------------------------------------
    ELSIF p_contexto = 'KARDEX_PRODUCTO' THEN
        -- 2.1: Obtener el evento_id y estado_id de la cabecera
        SELECT evento_id, estado_id INTO v_evento_id, v_estado_actual
        FROM kardex
        WHERE kardex_id = p_kardex_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Cabecera con ID % no existe', p_kardex_id;
        END IF;

        -- 2.2: No permitir modificar ANULADAS
        IF v_estado_actual = 1003 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: No se puede modificar transacci?n ANULADA (estado_id = 1003)';
        END IF;

        -- ============================================================
        -- 2.3: VALIDACI?N DE CANTIDADES POR EVENTO (OBS. 05)
        -- ============================================================
        -- INGRESO (1050, 1054, 1056, 1060, 1065, 1069)
        IF v_evento_id IN (1050, 1056, 1060, 1065, 1069) OR v_evento_id = 1054 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (INGRESO) requiere cantidad > 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- EGRESO (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
        ELSIF v_evento_id IN (1051, 1057, 1062, 1063, 1064, 1066, 1068) OR v_evento_id = 1053 OR v_evento_id = 1061 THEN
            -- 1061 (DEVOLUCION_PROVEEDOR) es egreso
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (EGRESO) requiere cantidad = 0 y cantidad_salida > 0', v_evento_id;
            END IF;

        -- PROFORMA (1052), SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id IN (1052, 1058) THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidad = 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA (1059) requiere cantidad = 0 y cantidad_salida > 0';
            END IF;

        -- MIXTOS (1055)
        ELSIF v_evento_id IN (1055) THEN
            IF p_cantidad < 0 OR p_cantidad_salida < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidades >= 0', v_evento_id;
            END IF;
            IF p_cantidad = 0 AND p_cantidad_salida = 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere al menos una cantidad > 0', v_evento_id;
            END IF;

        -- CONVERSION_UNIDADES (1067)
        ELSIF v_evento_id = 1067 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: CONVERSION_UNIDADES (1067) requiere cantidad > 0 y cantidad_salida > 0';
            END IF;

        -- Evento desconocido
        ELSE
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % no contemplado. Solo cantidades = 0', v_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.4: VALIDACI?N DE PRECIOS POR EVENTO (OBS. 11)
        -- ============================================================
        -- COMPRA (1050)
        IF v_evento_id = 1050 THEN
            IF p_pcompra <= 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: COMPRA (1050) requiere pcompra > 0 y precios venta = 0';
            END IF;

        -- VENTA (1051)
        ELSIF v_evento_id = 1051 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere precios > 0';
            END IF;

        -- TRASPASOS (1053, 1054) - OBS. 11: precios deben ser 0
        ELSIF v_evento_id IN (1053, 1054) THEN
            IF p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % requiere precio_venta = 0 y precio_venta_factura = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % no permite descuentos', v_evento_id;
            END IF;

        -- AJUSTES INTERNOS
        ELSIF v_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % requiere TODOS los precios = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % no permite descuentos', v_evento_id;
            END IF;

        -- PROFORMA (1052)
        ELSIF v_evento_id = 1052 THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA (1052) requiere TODOS los precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA no permite descuentos';
            END IF;

        -- SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id = 1058 THEN
            IF p_pcompra < 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA requiere pcompra >= 0 y dem?s precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA no permite descuentos';
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere precios > 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA no permite descuentos';
            END IF;

        -- DEVOLUCION_CLIENTE (1060)
        ELSIF v_evento_id = 1060 THEN
            IF p_precio_venta < 0 OR p_precio_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE requiere precios >= 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE no permite descuentos. Debe ser 0.00';
            END IF;

        -- DEVOLUCION_PROVEEDOR (1061)
        ELSIF v_evento_id = 1061 THEN
            IF p_pcompra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR requiere pcompra >= 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR no permite descuentos. Debe ser 0.00';
            END IF;

        -- ANULACION (1055)
        ELSIF v_evento_id = 1055 THEN
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: ANULACION no permite descuentos';
            END IF;
        END IF;

        -- ============================================================
        -- 2.5: VALIDACI?N DE TIPOS DE PAGO Y VENTA (OBS. 06 y 07)
        -- ============================================================
        -- Eventos NEUTRALES (incluye traspasos)
        IF v_evento_id IN (1052, 1053, 1054, 1055, 1056, 1057, 1058, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_pago_id = 1400', v_evento_id;
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_venta_id = 1350', v_evento_id;
            END IF;
        END IF;

        -- VENTA (1051): tipos definidos
        IF v_evento_id = 1051 THEN
            IF p_tipo_pago_id = 1400 OR p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere tipo_pago_id != 1400 y tipo_venta_id != 1350';
            END IF;
        END IF;

        -- VENTA_RESERVA (1059)
        IF v_evento_id = 1059 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_pago_id = 1400';
            END IF;
            IF p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_venta_id != 1350';
            END IF;
        END IF;

        -- DEVOLUCION_CLIENTE (1060) - OBS. 05
        IF v_evento_id = 1060 THEN
            IF p_tipo_pago_id <> 1406 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_pago_id = 1406 (SIN_PAGO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- DEVOLUCION_PROVEEDOR (1061) - OBS. 05
        IF v_evento_id = 1061 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_pago_id = 1400 (NINGUNO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- ============================================================
        -- 2.6: VALIDACI?N DE SUCURSAL_ID EN DETALLE (OBS. 10)
        -- ============================================================
        IF v_evento_id = 1053 THEN
            -- EGRESO_TRASPASO: sucursal del detalle debe ser la sucursal origen
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: EGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_id origen (%)',
                    p_sucursal_id;
            END IF;
        END IF;

        IF v_evento_id = 1054 THEN
            -- INGRESO_TRASPASO: sucursal del detalle debe ser la sucursal destino
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_destino_id (%)',
                    p_sucursal_destino_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.7: VALIDACI?N DE LOTE_ID (OBS. 09)
        -- ============================================================
        IF v_evento_id = 1054 AND p_kardex_origen_id IS NOT NULL THEN
            -- Obtener el lote del origen
            SELECT kp.lote_id INTO v_origen_lote_id
            FROM kardex_productos kp
            WHERE kp.kardex_id = p_kardex_origen_id
            LIMIT 1;

            IF v_origen_lote_id IS NOT NULL AND p_lote_id IS NOT NULL AND v_origen_lote_id != p_lote_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO debe usar el mismo lote que el origen (%). Lote destino: %',
                    v_origen_lote_id, p_lote_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.8: VALIDACI?N DE COSTO_VENTA (OBS. 16)
        -- ============================================================
        IF v_evento_id = 1054 THEN
            IF p_costo_venta IS NOT NULL AND p_costo_venta != 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO (1054) requiere costo_venta = 0. Recibido: %',
                    p_costo_venta;
            END IF;
        END IF;

        -- ============================================================
        -- 2.9: VALIDACI?N DE LOTE_ID Y MOTIVO PARA DEVOLUCIONES (OBS. 01)
        -- ============================================================
        IF v_evento_id IN (1060, 1061) THEN
            -- Validar que el lote no sea el comod?n (1)
            IF p_lote_id IS NULL OR p_lote_id = 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devoluci?n (%) requiere un lote real (lote_id > 1). No puede usar el lote comod?n (1)',
                    v_evento_id;
            END IF;

            -- Validar que el lote exista y est? ACTIVO y VIGENTE
            IF NOT EXISTS (
                SELECT 1 FROM lotes_productos
                WHERE lote_id = p_lote_id
                AND estado_id = 1000
                AND estado_lote_id = 2500  -- VIGENTE
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: El lote % no existe, no est? ACTIVO o no est? VIGENTE',
                    p_lote_id;
            END IF;

            -- Validar motivo_devolucion_id para DEVOLUCIONES
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id NOT IN (3500, 3501, 3502, 3503, 3504, 3505, 3507, 3508) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devoluci?n (%) requiere motivo_devolucion_id v?lido (3500-3505, 3507, 3508). Recibido: %',
                    v_evento_id, p_motivo_devolucion_id;
            END IF;
        END IF;
    ------------------------------------------------------------------
    -- CONTEXTO 3: VALIDACI?N DE DOMINIOS PROTEGIDOS
    ------------------------------------------------------------------
    ELSIF p_contexto = 'DOMINIO' THEN
        SELECT es_protegido INTO v_es_protegido
        FROM dominios
        WHERE dominio_id = p_dominio_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % no existe', p_dominio_id;
        END IF;

        IF v_es_protegido = 1 THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % est? protegido (es_protegido = 1)', p_dominio_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO DESCONOCIDO
    ------------------------------------------------------------------
    ELSE
        RAISE EXCEPTION 'Regla de Negocio: Contexto desconocido: %. Contextos v?lidos: KARDEX, KARDEX_PRODUCTO, DOMINIO', p_contexto;
    END IF;
END;
$$ LANGUAGE plpgsql;