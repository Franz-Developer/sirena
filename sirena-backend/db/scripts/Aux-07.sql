LISTA DE ERRORES

almacenes.service.ts

    ERROR No. 1

        Archivo: almacenes.service.ts

        Función: validarCombinacionTipoAlmacen

        Explicación: Lógica de validación invertida. La regla de negocio R.2 de la tabla almacenes y la restricción chk_almacenes_tipoalmacenid en el DDL indican que LOGISTICA_INTERNA (4050) solo permite TIPO_ALMACEN_PROHIBIDOS y VENTA_DIRECTA (4051) solo permite TIPO_ALMACEN_VALIDOS. El código actual tiene esta lógica al revés, lo que permitiría crear almacenes de tránsito para venta directa y almacenes normales para logística interna, violando la restricción de la base de datos y las reglas de negocio.

    ERROR No. 2

        Archivo: almacenes.service.ts

        Función: create y update

        Explicación: No se valida que el codigo del almacén cumpla con el formato de mayúsculas y el patrón definido en la base de datos (^[A-Z0-9_-]+$). La entidad y el DTO tienen validaciones, pero el servicio no fuerza la conversión a mayúsculas (toUpperCase()) antes de la inserción o actualización. Si el DTO no lo hace, la base de datos rechazará la operación con un error inesperado.

    ERROR No. 3

        Archivo: almacenes.service.ts

        Función: create y update

        Explicación: No se valida el tipo_operacion_almacen_id para los almacenes existentes o nuevos. Si el campo tipo_operacion_almacen_id se actualiza para un almacén que ya tiene relaciones en almacenes_puntos_venta, la lógica de negocio R.G.5 indica que debe invalidarse, pero no se valida.

create-almacen.dto.ts

    ERROR No. 4

        Archivo: create-almacen.dto.ts

        Función: codigo

        Explicación: El DTO aplica transform para convertir el valor a mayúsculas, pero la validación @Matches(/^[A-Z0-9_-]+$/) es correcta. El servicio aún debería forzar esto como medida de seguridad adicional.

    ERROR No. 5

        Archivo: create-almacen.dto.ts

        Función: almacen

        Explicación: El campo almacen tiene @IsSafeText() y @MaxLength(200). La base de datos tiene VARCHAR(200) NOT NULL. La validación es correcta.

almacen-response.dto.ts

    ERROR No. 6

        Archivo: almacen-response.dto.ts

        Función: transformTipoAlmacen, transformTipoOperacionAlmacen

        Explicación: Los transformadores para tipo_almacen y tipo_operacion_almacen devuelven un objeto con abreviatura, valor, y prefijo. El DDL define tipo_almacen_id y tipo_operacion_almacen_id como SMALLINT. No hay un prefijo en la tabla, por lo que este campo puede ser superfluo o malinterpretado.

    ERROR No. 7

        Archivo: almacen-response.dto.ts

        Función: transformEstado

        Explicación: El transformador usa ESTADO_METADATA para obtener la abreviatura del estado. ESTADO_METADATA define es_defecto como una propiedad adicional. No hay problema con esto, es correcto.