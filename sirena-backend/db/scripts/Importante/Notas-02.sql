-- ================================================================================================
-- FACTURACION.	

-- ================================================================================================
-- Datos maestros que debes guardar.

-- A. Empresa (Emisor).

empresa
--------
nit
razon_social
nombre_comercial
actividad_economica_principal
direccion
telefono
correo
modalidad_facturacion	-- 1=Electrónica en Línea 2=Computarizada en Línea  POR DEFECTO 1
codigo_ambiente			-- 1=Producción 2=Piloto/Pruebas
certificado_digital
fecha_vencimiento_certificado

NOTA.- 
Razón Social: Nombre legal, oficial y obligatorio ante el Estado (SEPREC, SIN). Se usa para contratos, impuestos y facturación. (Ej: Importadora Farmacéutica Santa Cruz S.R.L.)
Nombre Comercial: Nombre de fantasía o marca visible para el público (letrero, logo, marketing). (Ej: Farmacia El Inca)
En el SIAT: El SIN exige la Razón Social como responsable tributario; el Nombre Comercial solo va de apoyo visual en el ticket o PDF para que el cliente reconozca el local.

-- B. Sucursales. El SIN registra sucursales.

sucursal
---------
codigo_sucursal
nombre
direccion
telefono

Ejemplo:
0 = Casa Matriz
1 = Sucursal Equipetrol
2 = Sucursal Centro
3 = Sucursal Norte

Si tienes 3 sucursales:
Casa Matriz = 0
Sucursal A = 1
Sucursal B = 2
Sucursal C = 3

El código lo asigna el SIN.

-- C. Puntos de Venta. Cada sucursal puede tener varios puntos de venta.

punto_venta
-----------
codigo_sucursal
codigo_punto_venta
descripcion

Ejemplo:
Sucursal 0
0 = Punto principal
1 = Caja 1
2 = Caja 2

Sucursal 1
0 = Punto principal
1 = Caja farmacia
2 = Caja delivery

Importante: El código de punto de venta es independiente dentro de cada sucursal.

Por ejemplo:
Sucursal 1 -> Punto 0
Sucursal 2 -> Punto 0
Sucursal 3 -> Punto 0
es válido.

-- D. Catálogos importantes

Tipo documento cliente
1 = CI
2 = CEX
3 = Pasaporte
4 = Otro documento
5 = NIT

Método de pago
1 = Efectivo
2 = Tarjeta
3 = Cheque
4 = Vale
5 = Otros
6 = Sin pago
7 = Transferencia
8 = Depósito
9 = QR

Moneda
1 = BOB
2 = USD
3 = EUR
4 = UFV

Motivo anulación
1 = Factura mal emitida
2 = Error datos cliente
3 = Devolución
4 = Contingencia
5 = Operación no concretada

-- E. Productos. JSON válido para una farmacia.
Sin embargo el XML del SIN necesita además:

{
	"codigo_producto_sin": 123456,
	"codigo_producto": "PARA500",
	"descripcion": "Paracetamol 500 mg",
	"cantidad": 2,
	"unidad_medida": 58,
	"precio_unitario": 3.50,
	"sub_total": 7.00
}

Y en el sistema interno se puede guardar:

{
	"lote": "L2026001",
	"fecha_vencimiento": "2028-05-31",
	"registro_sanitario": "RS-123456",
	"laboratorio": "INTI",
	"concentracion": "500 mg"
}

Estos últimos no son obligatorios para el SIN.

-- F. Documento Sector
Para una farmacia normalmente: 1 = Factura Compra Venta
Se Debe verificar el catálogo vigente del SIAT porque el código de documento sector puede variar según la actividad económica autorizada.

-- G. Tabla Factura recomendada.

factura
---------
id
nit_emisor
codigo_sucursal
codigo_punto_venta
cuis
cufd
codigo_control_cufd
numero_factura
cuf
fecha_emision
cliente_nombre
cliente_documento
cliente_tipo_documento
metodo_pago
subtotal
descuento
total
codigo_documento_sector
xml_generado
xml_firmado
codigo_recepcion
estado_siat
qr
fecha_registro

-- ================================================================================================
-- Flujo real completo.

-- ================================================================================================
-- 1. Obtener CUIS. Código Único de Inicio de Sistemas.

Identifica:
Sucursal
Punto de Venta
Sistema

Se debe guardar:

cuis
------
codigo_sucursal
codigo_punto_venta
cuis
fecha_vigencia

Ejemplo:
CUIS = B7D8E6F9

Se obtiene mediante servicio web SIAT. No se genera localmente.

-- ================================================================================================
-- 2. Obtener CUFD. Código Único de Facturación Diaria.

Identifica:
Sucursal
Punto de Venta
Día

Se debe guardar:

cufd
------
codigo_sucursal
codigo_punto_venta
cufd
codigo_control
fecha_vigencia
fecha_inicio
fecha_fin

Ejemplo:

CUFD = EFD7A8B9C123456789ABCDE...
Código Control = 4A7B8C9D

El SIN devuelve ambos. No se generan localmente.

¿Qué es el Código de Control?
Aquí suele haber confusión.

Sistema antiguo Antes se usaba: 
Dosificación + Código de Control Generado con: Verhoeff + RC4 Ejemplo: A1-B2-C3-D4-E5

Sistema SIAT actual. NO se usa ese algoritmo.

El SIN entrega:
CUFD
Código Control
ya calculados. El sistema sólo los almacena.

-- ================================================================================================
-- 3. Crear factura. Número de Factura. Debe ser secuencial.

factura
---------
numero_factura

Ejemplo:

1
2
3
4
5
...

La secuencia es por:
Sucursal
Punto de Venta

-- ================================================================================================
-- 4. Generar CUF. El CUF sí debe generarlo tu sistema.

Está compuesto por:
NIT
FechaHora
Sucursal
Modalidad
TipoEmisión
TipoFacturaDocumentoAjuste
DocumentoSector
NúmeroFactura
PuntoVenta

y posteriormente: Módulo 11 + Código de Control del CUFD

Estructura oficial
NIT(13)
FechaHora(17)
Sucursal(4)
Modalidad(1)
TipoEmision(1)
TipoFactura(1)
TipoDocumentoSector(2)
NumeroFactura(10)
PuntoVenta(4)

Todo concatenado. Luego:
Módulo 11

Luego:
Base16

Finalmente:
+ Código Control del CUFD

Resultado:
CUF

Ejemplo: 7D4F1A6B8C9D01234567890ABCDE1234567890ABCDE

Los números entre paréntesis son la longitud fija que debe tener cada campo dentro de la cadena base del CUF.
No significan tipo de dato.

Significan:
NIT(13) Debe ocupar exactamente 13 posiciones.

Ejemplo:
NIT real: 1023456789 Tiene 10 dígitos.
Se completa con ceros a la izquierda: 0001023456789 Ahora tiene 13 posiciones.

FechaHora(17) Formato: AAAAMMDDHHMMSSmmm

Donde:
AAAA = año
MM   = mes
DD   = día
HH   = hora
MM   = minuto
SS   = segundo
mmm  = milisegundos

Ejemplo: 20260730101523123
Longitud: 17 caracteres

Sucursal(4) 
Si la sucursal es: 0 debe quedar: 0000
Si es: 3 queda: 0003

Modalidad(1) Un solo dígito.
Ejemplo: 1 = Electrónica en Línea queda: 1

TipoEmision(1)
Ejemplo: 
1 = Emisión Normal
2 = Contingencia
queda: 1

TipoFactura(1)
Ejemplo: 1 = Factura
queda: 1

DocumentoSector(2)
Ejemplo: 1
Debe quedar: 01
porque necesita 2 posiciones.

NumeroFactura(10)
Factura: 125 queda: 0000000125

PuntoVenta(4) Punto: 0 queda: 0000

Ejemplo completo
Supongamos:

NIT = 1023456789
Fecha = 2026-07-30 10:15:23.123
Sucursal = 0
Modalidad = 1
TipoEmision = 1
TipoFactura = 1
DocumentoSector = 1
NumeroFactura = 125
PuntoVenta = 0

Se convierten a longitud fija:

0001023456789
20260730101523123
0000
1
1
1
01
0000000125
0000

Concatenado:
00010234567892026073010152312300001110100000001250000

(Ejemplo ilustrativo)
¿Qué es Módulo 11? Es un algoritmo matemático para generar un dígito verificador.

Se usa para detectar errores.

Por ejemplo: 123456789 produce: 5

Entonces: 1234567895 Ese 5 permite validar que no hubo errores al escribir el número.

¿Por qué existe?
Si alguien escribe: 1234567895 y accidentalmente cambia: 1234567896

El sistema detecta: INVÁLIDO

Cómo funciona el Módulo 11

Se tiene: 123456
Se multiplica cada dígito por pesos.
Normalmente: 2,3,4,5,6,7 desde la derecha.

Ejemplo:
6 × 2 = 12
5 × 3 = 15
4 × 4 = 16
3 × 5 = 15
2 × 6 = 12
1 × 7 = 7

Suma: 77
Luego: 77 mod 11 = 0
Se calcula el dígito verificador según la fórmula del SIN.

¿Qué hace el SIAT? Al final de la cadena base: 000102345678920260730...
Se calcula un dígito Módulo 11.

Supongamos: 8
Entonces: 000102345678920260730...8

¿Qué es Base16?. Base16 es hexadecimal.
Convierte un número decimal gigantesco a:
0-9
A-F

Ejemplo sencillo
Decimal: 255
Hexadecimal: FF

Ejemplo
Decimal: 26
Hexadecimal: 1A

¿Por qué se usa?. La cadena CUF es enorme.

Ejemplo: 000102345678920260730101523123000011101000000012500008

Eso es un número decimal muy grande.
El SIN exige convertirlo a: Base16

Resultado:
7D4F1A6B8C9D...

Entonces el proceso real es

Paso 1. Crear cadena base
NIT
FechaHora
Sucursal
Modalidad
TipoEmision
TipoFactura
DocumentoSector
NumeroFactura
PuntoVenta
↓
000102345678920260730...

Paso 2. Aplicar Módulo 11
↓
000102345678920260730...8

Paso 3. Convertir TODO a hexadecimal
↓
7D4F1A6B8C9D0123456789ABCDE

¿Qué es el Código de Control del CUFD?

Cuando solicitas un CUFD:
El SIN responde:
CUFD: EFD7A8B9C123456789ABCDE...
Código Control: 4A7B8C9D

Ejemplo
CUFD = EFD7A8B9...
CódigoControl = 4A7B8C9D

Ese código viene del SIN.
El sistema NO lo calcula.

¿Cómo se obtiene el CUF final?. 
Supongamos que después de Base16 obtienes: 7D4F1A6B8C9D01234567890ABCDE
Y el CUFD tiene CódigoControl: 4A7B8C9D

Entonces:
CUF      = 7D4F1A6B8C9D01234567890ABCDE + 4A7B8C9D
Resultado: 7D4F1A6B8C9D01234567890ABCDE4A7B8C9D

Ese valor es el CUF que va en:
<cuf>
7D4F1A6B8C9D01234567890ABCDE4A7B8C9D
</cuf>

Importante para una implementación real
No debes inventar estas longitudes ni el algoritmo. 
El SIN publica la especificación oficial del CUF con:
Longitudes exactas.
Valores de modalidad.
Valores de tipo de emisión.
Fórmula exacta de Módulo 11.
Conversión hexadecimal.
Ejemplos oficiales.

Cuando programes el sistema, conviene crear una función:
generar_cuf(
	nit,
	fecha_hora,
	sucursal,
	modalidad,
	tipo_emision,
	tipo_factura,
	documento_sector,
	numero_factura,
	punto_venta,
	codigo_control_cufd
)

Que haga exactamente:
1. Formatear longitudes fijas
2. Concatenar
3. Calcular Módulo 11
4. Convertir a Base16
5. Agregar CódigoControl CUFD
6. Retornar CUF

Porque ese CUF será utilizado en el XML, en el QR y en las consultas posteriores al SIAT.

-- ================================================================================================
-- 5. Construir XML
	
Después de tener:
CUIS
CUFD
Número de factura
CUF
Datos del cliente
Productos

Se debe generar un XML con la estructura exacta definida por el SIN.
Conceptualmente	la factura en la base de datos:

{
	"numero": 125,
	"cuf": "ABCD123...",
	"cufd": "EFGH456...",
	"cliente": {
		"nombre": "Juan Perez",
		"nit": "1234567"
	},
	"total": 100
}

Debe transformarse en:
<facturaElectronicaCompraVenta>
	<cabecera>
		<nitEmisor>1023456789</nitEmisor>
		<razonSocialEmisor>FARMACIA XYZ</razonSocialEmisor>
		<municipio>Santa Cruz</municipio>
		<telefono>3333333</telefono>
		<numeroFactura>125</numeroFactura>
		<cuf>ABCD123...</cuf>
		<cufd>EFGH456...</cufd>
		<codigoSucursal>0</codigoSucursal>
		<direccion>Av. Principal</direccion>
		<codigoPuntoVenta>0</codigoPuntoVenta>
		<fechaEmision>2026-07-30T10:35:20.000</fechaEmision>
		<nombreRazonSocial>Juan Perez</nombreRazonSocial>
		<codigoTipoDocumentoIdentidad>5</codigoTipoDocumentoIdentidad>
		<numeroDocumento>1234567</numeroDocumento>
		<montoTotal>100.00</montoTotal>
		<codigoMoneda>1</codigoMoneda>
	</cabecera>
	<detalle>
		<actividadEconomica>477311</actividadEconomica>
		<codigoProductoSin>12345</codigoProductoSin>
		<codigoProducto>PARA500</codigoProducto>
		<descripcion>Paracetamol 500 mg</descripcion>
		<cantidad>2</cantidad>
		<unidadMedida>58</unidadMedida>
		<precioUnitario>50.00</precioUnitario>
		<subTotal>100.00</subTotal>
	</detalle>
</facturaElectronicaCompraVenta>

¿De dónde sale esta estructura?. Del XSD oficial del SIN.

El SIN publica: facturaElectronicaCompraVenta.xsd
Ese archivo define:
etiquetas obligatorias
tipos de datos
tamaños máximos
orden exacto

Si el XML no cumple el XSD:
Rechazado
Validación previa

Antes de firmar se debe validar:

XML
↓
Validador XSD
↓
Correcto

Si no se hace esto, muchas facturas serán rechazadas.

-- ================================================================================================
-- 6. Firmar XML XAdES.

Una factura sin firma digital NO es válida.
¿Qué es una firma digital?. Es similar a firmar un documento con un sello criptográfico.
Garantiza:
Autenticidad
Integridad
No repudio
Certificado Digital
La empresa debe tener: certificado.p12 ó certificado.pfx emitido por una entidad autorizada.

Ejemplo:
Farmacia XYZ
NIT 1023456789
Proceso
XML original
	<facturaElectronicaCompraVenta>
	...
	</facturaElectronicaCompraVenta>

Aplicar XAdES
Se calcula:
SHA256
sobre el XML.
Luego:
Clave privada del certificado
firma ese hash.

El resultado se inserta dentro del XML:

<ds:Signature>
	<SignedInfo>
	...
	</SignedInfo>
	<SignatureValue>
		ABCDEF123456...
	</SignatureValue>
</ds:Signature>

Resultado:

XML firmado
Bibliotecas comunes
Java
xades4j
Apache Santuario
.NET
System.Security.Cryptography.Xml
Python
signxml
xmlsec

-- ================================================================================================
-- 7. Comprimir XML.

El SIN no recibe normalmente el XML plano.
Recibe: XML comprimido

Ejemplo:
factura.xml
↓
factura.xml.gz
GZIP

Se utiliza: GZIP No ZIP tradicional.

Ejemplo: gzip.compress(xml_bytes)

Resultado:
factura.xml.gz

¿Por qué? Reduce tráfico.

Ejemplo:
XML original --> 120 KB
GZIP --> 18 KB
	
-- ================================================================================================
-- 8. Enviar al SIAT.

Aquí se usan Web Services SOAP.
Servicio

Normalmente:
RecepcionFactura, Solicitud

Se debe enviar algo parecido a:
CUIS
CUFD
NIT
Archivo XML GZIP
HASH SHA256

Conceptualmente:

Sistema
	|
	|
	|---- XML GZIP ---->
	|
SIAT
Hash del archivo

Además del archivo se envía: SHA256 del archivo comprimido.

Ejemplo:
9A4B5C7D8E...
Sirve para verificar integridad.

SOAP
La petición es algo similar a:
<soapenv:Envelope>
	<soapenv:Body>
		<recepcionFactura>
			<archivo>BASE64...</archivo>
			<hashArchivo>ABC123...</hashArchivo>
			<cufd>...</cufd>
		</recepcionFactura>
	</soapenv:Body>
</soapenv:Envelope>

Codificación Base64
El archivo GZIP: factura.xml.gz Se convierte a: QWxhZGRpbjpPcGVuU2VzYW1l... para poder viajar dentro del SOAP.

-- ================================================================================================
-- 9. Recibir código recepción.

Si todo está correcto el SIAT responde.

Ejemplo:
<RespuestaServicioFacturacion>
	<transaccion>true</transaccion>
	<codigoEstado>908</codigoEstado>
	<codigoRecepcion>
		8F7A9B6C123456789
	</codigoRecepcion>
</RespuestaServicioFacturacion>
Qué debes guardar
codigo_recepcion
estado
fecha_respuesta

Ejemplo:
codigo_recepcion = 8F7A9B6C123456789
estado = ACEPTADA

¿Qué es el código de recepción?. Es el identificador que el SIAT asigna a esa factura.

Sirve para:
consultar estado
verificar recepción
anular factura
auditoría
Si existe error

El SIAT devuelve algo parecido a:
<mensajesList>
	<codigo>1010</codigo>
	<descripcion>
		CUFD inválido
	</descripcion>
</mensajesList>
ó
XML inválido
ó
Firma digital inválida
Flujo completo real
Factura BD
	↓
Generar CUF
	↓
Construir XML
	↓
Validar XSD
	↓
Firmar XAdES
	↓
XML Firmado
	↓
GZIP
	↓
SHA256 archivo
	↓
Base64
	↓
SOAP RecepcionFactura
	↓
SIAT
	↓
Código Recepción
	↓
Guardar en BD
	↓
Imprimir factura con CUF y QR

Para una implementación profesional, además de guardar el XML firmado, conviene guardar también:
xml_original
xml_firmado
hash_xml
hash_gzip
codigo_recepcion
cuf
cufd
fecha_envio
fecha_respuesta
estado_siat

Porque eso facilita auditorías, reenvíos, anulaciones y verificaciones futuras ante el SIN.

-- ================================================================================================
-- 10. Registrar aceptación

Cuando envías la factura al SIAT, la respuesta puede ser:

<RespuestaServicioFacturacion>
    <transaccion>true</transaccion>
    <codigoEstado>908</codigoEstado>
    <codigoRecepcion>8F7A9B6C123456789</codigoRecepcion>
</RespuestaServicioFacturacion>
¿Qué significa? transaccion = true

El SIAT recibió correctamente la factura.

codigoEstado = 908
Factura válida y aceptada.
codigoRecepcion
Identificador único de recepción asignado por el SIN.

Qué debes guardar

En la tabla factura:
estado_siat
codigo_recepcion
fecha_envio
fecha_respuesta
codigo_estado

Ejemplo:
estado_siat = 'ACEPTADA'
codigo_estado = 908
codigo_recepcion = '8F7A9B6C123456789'
fecha_respuesta = '2026-07-30 10:15:23'
Estados recomendados
PENDIENTE
ENVIADA
ACEPTADA
RECHAZADA
ANULADA

Ejemplo de flujo
Usuario vende medicamento
↓
Factura N° 125
↓
XML generado
↓
XML enviado
↓
SIAT responde OK
↓
Estado = ACEPTADA
↓
Se habilita impresión
¿Cuándo imprimir?

La práctica recomendada es imprimir o entregar la representación gráfica solamente cuando:

estado_siat = ACEPTADA

porque ya tienes:

CUF definitivo
Código de recepción
Validación del SIN

-- ================================================================================================
-- 11. Generar QR. No es un QR libre. Debe contener la URL definida por el SIN.

Generalmente incluye: NIT, CUF, Número Factura.

Ejemplo:
https://siat.impuestos.gob.bo/consulta/QR?
nit=1023456789&
cuf=7D4F1A...
numero=125

La estructura exacta depende de la versión vigente del SIN.

Cuando envías la factura al SIAT, la respuesta puede ser:

<RespuestaServicioFacturacion>
    <transaccion>true</transaccion>
    <codigoEstado>908</codigoEstado>
    <codigoRecepcion>8F7A9B6C123456789</codigoRecepcion>
</RespuestaServicioFacturacion>
¿Qué significa?
transaccion = true

El SIAT recibió correctamente la factura.

codigoEstado = 908

Factura válida y aceptada.

codigoRecepcion

Identificador único de recepción asignado por el SIN.

Qué debes guardar:

En la tabla factura:
estado_siat
codigo_recepcion
fecha_envio
fecha_respuesta
codigo_estado

Ejemplo:
estado_siat = 'ACEPTADA'
codigo_estado = 908
codigo_recepcion = '8F7A9B6C123456789'
fecha_respuesta = '2026-07-30 10:15:23'
Estados recomendados
PENDIENTE
ENVIADA
ACEPTADA
RECHAZADA
ANULADA

Ejemplo de flujo
Usuario vende medicamento
↓
Factura N° 125
↓
XML generado
↓
XML enviado
↓
SIAT responde OK
↓
Estado = ACEPTADA
↓
Se habilita impresión

¿Cuándo imprimir?. La práctica recomendada es imprimir o entregar la representación gráfica solamente cuando:

estado_siat = ACEPTADA

porque ya tienes:
CUF definitivo
Código de recepción
Validación del SIN

El QR no es decorativo.

Sirve para que cualquier persona pueda verificar la factura.

Datos mínimos que normalmente intervienen
NIT Emisor
CUF
Número Factura

Dependiendo de la versión vigente del SIAT, la URL exacta puede cambiar.

Conceptualmente es algo parecido a:
https://siat.impuestos.gob.bo/consulta?
nit=1023456789
&cuf=ABCD123456
&numero=125
Generación

Tu sistema construye el texto:
https://siat.impuestos.gob.bo/consulta?nit=1023456789&cuf=ABCD123456789

Luego una librería QR genera la imagen.

Ejemplo:

█████████████
██ ▄▄▄▄▄ ██
██ █   █ ██
██ █▄▄▄█ ██
█████████████

Qué guardar se puede guardar:

qr_texto
qr_imagen
o generar la imagen cada vez que se imprima.

Muchas empresas sólo guardan: url_qr y regeneran el QR cuando sea necesario.
Recomendación Guardar:
url_qr
es suficiente.

Ejemplo: url_qr = 'https://siat.impuestos.gob.bo/...'

-- ================================================================================================
-- 12. Imprimir representación gráfica.

La representación gráfica NO es la factura oficial. La factura oficial es:
XML firmado
La impresión es una representación visual para el cliente.

Información mínima que normalmente debe mostrarse
Datos del emisor
FARMACIA XYZ SRL
NIT: 1023456789
Casa Matriz
Dirección
Teléfono
Datos de la factura
FACTURA N° 125
CUF: ABCD123456789...
Fecha: 30/07/2026 10:15
Cliente
Nombre: Juan Pérez
NIT/CI: 1234567
Detalle
Paracetamol 500mg     2     3.50     7.00
Ibuprofeno 400mg      1     5.00     5.00
Totales
Subtotal: 12.00
Descuento: 0.00
Total: 12.00
Código QR
[QR]
Leyenda fiscal

Según la normativa vigente, el SIN puede exigir determinadas leyendas obligatorias en la representación gráfica. Conviene obtenerlas desde los catálogos oficiales y no escribirlas fijas en el sistema.

PDF vs Ticket
Ticket térmico

Impresoras:
58 mm
80 mm

Ejemplo:

------------------------
FARMACIA XYZ
NIT: 1023456789

FACTURA N° 125

Paracetamol	2 x 3.50

TOTAL Bs 7.00

CUF: ABCD123456789

[QR]
------------------------
PDF

Muy usado para:

correo electrónico
WhatsApp
reimpresión

Ejemplo:

factura_125.pdf
Qué deberías guardar para reimpresiones

factura
---------
id
numero_factura
cuf
cufd
codigo_recepcion
estado_siat
url_qr
fecha_emision
total

y además:

factura_xml
-------------
xml_firmado
hash_xml

Opcionalmente:

factura_pdf
-------------
ruta_pdf
Flujo completo final
Venta
↓
Generar CUF
↓
Construir XML
↓
Firmar XML
↓
Comprimir
↓
Enviar SIAT
↓
Respuesta SIAT
↓
Registrar aceptación
↓
Guardar código recepción
↓
Generar URL QR
↓
Generar imagen QR
↓
Generar PDF/Ticket
↓
Entregar factura al cliente

Para una farmacia, además de la representación gráfica estándar, suele ser útil imprimir también datos internos como lote, fecha de vencimiento y registro sanitario de los medicamentos, pero esos datos son principalmente para control comercial y trazabilidad; no forman parte de los campos fiscales obligatorios del XML de facturación del SIN.

-- ================================================================================================
-- 13. Lo que sí debes implementar y lo que no se Debe implementar

✅ Gestión de sucursales
✅ Gestión de puntos de venta
✅ CUIS
✅ CUFD
✅ Generación de CUF
✅ XML oficial
✅ Firma digital XAdES
✅ Envío SOAP al SIAT
✅ Recepción de eventos
✅ Anulación
✅ Reimpresión
✅ QR
✅ Catálogos SIN

No se debe implementar
❌ Algoritmo antiguo de Código de Control (Verhoeff + RC4)
❌ Dosificación
❌ Llave de dosificación
❌ Facturación computarizada antigua

Eso quedó para sistemas anteriores al SIAT actual. Para una farmacia con Facturación Electrónica en Línea, el núcleo técnico es: CUIS → CUFD → CUF → XML → Firma XAdES → SIAT → QR.

-- ================================================================================================
-- Tablas propuestas.

CREATE TABLE empresa (
    id SERIAL PRIMARY KEY,
    nit VARCHAR(13) NOT NULL UNIQUE, -- 13 caracteres fijos (completar con ceros a la izquierda si es necesario)
    razon_social VARCHAR(200) NOT NULL, -- Nombre legal oficial ante SEPREC y SIN
    nombre_comercial VARCHAR(200), -- Nombre de fantasía/marca visible al público
    actividad_economica_principal VARCHAR(10) NOT NULL, -- Código de actividad económica (ej: 477311)
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    modalidad_facturacion INTEGER DEFAULT 1, -- 1=Electrónica en Línea, 2=Computarizada en Línea
    codigo_ambiente INTEGER DEFAULT 1, -- 1=Producción, 2=Piloto/Pruebas
    certificado_digital BYTEA, -- Archivo .p12 o .pfx en formato binario
    fecha_vencimiento_certificado DATE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);
COMMENT ON COLUMN empresa.modalidad_facturacion IS '1=Electrónica en Línea, 2=Computarizada en Línea';
COMMENT ON COLUMN empresa.codigo_ambiente IS '1=Producción, 2=Piloto/Pruebas';
COMMENT ON COLUMN empresa.nit IS 'NIT con 13 dígitos fijos, completar con ceros a la izquierda';
COMMENT ON COLUMN empresa.razon_social IS 'Nombre legal oficial obligatorio ante el Estado (SEPREC, SIN)';
COMMENT ON COLUMN empresa.nombre_comercial IS 'Nombre de fantasía o marca visible al público (opcional)';
COMMENT ON COLUMN empresa.certificado_digital IS 'Certificado digital en formato .p12 o .pfx emitido por entidad autorizada';

CREATE TABLE sucursal (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER NOT NULL REFERENCES empresa(id),
    codigo_sucursal VARCHAR(4) NOT NULL, -- Código asignado por el SIN (0=Casa Matriz, 1,2,3...)
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(empresa_id, codigo_sucursal)
);
COMMENT ON COLUMN sucursal.codigo_sucursal IS 'Código de sucursal asignado por el SIN. 0=Casa Matriz, 1,2,3... para sucursales';
COMMENT ON COLUMN sucursal.nombre IS 'Nombre descriptivo de la sucursal (Ej: Casa Matriz, Sucursal Equipetrol)';

CREATE TABLE punto_venta (
    id SERIAL PRIMARY KEY,
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    codigo_punto_venta VARCHAR(4) NOT NULL, -- Código independiente por sucursal (0,1,2...)
    descripcion VARCHAR(200) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sucursal_id, codigo_punto_venta)
);

COMMENT ON COLUMN punto_venta.codigo_punto_venta IS 'Código de punto de venta, independiente por sucursal. 0=Punto principal, 1,2... para cajas';
COMMENT ON COLUMN punto_venta.descripcion IS 'Descripción del punto de venta (Ej: Caja 1, Caja farmacia)';

CREATE TABLE cuis (
    id SERIAL PRIMARY KEY,
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    punto_venta_id INTEGER NOT NULL REFERENCES punto_venta(id),
    cuis VARCHAR(50) NOT NULL, -- Código Único de Inicio de Sistemas (proporcionado por el SIAT)
    fecha_vigencia DATE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    UNIQUE(sucursal_id, punto_venta_id, cuis)
);
COMMENT ON COLUMN cuis.cuis IS 'Código Único de Inicio de Sistemas, proporcionado por el SIAT, no se genera localmente';
COMMENT ON COLUMN cuis.fecha_vigencia IS 'Fecha hasta la cual es válido el CUIS';

CREATE TABLE cufd (
    id SERIAL PRIMARY KEY,
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    punto_venta_id INTEGER NOT NULL REFERENCES punto_venta(id),
    cufd VARCHAR(50) NOT NULL, -- Código Único de Facturación Diaria (proporcionado por el SIAT)
    codigo_control VARCHAR(20) NOT NULL, -- Código de Control del CUFD (proporcionado por el SIAT)
    fecha_vigencia DATE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    UNIQUE(sucursal_id, punto_venta_id, cufd)
);
COMMENT ON COLUMN cufd.cufd IS 'Código Único de Facturación Diaria, proporcionado por el SIAT';
COMMENT ON COLUMN cufd.codigo_control IS 'Código de Control del CUFD, proporcionado por el SIAT, NO se calcula localmente';
COMMENT ON COLUMN cufd.fecha_vigencia IS 'Fecha hasta la cual es válido el CUFD (generalmente 24 horas)';

CREATE TABLE factura (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER NOT NULL REFERENCES empresa(id),
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    punto_venta_id INTEGER NOT NULL REFERENCES punto_venta(id),
    cuis_id INTEGER NOT NULL REFERENCES cuis(id),
    cufd_id INTEGER NOT NULL REFERENCES cufd(id),
    
    -- Datos de la factura
    numero_factura VARCHAR(10) NOT NULL, -- Secuencial por sucursal+punto_venta
    cuf VARCHAR(70) NOT NULL UNIQUE, -- Código Único de Factura (generado localmente)
    fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Datos del cliente
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_documento VARCHAR(20) NOT NULL,
    cliente_tipo_documento INTEGER NOT NULL, -- 1=CI, 2=CEX, 3=Pasaporte, 4=Otro, 5=NIT
    
    -- Datos financieros
    metodo_pago INTEGER NOT NULL, -- 1=Efectivo, 2=Tarjeta, 3=Cheque, 4=Vale, 5=Otros, 6=Sin pago, 7=Transferencia, 8=Depósito, 9=QR
    subtotal DECIMAL(12,2) NOT NULL,
    descuento DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    codigo_moneda INTEGER DEFAULT 1, -- 1=BOB, 2=USD, 3=EUR, 4=UFV
    
    -- Datos SIAT
    codigo_documento_sector VARCHAR(2) DEFAULT '01', -- 01=Factura Compra Venta (para farmacia)
    xml_generado TEXT, -- XML antes de firmar (para auditoría)
    xml_firmado TEXT, -- XML firmado con XAdES
    hash_xml VARCHAR(100), -- SHA256 del XML firmado
    hash_gzip VARCHAR(100), -- SHA256 del archivo comprimido
    
    -- Estado y respuesta del SIAT
    estado_siat VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, ENVIADA, ACEPTADA, RECHAZADA, ANULADA
    codigo_recepcion VARCHAR(50), -- Código de recepción asignado por el SIAT
    codigo_estado VARCHAR(10), -- Código de estado devuelto por el SIAT (ej: 908)
    mensaje_siat TEXT, -- Mensaje de respuesta del SIAT
    
    -- QR
    url_qr VARCHAR(500), -- URL para el código QR (generada localmente)
    
    -- Fechas de proceso
    fecha_envio TIMESTAMP,
    fecha_respuesta TIMESTAMP,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Motivo de anulación (si aplica)
    motivo_anulacion INTEGER, -- 1=Factura mal emitida, 2=Error datos cliente, 3=Devolución, 4=Contingencia, 5=Operación no concretada
    
    UNIQUE(sucursal_id, punto_venta_id, numero_factura)
);

COMMENT ON COLUMN factura.numero_factura IS 'Número secuencial de factura por sucursal+punto_venta (10 dígitos fijos completar con ceros)';
COMMENT ON COLUMN factura.cuf IS 'Código Único de Factura, generado localmente siguiendo algoritmo oficial del SIN';
COMMENT ON COLUMN factura.cliente_tipo_documento IS '1=CI, 2=CEX, 3=Pasaporte, 4=Otro documento, 5=NIT';
COMMENT ON COLUMN factura.metodo_pago IS '1=Efectivo, 2=Tarjeta, 3=Cheque, 4=Vale, 5=Otros, 6=Sin pago, 7=Transferencia, 8=Depósito, 9=QR';
COMMENT ON COLUMN factura.codigo_moneda IS '1=BOB, 2=USD, 3=EUR, 4=UFV';
COMMENT ON COLUMN factura.estado_siat IS 'Estado de la factura en el SIAT: PENDIENTE, ENVIADA, ACEPTADA, RECHAZADA, ANULADA';
COMMENT ON COLUMN factura.codigo_recepcion IS 'Identificador único asignado por el SIAT cuando la factura es aceptada';
COMMENT ON COLUMN factura.motivo_anulacion IS '1=Factura mal emitida, 2=Error datos cliente, 3=Devolución, 4=Contingencia, 5=Operación no concretada';

CREATE TABLE detalle_factura (
    id SERIAL PRIMARY KEY,
    factura_id INTEGER NOT NULL REFERENCES factura(id) ON DELETE CASCADE,
    
    -- Datos fiscales (obligatorios para el SIN)
    codigo_producto_sin VARCHAR(20) NOT NULL, -- Código de producto en el catálogo del SIN
    codigo_producto VARCHAR(50) NOT NULL, -- Código interno del producto
    descripcion VARCHAR(500) NOT NULL,
    cantidad DECIMAL(12,3) NOT NULL,
    unidad_medida INTEGER NOT NULL, -- 58=Unidad (para medicamentos), otros según catálogo SIN
    precio_unitario DECIMAL(12,2) NOT NULL,
    sub_total DECIMAL(12,2) NOT NULL,
    
    -- Datos internos (no obligatorios para el SIN, útiles para la farmacia)
    lote VARCHAR(50),
    fecha_vencimiento DATE,
    registro_sanitario VARCHAR(50),
    laboratorio VARCHAR(100),
    concentracion VARCHAR(50),
    
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN detalle_factura.codigo_producto_sin IS 'Código de producto según catálogo del SIN (obligatorio)';
COMMENT ON COLUMN detalle_factura.unidad_medida IS 'Código de unidad de medida según catálogo del SIN (58=Unidad)';
COMMENT ON COLUMN detalle_factura.lote IS 'Número de lote del medicamento (solo para control interno)';
COMMENT ON COLUMN detalle_factura.fecha_vencimiento IS 'Fecha de vencimiento del lote (solo para control interno)';
COMMENT ON COLUMN detalle_factura.registro_sanitario IS 'Registro sanitario del medicamento (solo para control interno)';

CREATE TABLE catalogo_siat (
    id SERIAL PRIMARY KEY,
    codigo_catalogo VARCHAR(10) NOT NULL, -- Ej: 'TIPO_DOCUMENTO', 'METODO_PAGO', 'UNIDAD_MEDIDA'
    codigo VARCHAR(10) NOT NULL, -- Código del valor en el catálogo
    descripcion VARCHAR(200) NOT NULL, -- Descripción del valor
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(codigo_catalogo, codigo)
);

COMMENT ON TABLE catalogo_siat IS 'Catálogos oficiales del SIAT para valores estándar';
COMMENT ON COLUMN catalogo_siat.codigo_catalogo IS 'Identificador del catálogo (ej: TIPO_DOCUMENTO, METODO_PAGO)';
COMMENT ON COLUMN catalogo_siat.codigo IS 'Código del valor en el catálogo del SIAT';
COMMENT ON COLUMN catalogo_siat.descripcion IS 'Descripción del valor según el SIAT';

-- Datos de ejemplo para catálogos
INSERT INTO catalogo_siat (codigo_catalogo, codigo, descripcion) VALUES
									('TIPO_DOCUMENTO', '1', 'CI'),
									('TIPO_DOCUMENTO', '2', 'CEX'),
									('TIPO_DOCUMENTO', '3', 'Pasaporte'),
									('TIPO_DOCUMENTO', '4', 'Otro documento'),
									('TIPO_DOCUMENTO', '5', 'NIT'),
									('METODO_PAGO', '1', 'Efectivo'),
									('METODO_PAGO', '2', 'Tarjeta'),
									('METODO_PAGO', '3', 'Cheque'),
									('METODO_PAGO', '4', 'Vale'),
									('METODO_PAGO', '5', 'Otros'),
									('METODO_PAGO', '6', 'Sin pago'),
									('METODO_PAGO', '7', 'Transferencia'),
									('METODO_PAGO', '8', 'Depósito'),
									('METODO_PAGO', '9', 'QR'),
('UNIDAD_MEDIDA', '58', 'Unidad'),
('MONEDA', '1', 'BOB'),
('MONEDA', '2', 'USD'),
('MONEDA', '3', 'EUR'),
('MONEDA', '4', 'UFV'),
('MOTIVO_ANULACION', '1', 'Factura mal emitida'),
('MOTIVO_ANULACION', '2', 'Error datos cliente'),
('MOTIVO_ANULACION', '3', 'Devolución'),
('MOTIVO_ANULACION', '4', 'Contingencia'),
('MOTIVO_ANULACION', '5', 'Operación no concretada');

CREATE TABLE logs_siat (
    id SERIAL PRIMARY KEY,
    factura_id INTEGER REFERENCES factura(id),
    operacion VARCHAR(50) NOT NULL, -- 'ENVIO', 'CONSULTA', 'ANULACION'
    peticion TEXT,
    respuesta TEXT,
    codigo_estado VARCHAR(10),
    mensaje_error TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE logs_siat IS 'Registro de todas las comunicaciones con el SIAT para auditoría';
COMMENT ON COLUMN logs_siat.operacion IS 'Tipo de operación: ENVIO, CONSULTA, ANULACION';
COMMENT ON COLUMN logs_siat.peticion IS 'Contenido de la petición SOAP al SIAT';
COMMENT ON COLUMN logs_siat.respuesta IS 'Respuesta del SIAT';


CREATE TABLE configuracion_cuf (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) NOT NULL, -- 'V1', 'V2', etc. para futuras versiones
    activo BOOLEAN DEFAULT TRUE,
    
    -- Longitudes de cada campo
    longitud_nit INTEGER NOT NULL DEFAULT 13,
    longitud_fecha_hora INTEGER NOT NULL DEFAULT 17,
    longitud_sucursal INTEGER NOT NULL DEFAULT 4,
    longitud_modalidad INTEGER NOT NULL DEFAULT 1,
    longitud_tipo_emision INTEGER NOT NULL DEFAULT 1,
    longitud_tipo_factura INTEGER NOT NULL DEFAULT 1,
    longitud_documento_sector INTEGER NOT NULL DEFAULT 2,
    longitud_numero_factura INTEGER NOT NULL DEFAULT 10,
    longitud_punto_venta INTEGER NOT NULL DEFAULT 4,
    longitud_codigo_control INTEGER NOT NULL DEFAULT 10,
    
    -- Orden de concatenación
    orden_campos TEXT NOT NULL DEFAULT 'nit,fecha_hora,sucursal,modalidad,tipo_emision,tipo_factura,documento_sector,numero_factura,punto_venta',
    
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_actualizacion VARCHAR(50),
    
    UNIQUE(version, activo)
);

COMMENT ON TABLE configuracion_cuf IS 'Configuración de longitudes fijas para la generación del CUF según versión del SIAT';
COMMENT ON COLUMN configuracion_cuf.version IS 'Versión de la configuración del CUF';
COMMENT ON COLUMN configuracion_cuf.longitud_nit IS 'Longitud fija para el NIT (generalmente 13)';
COMMENT ON COLUMN configuracion_cuf.longitud_fecha_hora IS 'Longitud fija para fecha/hora (AAAAMMDDHHMMSSmmm)';
COMMENT ON COLUMN configuracion_cuf.longitud_sucursal IS 'Longitud fija para código de sucursal';
COMMENT ON COLUMN configuracion_cuf.longitud_modalidad IS 'Longitud fija para modalidad de facturación (1 dígito)';
COMMENT ON COLUMN configuracion_cuf.longitud_tipo_emision IS 'Longitud fija para tipo de emisión (1 dígito)';
COMMENT ON COLUMN configuracion_cuf.longitud_tipo_factura IS 'Longitud fija para tipo de factura (1 dígito)';
COMMENT ON COLUMN configuracion_cuf.longitud_documento_sector IS 'Longitud fija para código de documento sector (2 dígitos)';
COMMENT ON COLUMN configuracion_cuf.longitud_numero_factura IS 'Longitud fija para número de factura';
COMMENT ON COLUMN configuracion_cuf.longitud_punto_venta IS 'Longitud fija para código de punto de venta';
COMMENT ON COLUMN configuracion_cuf.longitud_codigo_control IS 'Longitud fija para el código de control del CUFD';

-- Configuración por defecto (versión actual del SIAT)
INSERT INTO configuracion_cuf (
    version, 
    longitud_nit, 
    longitud_fecha_hora, 
    longitud_sucursal, 
    longitud_modalidad, 
    longitud_tipo_emision, 
    longitud_tipo_factura, 
    longitud_documento_sector, 
    longitud_numero_factura, 
    longitud_punto_venta, 
    longitud_codigo_control,
    orden_campos
) VALUES (
    'V1', 
    13,  -- NIT (13 dígitos)
    17,  -- Fecha/Hora (17 dígitos)
    4,   -- Sucursal (4 dígitos)
    1,   -- Modalidad (1 dígito)
    1,   -- Tipo Emisión (1 dígito)
    1,   -- Tipo Factura (1 dígito)
    2,   -- Documento Sector (2 dígitos)
    10,  -- Número Factura (10 dígitos)
    4,   -- Punto Venta (4 dígitos)
    10   -- Código Control CUFD (10 dígitos)
);

CREATE TABLE configuracion_formato (
    id SERIAL PRIMARY KEY,
    tipo_formato VARCHAR(20) NOT NULL, -- 'NIT', 'FECHA_HORA', 'SUCURSAL', etc.
    version VARCHAR(20) NOT NULL, -- 'V1', 'V2', etc.
    longitud INTEGER NOT NULL,
    padding_char CHAR(1) DEFAULT '0',
    padding_direction VARCHAR(10) DEFAULT 'LEFT', -- 'LEFT' o 'RIGHT'
    formato_ejemplo VARCHAR(50),
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tipo_formato, version)
);

COMMENT ON TABLE configuracion_formato IS 'Configuración detallada de formato para cada campo del CUF';
COMMENT ON COLUMN configuracion_formato.tipo_formato IS 'Tipo de campo a formatear';
COMMENT ON COLUMN configuracion_formato.version IS 'Versión del formato';
COMMENT ON COLUMN configuracion_formato.longitud IS 'Longitud fija del campo';
COMMENT ON COLUMN configuracion_formato.padding_char IS 'Carácter de relleno (generalmente 0)';
COMMENT ON COLUMN configuracion_formato.padding_direction IS 'Dirección del relleno: LEFT o RIGHT';

-- Insertar configuraciones de formato por defecto
INSERT INTO configuracion_formato (tipo_formato, version, longitud, padding_char, padding_direction, formato_ejemplo, descripcion) VALUES
('NIT', 'V1', 13, '0', 'LEFT', '0001023456789', 'NIT con 13 dígitos fijos'),
('FECHA_HORA', 'V1', 17, '0', 'LEFT', '20260730101523123', 'Fecha/Hora: AAAAMMDDHHMMSSmmm'),
('SUCURSAL', 'V1', 4, '0', 'LEFT', '0000', 'Código de sucursal (0=Casa Matriz)'),
('MODALIDAD', 'V1', 1, '0', 'LEFT', '1', 'Modalidad de facturación (1=Electrónica en Línea)'),
('TIPO_EMISION', 'V1', 1, '0', 'LEFT', '1', 'Tipo de emisión (1=Normal, 2=Contingencia)'),
('TIPO_FACTURA', 'V1', 1, '0', 'LEFT', '1', 'Tipo de factura (1=Factura)'),
('DOCUMENTO_SECTOR', 'V1', 2, '0', 'LEFT', '01', 'Código de documento sector (01=Factura Compra Venta)'),
('NUMERO_FACTURA', 'V1', 10, '0', 'LEFT', '0000000125', 'Número de factura secuencial'),
('PUNTO_VENTA', 'V1', 4, '0', 'LEFT', '0000', 'Código de punto de venta'),
('CODIGO_CONTROL', 'V1', 10, '0', 'RIGHT', '4A7B8C9D00', 'Código de control del CUFD (completar a la derecha)');


CREATE TABLE configuracion_calculo_cuf (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) NOT NULL,
    modulo_base INTEGER DEFAULT 11, -- Módulo para el cálculo (generalmente 11)
    base_hexadecimal BOOLEAN DEFAULT TRUE, -- Si se convierte a hexadecimal
    incluir_codigo_control BOOLEAN DEFAULT TRUE, -- Si se incluye el código de control del CUFD
    separador_campos VARCHAR(5), -- Separador entre campos (generalmente vacío)
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(version, activo)
);

COMMENT ON TABLE configuracion_calculo_cuf IS 'Configuración del algoritmo de cálculo del CUF';
COMMENT ON COLUMN configuracion_calculo_cuf.modulo_base IS 'Módulo para el cálculo del dígito verificador';
COMMENT ON COLUMN configuracion_calculo_cuf.base_hexadecimal IS 'Si se convierte el resultado a Base16 (hexadecimal)';
COMMENT ON COLUMN configuracion_calculo_cuf.incluir_codigo_control IS 'Si se añade el código de control del CUFD al final';

-- Configuración por defecto
INSERT INTO configuracion_calculo_cuf (version, modulo_base, base_hexadecimal, incluir_codigo_control) VALUES
('V1', 11, TRUE, TRUE);
-- ================================================================================================


CREATE TABLE unidades (
    unidad_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    codigo_sin VARCHAR(50) NOT NULL DEFAULT '0',
    unidad VARCHAR(100) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_uni_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_uni_unidad_not_empty CHECK (TRIM(unidad) <> ''),
    CONSTRAINT chk_uni_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_uni_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 1),
    CONSTRAINT chk_uni_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_uni_estado_dominio CHECK (estado_id IN (1000, 1001, 1002))
);
CREATE UNIQUE INDEX uix_uni_codigo ON unidades (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_uni_unidad ON unidades (unidad) WHERE estado_id IN (1000, 1002);

DELETE FROM unidades;
ALTER SEQUENCE unidades_unidad_id_seq RESTART WITH 1;

INSERT INTO unidades (unidad_id, codigo, codigo_sin, unidad, estado_id, usuario_id_registro) VALUES
(1, 'NIN', '0', 'NINGUNA', 1000, 1),
(2, 'KG', '1', 'KILOGRAMO', 1000, 1),
(3, 'G', '2', 'GRAMO', 1000, 1),
(4, 'T', '3', 'TONELADA', 1000, 1),
(5, 'L', '4', 'LITRO', 1000, 1),
(6, 'ML', '5', 'MILILITRO', 1000, 1),
(7, 'M', '6', 'METRO', 1000, 1),
(8, 'CM', '7', 'CENTÍMETRO', 1000, 1),
(9, 'U', '58', 'UNIDAD', 1000, 1),
(10, 'PZ', '9', 'PIEZA', 1000, 1),
(11, 'CJ', '10', 'CAJA', 1000, 1),
(12, 'PQ', '11', 'PAQUETE', 1000, 1);
