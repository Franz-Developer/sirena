Todos los archivos generados deben estar separados debe ir estrictamente dentro de las comillas invertidas de Markdown o backticks. Cada import debe ser una sola fila.

# C:\sirena\sirena-backend\src\modules\menus\menus.http
# ----------------------------------------------------------------------
# DEFINICIÓN DE VARIABLES
# ----------------------------------------------------------------------
@baseUrl = http://localhost:3010/api
@baseUrl_menus = {{baseUrl}}/menus
@rest-client.previewOption = body

### 1. OBTENER TOKEN DE AUTENTICACIÓN.
# @name login
POST {{baseUrl}}/auth/validar
Content-Type: application/json

{
    "username": "ADMIN",
    "password": "12345678"
}

### 2. GUARDAR TOKEN EN VARIABLE.
@authToken = {{login.response.body.token}}

# ==============================================================================
# AUTENTICACIÓN - USUARIO 3
# ==============================================================================

### 1.b OBTENER TOKEN USUARIO 3
# @name loginUser3
POST {{baseUrl}}/auth/validar
Content-Type: application/json

{
    "username": "GLADYS",
    "password": "12345678"
}

### 2.b GUARDAR TOKEN USUARIO 3
# @authToken = {{loginUser3.response.body.token}}

# ==============================================================================
# LISTAR MENÚS (GET)
# ==============================================================================

### LISTAR TODOS (Activos + Históricos por defecto)
GET {{baseUrl_menus}}
Authorization: Bearer {{authToken}}

### b. LISTAR POR ESTADO ACTIVOS (1000)
GET {{baseUrl_menus}}?estado_id=1000
Authorization: Bearer {{authToken}}

### HISTÓRICOS (1002)
GET {{baseUrl_menus}}?estado_id=1002
Authorization: Bearer {{authToken}}

# ==============================================================================
# BÚSQUEDA POR TEXTO (q)
# ==============================================================================

### BÚSQUEDA FLEXIBLE POR TÍTULO
GET {{baseUrl_menus}}?q=CONFIGURACIÓN
Authorization: Bearer {{authToken}}

### Búsqueda por coincidencia exacta
GET {{baseUrl_menus}}?q=DATOS DE LA EMPRESA&exactMatch=1
Authorization: Bearer {{authToken}}

# ==============================================================================
# PAGINACIÓN
# ==============================================================================

### PÁGINA 1: Registros 0 al 15
GET {{baseUrl_menus}}?offset=0&limit=16
Authorization: Bearer {{authToken}}

### Paginación con filtro de estado
GET {{baseUrl_menus}}?estado_id=1000&offset=0&limit=5
Authorization: Bearer {{authToken}}

# ==============================================================================
# ORDENAMIENTO
# ==============================================================================

### ORDENAR POR TÍTULO (Ascendente)
GET {{baseUrl_menus}}?sortField=titulo&sortOrder=1
Authorization: Bearer {{authToken}}

### ORDENAR POR ID (Descendente)
GET {{baseUrl_menus}}?sortField=menu_id&sortOrder=-1
Authorization: Bearer {{authToken}}

# ==============================================================================
# OBTENER POR ID
# ==============================================================================

### OBTENER MENÚ POR ID
GET {{baseUrl_menus}}/3
Authorization: Bearer {{authToken}}

# ==============================================================================
# CRUD MENÚ
# ==============================================================================

### CREAR NUEVO MENÚ
POST {{baseUrl_menus}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "menu_padre_id": 2,
    "titulo": "AUDITORÍA DE SISTEMA",
    "icono": "pi pi-shield",
    "url": "/configuracion/auditoria",
    "orden": 6
}

### ACTUALIZAR MENÚ
PATCH {{baseUrl_menus}}/79
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "titulo": "AUDITORÍA GENERAL Y LOGS"
}

### ELIMINAR MENÚ (ACTIVO → BORRADO)
DELETE {{baseUrl_menus}}/79
Authorization: Bearer {{authToken}}

# ==============================================================================
# ARCHIVAR / DESARCHIVAR (Cambio de estado)
# ==============================================================================

### ARCHIVAR MENÚ (ACTIVO → HISTÓRICO)
PATCH {{baseUrl_menus}}/78/archivar
Authorization: Bearer {{authToken}}

### DESARCHIVAR MENÚ (HISTÓRICO → ACTIVO)
PATCH {{baseUrl_menus}}/78/desarchivar
Authorization: Bearer {{authToken}}
