### ACTUALIZAR TODOS LOS CAMPOS
PATCH {{baseUrl_bancos}}/3
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "banco": "BANCO MERCANTIL BOLIVIANO S.A",
    "abreviatura": "BMB",
    "descripcion": "Hola mundo a todos, como"
}
SALE 
{
  "banco_id": "3",
  "banco": "BANCO MERCANTIL SANTA CRUZ S.A.",
  "codigo_asfi": "02",
  "abreviatura": "BMSC",
  "descripcion": "Hola mundo a todos, como",
  "estado_id": 1000,
  "estado_registro": "ACTIVO",
  "usuario_operacion": "GLADYS",
  "usuario_id_registro": "2",
  "usuario_id_actualizacion": "4",
  "usuario_id_baja": null,
  "fecha_registro": "2026-09-05 00:42:53.022 -04:00",
  "fecha_actualizacion": "2026-09-05 13:06:34.291 -04:00",
  "fecha_baja": null,
  "tiene_dependencias": true,
  "campos_protegidos": [
    "banco",
    "codigo_asfi",
    "abreviatura"
  ]
}
