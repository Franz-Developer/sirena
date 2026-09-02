ACTÚA COMO UN DESARROLLADOR SENIOR BACKEND Y QA EXPERTO EN NESTJS, TYPESCRIPT Y TYPEORM.

Tu tarea es generar el archivo de pruebas o archivo de peticiones HTTP en formato REST Client (`[nombre-modulo].http`) para un módulo específico de la aplicación, basándote en la arquitectura sirena y tomando estrictamente como referencia el archivo de pruebas oficial provisto a continuación y sus patrones de diseño.

Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

---

### EJEMPLO DE REFERENCIA OFICIAL:

# ----------------------------------------------------------------------
# DEFINICIÓN DE VARIABLES
# ----------------------------------------------------------------------
@baseUrl = http://localhost:3010/api
@baseUrl_tipos_cambios = {{baseUrl}}/tipos-cambios
@baseUrl_cat = {{baseUrl}}/catalogos

### 1. OBTENER TOKEN DE AUTENTICACIÓN.
# Se debe presionar primero.
# @name login
POST {{baseUrl}}/auth/validar
Content-Type: application/json

{
    "username": "ADMIN",
    "password": "12345678"
}

### 2. GUARDAR TOKEN EN VARIABLE.
# No se debe presionar es automático.
@authToken = {{login.response.body.token}}

# ----------------------------------------------------------------------
# ENDPOINTS EXTRAS (DOMINIOS / CATALOGOS)
# ----------------------------------------------------------------------
GET {{baseUrl_cat}}/dominios/EstadoID
Authorization: Bearer {{authToken}}

# ----------------------------------------------------------------------
# ENDPOINTS DEL MÓDULO
# ----------------------------------------------------------------------

### a. LISTAR TODOS LOS REGISTROS (Activos e Históricos por defecto)
GET {{baseUrl_tipos_cambios}}
Authorization: Bearer {{authToken}}

### b. LISTAR FILTRADOS POR ESTADO (Activos: 1000, Históricos: 1002, Borrados: 1001)
GET {{baseUrl_tipos_cambios}}?estado_id=1000
Authorization: Bearer {{authToken}}

### c. FILTRAR POR PARÁMETROS ESPECÍFICOS DEL DTO DE BÚSQUEDA
GET {{baseUrl_tipos_cambios}}?estado_id=1000&fecha_registro_inicio=2026-01-01
Authorization: Bearer {{authToken}}

### d. BÚSQUEDA GLOBAL POR TEXTO (Query `q`)
GET {{baseUrl_tipos_cambios}}?estado_id=1000&q=VALOR_BUSQUEDA
Authorization: Bearer {{authToken}}

### e. LISTAR CON PAGINACIÓN Y ORDENAMIENTO
GET {{baseUrl_tipos_cambios}}?estado_id=1000&offset=0&limit=5&sortField=fecha_registro&sortOrder=-1
Authorization: Bearer {{authToken}}

### f. OBTENER UN REGISTRO POR ID
GET {{baseUrl_tipos_cambios}}/2
Authorization: Bearer {{authToken}}

### g. CREAR UN NUEVO REGISTRO
POST {{baseUrl_tipos_cambios}}
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "campo_ejemplo": "Valor de prueba",
    "estado_id": 1000
}

### h. ACTUALIZAR UN REGISTRO
PATCH {{baseUrl_tipos_cambios}}/2
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "campo_ejemplo": "Valor actualizado"
}

### i. ARCHIVAR UN REGISTRO (Cambiar a estado HISTÓRICO)
PATCH {{baseUrl_tipos_cambios}}/2/archivar
Authorization: Bearer {{authToken}}

### j. DESARCHIVAR UN REGISTRO (Cambiar a estado ACTIVO)
PATCH {{baseUrl_tipos_cambios}}/2/desarchivar
Authorization: Bearer {{authToken}}

### k. ELIMINAR UN REGISTRO (Cambiar a estado BORRADO lógicamente)
DELETE {{baseUrl_tipos_cambios}}/2
Authorization: Bearer {{authToken}}

---

### REGLAS OBLIGATORIAS PARA GENERAR EL ARCHIVO `.http`:

1. **Estructura Base y Variables:**
   - Mantener la sección inicial de variables (`@baseUrl`, `@baseUrl_[modulo]`, `@baseUrl_cat`) y el bloque funcional de autenticación con `@name login` y `@authToken = {{login.response.body.token}}`.
2. **Pruebas Equilibradas y No Saturadas:**
   - No generar una cantidad excesiva de peticiones repetitivas. Incluir exactamente:
     - 1 petición para listar por defecto.
     - 3 variaciones clave de filtrado basadas en los campos definidos en el DTO de búsqueda (`find-[nombre-modulo]-query.dto.ts` adaptadas al módulo).
     - 1 petición de búsqueda global (`q`).
     - 1 petición de paginación con ordenamiento (`offset`, `limit`, `sortField`, `sortOrder`).
     - 1 petición `GET` por ID.
     - 1 petición `POST` para crear con un payload completo y válido.
     - 1 petición `PATCH` para actualizar campos específicos.
     - 1 petición `PATCH` para archivar.
     - 1 petición `PATCH` para desarchivar.
     - 1 petición `DELETE` para baja lógica.
3. **Formato REST Client:**
   - Cada endpoint debe estar debidamente separado por tres hashes (`###`) acompañados de un comentario descriptivo y claro.
   - Incluir la cabecera `Authorization: Bearer {{authToken}}` en todas las peticiones protegidas.
   - Usar `Content-Type: application/json` exclusivamente en los métodos `POST` y `PATCH` que requieran cuerpo JSON.
