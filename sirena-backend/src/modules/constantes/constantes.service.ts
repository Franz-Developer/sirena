// C:\sirena\sirena-backend\src\modules\constantes\constantes.service.ts
import { Injectable, HttpStatus, Logger } from '@nestjs/common';
import {
    ESTADO_METADATA,
    TIPO_MONEDA_METADATA,
    GENERO_METADATA,
    ESTADO_CIVIL_MASCULINO_METADATA,
    ESTADO_CIVIL_FEMENINO_METADATA,
    TIPO_CLIENTE_METADATA,
    TIPO_PAGO_METADATA,
    TIPO_VENTA_METADATA,
    TIPO_DOCUMENTO_METADATA,
    EVENTO_METADATA,
    TIPO_ALMACEN_METADATA,
    TIPOS_ALMACEN_VENTA_DIRECTA_METADATA,
    TIPOS_ALMACEN_LOGISTICA_INTERNA_METADATA,
    TIPO_CUENTA_METADATA,
    TIPO_COMPROBANTE_METADATA,
    FRAMEWORK_METADATA,
    TIPO_MODELO_METADATA,
    TIPO_TAREA_METADATA,
    SUBTIPO_TAREA_METADATA,
    FRECUENCIA_METADATA,
    NIVEL_LOG_METADATA,
    CALIDAD_RATING_METADATA,
    TIPO_MOVIMIENTO_METADATA,
    ESTADO_CAJA_METADATA,
    ESTADO_PAGO_METADATA,
    ESTADO_LOTE_METADATA,
    TIPO_BENEFICIO_METADATA,
    TIPO_PUNTO_VENTA_METADATA,
    MODALIDAD_FACTURACION_METADATA,
    TIPO_RECETA_METADATA,
    GRADO_EQUIVALENCIA_METADATA,
    METODO_CALCULO_METADATA,
    FACTOR_ESTACIONALIDAD_METADATA,
    TIPO_DESPACHO_METADATA,
    MOTIVO_DEVOLUCION_METADATA,
    MOTIVO_ANULACION_METADATA,
    ESTADO_FINANCIERO_METADATA,
    ESTADO_PEDIDO_METADATA,
    ESTADO_TRASPASO_METADATA,
    MODULO_ESTRATEGICO_METADATA,
    ESTADO_ALERTA_METADATA,
    NIVEL_CRITICO_METADATA,
    ORIGEN_ALERTA_METADATA,
    SUBTIPO_ALERTA_METADATA,
    TIPO_ALERTA_NOTIFICACION_METADATA,
    AMBIENTE_METADATA,
    TIPO_APLICACION_METADATA,
    TIPO_ASISTENCIA_METADATA,
    ESTADO_ASISTENCIA_METADATA,
    METODO_MARCACION_METADATA,
    TIPO_ALERTA_RRHH_METADATA,
    TIPO_PLANILLA_METADATA,
    ESTADO_PLANILLA_METADATA,
    ESTADO_CONTRATO_METADATA,
    TIPO_CONTRATO_METADATA,
    TIPO_JORNADA_METADATA,
    TIPO_BILLETE_MONEDA_METADATA,
    ESTADO_DOCUMENTO_METADATA,
    ESTADO_PROFORMA_METADATA,
    TIPO_OPERACION_ALMACEN_METADATA,
    ENTIDAD_AFECTADA_METADATA,
    CRITICIDAD_MEDICA_METADATA,
    TIPO_PATRON_METADATA,
    FUENTE_EXOGENA_METADATA,
    ESTADO_MODELO_METADATA,
    ESTADO_PRONOSTICO_METADATA,
    TEMPORADA_METADATA,
    ESTADO_FISCAL_METADATA,
    NIVEL_URGENCIA_METADATA,
    MOTIVO_OUTLIER_METADATA,
    FORMATO_PDF_METADATA,
    METRICA_PRECISION_METADATA,
    ESTADO_EJECUCION_METADATA,
    TIPO_METRICA_METADATA,
    TIPO_UBICACION_MOVIMIENTO_METADATA,
    TIPO_UMBRAL_METADATA,
    TIPO_DATO_METADATA,
    ESTADO_PEDIDO_ONLINE_METADATA,
    ESTADO_RESERVA_METADATA,
    ESTADO_CARRITO_METADATA,
} from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { FindConstantesQueryDto } from './dto/find-constantes-query.dto';
import { obtenerTodosLosTiposUbicacion } from '../../common/constants/ubicaciones.constants';

@Injectable()
export class ConstantesService {
    readonly logger = new Logger(ConstantesService.name);

    constructor(
        private readonly tablaValidador: TablaValidadorService,
    ) {}

    private readonly constantesMap: Record<string, Record<number, any>> = {
        estado_id: ESTADO_METADATA,
        tipo_moneda_id: TIPO_MONEDA_METADATA,
        genero_id: GENERO_METADATA,
        estado_civil_masculino_id: ESTADO_CIVIL_MASCULINO_METADATA,
        estado_civil_femenino_id: ESTADO_CIVIL_FEMENINO_METADATA,
        tipo_cliente_id: TIPO_CLIENTE_METADATA,
        tipo_pago_id: TIPO_PAGO_METADATA,
        tipo_venta_id: TIPO_VENTA_METADATA,
        tipo_documento_id: TIPO_DOCUMENTO_METADATA,
        evento_id: EVENTO_METADATA,
        tipo_almacen_id: TIPO_ALMACEN_METADATA,
        tipo_almacen_venta_directa_id: TIPOS_ALMACEN_VENTA_DIRECTA_METADATA,
        tipo_almacen_logistica_interna_id: TIPOS_ALMACEN_LOGISTICA_INTERNA_METADATA,
        tipo_cuenta_id: TIPO_CUENTA_METADATA,
        tipo_comprobante_id: TIPO_COMPROBANTE_METADATA,
        framework_id: FRAMEWORK_METADATA,
        tipo_modelo_id: TIPO_MODELO_METADATA,
        tipo_tarea_id: TIPO_TAREA_METADATA,
        subtipo_tarea_id: SUBTIPO_TAREA_METADATA,
        frecuencia_id: FRECUENCIA_METADATA,
        nivel_log_id: NIVEL_LOG_METADATA,
        calidad_rating_id: CALIDAD_RATING_METADATA,
        tipo_movimiento_id: TIPO_MOVIMIENTO_METADATA,
        estado_caja_id: ESTADO_CAJA_METADATA,
        estado_pago_id: ESTADO_PAGO_METADATA,
        estado_lote_id: ESTADO_LOTE_METADATA,
        tipo_beneficio_id: TIPO_BENEFICIO_METADATA,
        tipo_punto_venta_id: TIPO_PUNTO_VENTA_METADATA,
        modalidad_facturacion_id: MODALIDAD_FACTURACION_METADATA,
        tipo_receta_id: TIPO_RECETA_METADATA,
        grado_equivalencia_id: GRADO_EQUIVALENCIA_METADATA,
        metodo_calculo_id: METODO_CALCULO_METADATA,
        factor_estacionalidad_id: FACTOR_ESTACIONALIDAD_METADATA,
        tipo_despacho_id: TIPO_DESPACHO_METADATA,
        motivo_devolucion_id: MOTIVO_DEVOLUCION_METADATA,
        motivo_anulacion_id: MOTIVO_ANULACION_METADATA,
        estado_financiero_id: ESTADO_FINANCIERO_METADATA,
        estado_pedido_id: ESTADO_PEDIDO_METADATA,
        estado_traspaso_id: ESTADO_TRASPASO_METADATA,
        modulo_estrategico_id: MODULO_ESTRATEGICO_METADATA,
        estado_alerta_id: ESTADO_ALERTA_METADATA,
        nivel_critico_id: NIVEL_CRITICO_METADATA,
        origen_alerta_id: ORIGEN_ALERTA_METADATA,
        subtipo_alerta_id: SUBTIPO_ALERTA_METADATA,
        tipo_alerta_notificacion_id: TIPO_ALERTA_NOTIFICACION_METADATA,
        ambiente_id: AMBIENTE_METADATA,
        tipo_aplicacion_id: TIPO_APLICACION_METADATA,
        tipo_asistencia_id: TIPO_ASISTENCIA_METADATA,
        estado_asistencia_id: ESTADO_ASISTENCIA_METADATA,
        metodo_marcacion_id: METODO_MARCACION_METADATA,
        tipo_alerta_rrhh_id: TIPO_ALERTA_RRHH_METADATA,
        tipo_planilla_id: TIPO_PLANILLA_METADATA,
        estado_planilla_id: ESTADO_PLANILLA_METADATA,
        estado_contrato_id: ESTADO_CONTRATO_METADATA,
        tipo_contrato_id: TIPO_CONTRATO_METADATA,
        tipo_jornada_id: TIPO_JORNADA_METADATA,
        tipo_billete_id: TIPO_BILLETE_MONEDA_METADATA,
        estado_documento_id: ESTADO_DOCUMENTO_METADATA,
        estado_proforma_id: ESTADO_PROFORMA_METADATA,
        tipo_operacion_almacen_id: TIPO_OPERACION_ALMACEN_METADATA,
        entidad_afectada_id: ENTIDAD_AFECTADA_METADATA,
        criticidad_medica_id: CRITICIDAD_MEDICA_METADATA,
        tipo_patron_id: TIPO_PATRON_METADATA,
        fuente_exogena_id: FUENTE_EXOGENA_METADATA,
        estado_modelo_id: ESTADO_MODELO_METADATA,
        estado_pronostico_id: ESTADO_PRONOSTICO_METADATA,
        temporada_id: TEMPORADA_METADATA,
        estado_fiscal_id: ESTADO_FISCAL_METADATA,
        nivel_urgencia_id: NIVEL_URGENCIA_METADATA,
        motivo_outlier_id: MOTIVO_OUTLIER_METADATA,
        formato_pdf_id: FORMATO_PDF_METADATA,
        metrica_precision_id: METRICA_PRECISION_METADATA,
        estado_ejecucion_id: ESTADO_EJECUCION_METADATA,
        tipo_metrica_id: TIPO_METRICA_METADATA,
        tipo_ubicacion_movimiento_id: TIPO_UBICACION_MOVIMIENTO_METADATA,
        tipo_umbral_id: TIPO_UMBRAL_METADATA,
        tipo_dato_id: TIPO_DATO_METADATA,
        estado_pedido_online_id: ESTADO_PEDIDO_ONLINE_METADATA,
        estado_reserva_id: ESTADO_RESERVA_METADATA,
        estado_carrito_id: ESTADO_CARRITO_METADATA,
    };

    async findAll(queryDto: FindConstantesQueryDto, usuarioId: number): Promise<PaginatedResult<any>> {
        await this.tablaValidador.validarPermisoTabla(usuarioId, 'constantes', 'leer');

        try {
            if (queryDto.tipo && !this.constantesMap[queryDto.tipo]) {
                throw new DomainException(
                    `El tipo de constante '${queryDto.tipo}' no es válido.`,
                    {
                        tipoIngresado: queryDto.tipo,
                        tiposDisponibles: Object.keys(this.constantesMap).sort(),
                        httpStatus: HttpStatus.BAD_REQUEST
                    }
                );
            }

            if (queryDto.tipo && queryDto.id !== undefined) {
                const metadata = this.constantesMap[queryDto.tipo];
                if (metadata && !metadata[queryDto.id]) {
                    throw new DomainException(
                        `El ID ${queryDto.id} no existe en el tipo de constante '${queryDto.tipo}'.`,
                        {
                            tipo: queryDto.tipo,
                            id: queryDto.id,
                            httpStatus: HttpStatus.BAD_REQUEST
                        }
                    );
                }
            }

            let allData: any[] = [];
            const tipos = queryDto.tipo ? [queryDto.tipo] : Object.keys(this.constantesMap);

            for (const tipo of tipos) {
                const metadata = this.constantesMap[tipo];
                if (metadata) {
                    const items = Object.values(metadata).map((item: any) => ({
                        id: item.id,
                        abreviatura: item.abreviatura,
                        descripcion: item.descripcion,
                        prefijo: item.prefijo,
                        valor: item.valor,
                        tipo: tipo,
                        es_defecto: item.es_defecto ?? false,
                    }));
                    allData = [...allData, ...items];
                }
            }

            if (queryDto.id !== undefined) {
                allData = allData.filter(item => item.id === queryDto.id);
            }

            if (queryDto.q?.trim()) {
                const searchTerm = queryDto.q.trim().toLowerCase();
                allData = allData.filter(item =>
                    item.abreviatura?.toLowerCase().includes(searchTerm) ||
                    item.descripcion?.toLowerCase().includes(searchTerm)
                );
            }

            const sortField = queryDto.getValidatedSortField();
            const sortOrder = queryDto.getSortOrder();
            allData.sort((a, b) => {
                const valA = a[sortField] ?? '';
                const valB = b[sortField] ?? '';
                if (valA < valB) return sortOrder === 1 ? -1 : 1;
                if (valA > valB) return sortOrder === 1 ? 1 : -1;
                return 0;
            });

            const total = allData.length;
            const offset = queryDto.getOffset();
            const limit = queryDto.getLimit();
            const data = allData.slice(offset, offset + limit);

            return {
                data,
                total,
                limit,
                offset,
            };
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
            throw error;
        }
    }

    async getTipos(): Promise<{ tipos: string[]; total: number }> {
        const tipos = Object.keys(this.constantesMap);
        return {
            tipos,
            total: tipos.length,
        };
    }

    private mapConstantes(metadata: Record<number, any>, tipo: string): any[] {
        return Object.values(metadata).map((item: any) => ({
            id: item.id,
            abreviatura: item.abreviatura,
            descripcion: item.descripcion,
            prefijo: item.prefijo,
            valor: item.valor,
            tipo: tipo,
        }));
    }

    async getEstados(): Promise<any[]> {
        return this.mapConstantes(ESTADO_METADATA, 'estado_id');
    }

    async getMonedas(): Promise<any[]> {
        return this.mapConstantes(TIPO_MONEDA_METADATA, 'moneda_id');
    }

    async getGeneros(): Promise<any[]> {
        return this.mapConstantes(GENERO_METADATA, 'genero_id');
    }

    async getTiposPago(): Promise<any[]> {
        return this.mapConstantes(TIPO_PAGO_METADATA, 'tipo_pago_id');
    }

    async getTiposVenta(): Promise<any[]> {
        return this.mapConstantes(TIPO_VENTA_METADATA, 'tipo_venta_id');
    }

    async getTiposDocumento(): Promise<any[]> {
        return this.mapConstantes(TIPO_DOCUMENTO_METADATA, 'tipo_documento_id');
    }

    async getEventos(): Promise<any[]> {
        return this.mapConstantes(EVENTO_METADATA, 'evento_id');
    }

    /**
     * UBICACIONES
     */
    async getTiposUbicacion(): Promise<any[]> {
        return obtenerTodosLosTiposUbicacion().map(meta => ({
            id: meta.tipo,
            tipo: meta.tipo,
            codigo: meta.codigo,
            descripcion: meta.descripcion,
            config: {
                tipoSecuencia: meta.config.tipoSecuencia,
                prefijo: meta.config.prefijo || null,
                longitudMinima: meta.config.longitudMinima || null,
                maxCombinaciones: meta.config.maxCombinaciones || null,
            }
        }));
    }
}
