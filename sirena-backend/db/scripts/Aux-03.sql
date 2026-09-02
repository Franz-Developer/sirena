# C:\sirena\sirena-backend\src\modules\ubicaciones\ubicaciones.http
# ----------------------------------------------------------------------
# DEFINICIÓN DE VARIABLES
# ----------------------------------------------------------------------
@baseUrl = http://localhost:3010/api
@baseUrl_ubicaciones = {{baseUrl}}/ubicaciones
@baseUrl_almacenes = {{baseUrl}}/almacenes
@baseUrl_constantes = {{baseUrl}}/constantes
@rest-client.previewOption = body

### 1. OBTENER TOKEN DE AUTENTICACIÓN
# @name login
POST {{baseUrl}}/auth/validar
Content-Type: application/json

{
    "username": "ADMIN",
    "password": "12345678"
}

### 2. GUARDAR TOKEN EN VARIABLE
@authToken = {{login.response.body.token}}

# ==============================================================================
# ENDPOINTS EXTRAS
# ==============================================================================

### Listar almacenes activos
GET {{baseUrl_almacenes}}?sucursal_id=3&estado_id=1000
Authorization: Bearer {{authToken}}

### Listar tipos de ubicación disponibles
GET {{baseUrl_constantes}}/tipos-ubicacion
Authorization: Bearer {{authToken}}

# ==============================================================================
# 1. CREAR UBICACIONES (POST)
# ==============================================================================


# ==============================================================================
# 2. LISTAR UBICACIONES (GET)
# ==============================================================================

### 2.1 Listar todas por almacén (Activos + Históricos)
GET {{baseUrl_ubicaciones}}?almacen_id=4
Authorization: Bearer {{authToken}}

### 2.2 Listar por almacén y estado activo (1000)
GET {{baseUrl_ubicaciones}}?almacen_id=4&estado_id=1000
Authorization: Bearer {{authToken}}

### 2.3 Listar por almacén y estado histórico (1002)
GET {{baseUrl_ubicaciones}}?almacen_id=4&estado_id=1002
Authorization: Bearer {{authToken}}

### 2.4 Búsqueda flexible por código
GET {{baseUrl_ubicaciones}}?almacen_id=4&q=EST
Authorization: Bearer {{authToken}}

### 2.5 Búsqueda exacta por código
GET {{baseUrl_ubicaciones}}?almacen_id=4&q=EST-02-1&exactMatch=1
Authorization: Bearer {{authToken}}

### 2.6 Paginación: primeros 5 registros
GET {{baseUrl_ubicaciones}}?almacen_id=4&offset=0&limit=5
Authorization: Bearer {{authToken}}

### 2.7 Ordenar por código ascendente
GET {{baseUrl_ubicaciones}}?almacen_id=4&sortField=codigo&sortOrder=1
Authorization: Bearer {{authToken}}

### 2.8 Ordenar por código descendente
GET {{baseUrl_ubicaciones}}?almacen_id=4&sortField=codigo&sortOrder=-1
Authorization: Bearer {{authToken}}

# ==============================================================================
# 3. OBTENER UNA UBICACIÓN POR ID (GET)
# ==============================================================================

### 3.1 Obtener ubicación específica por ID
GET {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}

### 3.2 Obtener ubicación comodín (ID = 1)
GET {{baseUrl_ubicaciones}}/1
Authorization: Bearer {{authToken}}

# ==============================================================================
# 4. ACTUALIZAR UBICACIÓN (PATCH)
# ==============================================================================

### 4.1 Actualizar solo la descripción
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "descripcion": "ESTANTERIA ACTUALIZADA - MEDICAMENTOS GENERICOS"
}

### 4.2 Mover ubicación a otro almacén (si no tiene dependencias)
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 5,
    "descripcion": "MOVIDA A NUEVO ALMACEN - SECCION A"
}

### 4.3 Actualizar solo el almacén (manteniendo descripción)
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 6
}

### 4.4 Intento de actualizar campo no editable (tipo) - Debe fallar
# ❌ tipo NO se puede modificar (define la estructura física)
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "tipo": "REFRIGERADOR"
}

# ==============================================================================
# 5. ARCHIVAR / DESARCHIVAR (PATCH)
# ==============================================================================

### 5.1 Archivar ubicación (pasar a HISTORICO - estado 1002)
# ⚠️ Solo si NO tiene dependencias activas
PATCH {{baseUrl_ubicaciones}}/43/archivar
Authorization: Bearer {{authToken}}

### 5.2 Verificar que quedó archivada (estado_id=1002)
GET {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}

### 5.3 Desarchivar ubicación (pasar a ACTIVO - estado 1000)
PATCH {{baseUrl_ubicaciones}}/43/desarchivar
Authorization: Bearer {{authToken}}

### 5.4 Verificar que quedó activa (estado_id=1000)
GET {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}

# ==============================================================================
# 6. ELIMINAR UBICACIÓN (DELETE - Borrado Lógico)
# ==============================================================================

### 6.1 Eliminar ubicación (borrado lógico - estado BORRADO=1001)
# ⚠️ Solo si NO tiene dependencias activas
# ⚠️ Registro comodín (ID=1) NO se puede eliminar
DELETE {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}

### 6.2 Verificar que quedó eliminada (estado_id=1001)
GET {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}

### 6.3 Intentar eliminar registro comodín (ID=1) - Debe fallar
DELETE {{baseUrl_ubicaciones}}/1
Authorization: Bearer {{authToken}}

# ==============================================================================
# 7. CASOS DE ERROR (Pruebas negativas)
# ==============================================================================

### 7.1 Crear ubicación en almacén inexistente - Debe fallar
POST {{baseUrl_ubicaciones}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 999,
    "tipo": "ESTANTERIA"
}

### 7.2 Crear ubicación con tipo inválido - Debe fallar
POST {{baseUrl_ubicaciones}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 4,
    "tipo": "TIPO_INVALIDO"
}

### 7.3 Crear más de 50 niveles - Debe fallar
POST {{baseUrl_ubicaciones}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 4,
    "tipo": "ESTANTERIA",
    "niveles": 51
}

### 7.4 Actualizar ubicación archivada - Debe fallar
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "descripcion": "INTENTO DE ACTUALIZAR ARCHIVADO"
}

### 7.5 Eliminar ubicación con dependencias - Debe fallar
# (Si tiene productos_ubicaciones o lotes_productos asociados)
DELETE {{baseUrl_ubicaciones}}/2
Authorization: Bearer {{authToken}}

# ==============================================================================
# 8. FLUJO COMPLETO (Escenario real)
# ==============================================================================

### 8.1 Crear una nueva estantería con 4 niveles
POST {{baseUrl_ubicaciones}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "almacen_id": 4,
    "tipo": "ESTANTERIA",
    "niveles": 4,
    "descripcion": "ESTANTERIA NUEVA - SECCION B"
}

### 8.2 Listar las ubicaciones creadas
GET {{baseUrl_ubicaciones}}?almacen_id=4&q=ESTANTERIA NUEVA
Authorization: Bearer {{authToken}}

### 8.3 Actualizar la descripción de la primera ubicación
PATCH {{baseUrl_ubicaciones}}/43
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "descripcion": "ESTANTERIA NUEVA - SECCION B - NIVEL 1 (ACTUALIZADA)"
}

### 8.4 Archivar la última ubicación
PATCH {{baseUrl_ubicaciones}}/46/archivar
Authorization: Bearer {{authToken}}

### 8.5 Verificar que la ubicación está archivada
GET {{baseUrl_ubicaciones}}/46
Authorization: Bearer {{authToken}}

### 8.6 Desarchivar la ubicación
PATCH {{baseUrl_ubicaciones}}/46/desarchivar
Authorization: Bearer {{authToken}}

### 8.7 Eliminar la ubicación (si no tiene dependencias)
DELETE {{baseUrl_ubicaciones}}/46
Authorization: Bearer {{authToken}}