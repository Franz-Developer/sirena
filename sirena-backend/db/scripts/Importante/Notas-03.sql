Generalidades
El Servicio de Impuestos Nacionales (SIN) priorizando la modernización, optimización e integración de procesos y aplicaciones impositivas, con la premisa de facilitar a los contribuyentes el cumplimiento de sus obligaciones tributarias, así como dotar a la Administración Tributaria de mecanismos eficientes que le permitan cumplir adecuadamente con sus fines, pone a disposición del contribuyente, el presente Anexo Técnico que documenta las distintas modalidades de facturación, incluye procesos de autorización, emisión, registro y envío de facturas manuales como electrónicas cumpliendo los requisitos legales y reglamentarios establecidos en la Resolución Normativa de Directorio N° 102100000011. 
 
Actualización
"Se sustituye la leyenda “Tarifa Dignidad” por “Descuento Patria” en la representación gráfica de los documentos sector Factura de Servicios Básicos y Factura de Servicios Básicos Zona Franca.
La presente modificación se realiza en cumplimiento al convenio suscrito entre el Gobierno y el sector eléctrico, así como a la normativa aplicable vigente."

Facturación Electrónica 
Modalidad para la emisión de Facturas Digitales firmadas digitalmente, además del uso de Token propio o delegado a través de un Sistema Informático de Facturación autorizado por la Administración Tributaria y su posterior envío, registro y validación en los servidores de base de datos del SIN.  
Características:
•	Uso de la Firma Digital. (LINK Firma Digital_1)
•	Impresión de la Factura Digital de manera opcional.
•	Envío individual de la Factura firmada digitalmente en formato XML. (LINK XML_1)
•	Envío agrupado en paquete por contingencia de las Facturas en formato XML firmadas digitalmente.
•	Envío masivo en forma de paquetes de las Facturas en formato XML firmadas digitalmente.
Contenido del LINK Firma Digital_1
Firma Digital
Es un mecanismo criptográfico que permite al receptor de un mensaje firmado digitalmente identificar a la entidad originadora de dicho mensaje (autenticación de origen y no repudio), y confirmar que el mensaje no ha sido alterado desde que fue firmado por el originador (integridad).
Garantías de la Firma Digital
1.	Autenticidad: La firma digital ayuda a garantizar que la persona que firma es quien dice ser.
2.	No Repudio: El signatario no puede negar la firma digital ya que solo él posee el certificado digital y la clave privada.
3.	Integridad: La firma digital ayuda a verificar que el contenido no se ha cambiado o manipulado desde que se firmó el documento.
Beneficios
1.	Reduce el uso de papel.
2.	Disminuye costos operativos.
3.	Agiliza y simplifica la entrega de facturas.
4.	Permite implementar trámites en línea.
¿Cómo obtienes un certificado digital?
Para obtener un certificado digital válido a nivel nacional puede acudir a una entidad certificada autorizada o una Agencia de Registro y realizar el trámite ante ella: 
•         Agencia de Gobierno Electrónico y Tecnologías de Información y Comunicación (AGETIC).
•         Certificaciones Digitales Digicert SRL.
Proceso de Firmado
A efectos de poder firmar un documento, es necesario disponer de una llave pública y una privada; tener implementado algoritmos de conversión a Base 64, canonicalización, SHA256 y RSA Sha256 V2 y seguir los siguientes pasos:
1.	Aplicar el algoritmo de canonicalización al documento XML, es decir realizar un procesamiento que permita obtener su forma canónica o se normalice el documento original.
2.	Aplicara al resultado el algoritmo sha256 a objeto de obtener el HASH.
3.	Obtener una cadena aplicando al anterior HASH el algoritmo Base64.
4.	Adicionar las etiquetas de signature al XML.
5.	Agregar a la etiqueta Digest Value el valor obtenido en el paso 4.
6.	Tomar la sección de la firma y obtener un HASH del mismo aplicando el algoritmo SHA256.
7.	Encriptar el HASH obtenido utilizando el algoritmo RSA SHA256 con la llave privada.
8.	Aplicar a la cadena resultante el algoritmo Base64 para obtener una cadena.
9.	Adicionar a la etiqueta de Signature Value la cadena anterior.
10.	Finalmente colocar en la etiqueta X509 Certificate la llave publica.
11.	Devolver el XML firmado.
Validaciones de la Firma Digital
La Administración Tributaria validará de forma inmediata la vigencia de la Firma Digital utilizada en el firmado de Facturas digitales u otros documentos fiscales digitales, independientemente de su forma de envío.
La validación de revocación se hará en función de la información que las Entidades Certificadoras vayan actualizando su Lista de Certificados Revocados (CRL), por lo que no será necesariamente inmediata, las Facturas o Notas de Crédito - Débito emitidas con firmas revocadas o no vigentes serán observadas para procesos posteriores.


 Esquema de Interoperabilidad
 
EMISOR ---> 1. Solicita Código Único de Facturación Diaria - CUFD ---> SIN
EMISOR <--- 2. Valida y Devuelve Código <--- SIN
EMISOR ---> 3. Genera, Firma y Envía XML ---> SIN
SIN (4. Valida y almacena Archivo XML)
EMISOR <--- 5. Devuelve Ok o Errores <--- SIN
EMISOR (6. Opcionalmente Imprime Factura o Nota C/D)
EMISOR ---> 7. Solicita Confirmación Paquete ---> SIN
EMISOR <--- 8. Devuelve Ok o Errores <--- SIN

1. El Sistema Informático de Facturación del emisor (previamente autorizado y que tenga CUIS vigente) solicita al SIN el código único de facturación diaria (CUFD), que le habilita la emisión de Facturas por un periodo de 24 horas.
2.   El SIN realiza verificaciones a la información del emisor y devuelve los códigos de Verificación y CUFD, además de la dirección de la sucursal o casa matriz.
3.  El Sistema Informático de Facturación del Contribuyente utiliza el CUFD, junto con los datos de emisión para generar el archivo XML (factura digital), que debe ser firmado digitalmente y enviado a través de los servicios correspondientes del SIN.
4.  El SIN recibe la solicitud de recepción y procede a validar la cabecera para devolver la siguiente información:
a)     Si la validación es correcta y es un proceso individual en línea, retorna código de recepción. 
b)  Si la validación es correcta y es un proceso por paquete de contingencia o masivo, retorna el código de recepción.
c)   Si la validación presenta errores, retorna una lista de códigos y mensajes de error para que el emisor proceda a su corrección y posterior reenvío.
5.    El Sistema envía por correo u otra medio la representación gráfica y el XML al cliente, si este desea tener un respaldo de la emisión de la Factura Digital, el emisor podrá imprimir la Representación Gráfica.
6.  Cuando la emisión de la Factura Digital sea por paquete de contingencia o por emisión masiva, el SIN validará la información contenida en el paquete de manera individual, como resultado se tiene:
a)  Registrar y consolidar la Factura Digital para la emisión por contingencia o masiva en caso de no existir errores.
b) En caso de existir errores, se observa el paquete, se registran las facturas correctas y se rechazan las que contengan los errores. En caso de que el tipo de documento sea NIT y el  numero de documento no sea valido o no haya sido validado previamente a través del método de verificación de NIT, el emisor podrá enviar el código de excepción para que la factura no sea rechazada.
7.  El SIN retorna los resultados del proceso de validación descritos en el punto 6. En caso de existir observaciones deberá subsanarlas y posteriormente reenviar la Factura Digital. 
--- FIN DE LINK Firma Digital_1 ---
CONTENIDO DE LINK XML_1
Factura Electrónica
 
Una Factura Electrónica es un documento digital de índole fiscal,  emitido a través de un Sistema Informático de Facturación autorizado por la Administración Tributaria, su existencia es digital y debe ser registrada y validada en la base de datos del Servicio de Impuestos Nacionales.
 
A efecto de su emisión requiere:
•	Token de acceso que puede ser propio o delegado (en el caso de proveedor) y la Firma Digital del Sujeto Pasivo en la Modalidad de Facturación Electrónica en Línea;
•	Token de acceso delegado (en el caso de sistema proveedor) o propio, y la huella del archivo XML, en la Modalidad de Facturación Computarizada en Línea;
•	Credenciales de acceso otorgadas por la Administración Tributaria en la Modalidad de Facturación Portal Web en Línea.
XML
Las facturas electrónicas se envían al SIN utilizando para ello XML que es un tipo de lenguaje de marcado o conjunto de códigos (denominados etiquetas) que definen la estructura y el significado de los datos, El ejemplo a continuación describe de manera general la estructura de una factura computarizada.
 
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<facturaComputarizadaCompraVenta xsi:noNamespaceSchemaLocation="facturaComputarizadaCompraVenta.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<cabecera>
<nitEmisor>1003579028</nitEmisor>
<razonSocialEmisor>Carlos Loza</razonSocialEmisor>
<municipio>La Paz</municipio>
<telefono>78595684</telefono>
<numeroFactura>1</numeroFactura>
<cuf>44AAEC00DBD34C53C3E2CCE1A3FA7AF1E2A08606A667A75AC82F24C74</cuf>
<cufd>BQUE+QytqQUDBKVUFOSVRPQkxVRFZNVFVJBMDAwMDAwM</cufd>
<codigoSucursal>0</codigoSucursal>
<direccion>AV. JORGE LOPEZ #123</direccion>
<codigoPuntoVenta xsi:nil="true"/>
<fechaEmision>2021-10-06T16:03:48.675</fechaEmision>
<nombreRazonSocial>Mi razon social</nombreRazonSocial>
<codigoTipoDocumentoIdentidad>1</codigoTipoDocumentoIdentidad>
<numeroDocumento>5115889</numeroDocumento>
<complemento xsi:nil="true"/>
<codigoCliente>51158891</codigoCliente>
<codigoMetodoPago>1</codigoMetodoPago>
<numeroTarjeta xsi:nil="true"/>
<montoTotal>99</montoTotal>
<montoTotalSujetoIva>99</montoTotalSujetoIva>
<codigoMoneda>1</codigoMoneda>
<tipoCambio>1</tipoCambio>
<montoTotalMoneda>99</montoTotalMoneda>
<montoGiftCard xsi:nil="true"/>
<descuentoAdicional>1</descuentoAdicional>
<codigoExcepcion xsi:nil="true"/>
<cafc xsi:nil="true"/>
<leyenda>Ley N° 453: Tienes derecho a recibir información sobre las características y contenidos de los
servicios que utilices.
</leyenda>
<usuario>pperez</usuario>
<codigoDocumentoSector>1</codigoDocumentoSector>
</cabecera>
<detalle>
<actividadEconomica>451010</actividadEconomica>
<codigoProductoSin>49111</codigoProductoSin>
<codigoProducto>JN-131231</codigoProducto>
<descripcion>MI PRODUCTO O SERVICIO</descripcion>
<cantidad>1</cantidad>
<unidadMedida>1</unidadMedida>
<precioUnitario>100</precioUnitario>
<montoDescuento>0</montoDescuento>
<subTotal>100</subTotal>
<numeroSerie>124548</numeroSerie>
<numeroImei xsi:nil="true"/>
</detalle>
</facturaComputarizadaCompraVenta>
 --- FIN DE LINK XML_1 ---
 Servicios SOAP
Las facturas electrónicas son enviadas a la Administración Tributaria consumiendo servicios SOAP. Los servicios SOAP o simplemente conocidos como Web Services, basan su comunicación bajo el protocolo SOAP, que define cómo dos objetos en diferentes procesos pueden comunicarse intercambiando datos utilizando para ello XML.
 
        App A               +--------------------+               App B
        App A   =====>| SOAP (Payload: XML)| =====>   App B
        App A               +--------------------+               App B
            [ Transmisión HTTP ]
Facturación Computarizada en Línea
Modalidad para la emisión de Facturas Digitales usando un Token propio o delegado en un Sistema Informático de Facturación autorizado por la Administración Tributaria y su posterior envío, registro y validación en los servidores de base de datos del SIN. 
Características:
•	Impresión de la Factura Digital de manera opcional.
•	Envío individual de la Factura en formato XML.
•	Envío agrupado en paquete por contingencia de las Facturas en formato XML.
•	Envío masivo por paquete de las Facturas en formato XML.
Esquema de Interoperabilidad
 
EMISOR ---> 1. Solicita Código Único de Facturación Diaria - CUFD ---> SIN
EMISOR <--- 2. Valida y Devuelve Código <--- SIN
EMISOR ---> 3. Genera y Envia XML ---> SIN
SIN (4. Valida y almacena Archivo XML)
EMISOR <--- 5. Devuelve Ok o Errores <--- SIN
EMISOR (6. Opcionalmente Imprime Factura o Nota C/D)
EMISOR ---> 7. Solicita Confirmación Paquete ---> SIN
EMISOR <--- 8. Devuelve Ok o Errores <--- SIN

1.   El Sistema Informático de Facturación del emisor (previamente autorizado y que tenga el CUIS vigente) LINK CUIS solicita al SIN el código único de facturación diaria (CUFD) LINK CUFD, que le habilita la emisión de Facturas por un periodo de 24 horas.
2.   El SIN realiza verificaciones a la información del emisor y devuelve los códigos de Verificación y CUFD, además de la dirección de la sucursal o casa matriz.
3.   El Sistema Informático de Facturación del Contribuyente utiliza el CUFD. para emitir las Facturas en formato XML, obtención del hash del archivo y posteriormente realiza el envío del mismo al SIN.
4.   El SIN recibe la solicitud de recepción y procede a validar la cabecera de recepción para devolver la siguiente información:
a)  Si la validación esta correcta y es un proceso individual en línea, retorna código de recepción y el estado es recibido.
b) Si la validación es correcta y es un proceso por paquete de contingencia o masivo, retorna el código de recepción.
c)  Si la validación presenta errores, retorna una lista de códigos y mensajes de error para que el emisor proceda a su corrección y posterior reenvío.
5.   Si el cliente desea tener un respaldo de la emisión la Factura Digital, el emisor podrá imprimir la Factura.
6.   Cuando la emisión de la Factura sea por paquete de contingencia o por emisión masiva, el SIN validará la información contenida en la Factura Digital, como resultado procederá a:
a)  Registrar y consolidar la Factura Digital para la emisión por contingencia o masiva en caso de no existir errores.
b) En caso de existir errores, se observa el paquete, se registran las facturas correctas y se rechazan las que contengan los errores. En caso de que el tipo de documento sea NIT y el  numero de documento no sea valido o no haya sido validado previamente a través del método de verificación de NIT, el emisor podrá enviar el código de excepción para que la factura no sea rechazada.
7.   El emisor utilizará el código de recepción para realizar la validación de la Factura Digital enviada,solo cuando su emisión sea en paquete por contingencia o emisión masiva. 
8.   El SIN retorna los resultados del proceso de validación descritos en el punto 6. En caso de existir observaciones deberá subsanarlos y posteriormente reenviar la Factura Digital.

CONTENIDO LINK CUFD

Solicitud del Código Único de Facturación Diaria - CUFD
 
Conforme a normativa vigente el proceso de obtención del Código Único de Facturación Diaria (CUFD) para el Sistema Informático de Facturación autorizado debe realizarse diariamente. Este código habilita el sistema del Sujeto Pasivo para la emisión de Facturas Digitales durante un periodo de vigencia de 24 horas.
 
A continuación se describen los parámetros de entrada y salida a ser utilizados:
 
Nombre Método	solicitudCufd      
Entrada	Tipo Dato	Obligatorio	Descripción	Salida	Tipo Dato
codigoAmbiente	Numérico	Si	Describe el tipo de ambiente utilizado, los valores permitidos son:
        Producción: 1
        Pruebas y Piloto: 2	codigoCUFD	Alfanumérico
codigoSistema	Alfanumérico	Si	Código de Sistema que le fue asignado al momento de realizar la solicitud de autorización.	fechaVigencia	Fecha UTC Extendida
Nit	Numérico	Si	NIT perteneciente al emisor de la factura.	transaccion	Boolean
codigoModalidad	Numérico	Si	Modalidad utilizada por el Sistema Informático de Facturación para la emisión de facturas, pudiendo ser:
       Electrónica en Línea: 1
     Computarizada en Línea: 2	codigosRespuestas	DTO[codigosRespuesta]
Cuis	Alfanumérico	Si	Valor único para una sucursal y/o punto de venta que se obtiene al realizar el inicio de uso de sistemas.	codigoControl	Alfanumérico
codigoSucursal	Numérico	Si	Valor que identifica la sucursal donde se realiza la emisión de la Factura:
        Casa Matriz: 0
        Sucursal: 1,2,..,n	 direccion	Alfanumérico
codigoPuntoVenta	Numérico	No	Solo se envía este valor cuando se desea obtener un CUFD para el punto de venta (1, 2,..,n). Caso contrario enviar 0.	 	 
Nota:
Este servicio requiere el uso del Token Delegado.
    Al obtener el CUFD podría recibir una alerta del sistema informando sobre  la proximidad del vencimiento del CUIS y la necesidad de su renovación. 


--- FIN CONTENIDO LINK CUFD  ---

CONTENIDO DE LINK CUIS

Solicitud del Código Único de Inicio de Sistemas - CUIS
 
Conforme a normativa vigente el proceso de obtención del CUIS para una sucursal o punto de venta debe realizarse mediante el Sistema Informático de Facturación autorizado, a través del Servicio Web disponible. 
 
El servicio implementado posee un objeto denominado SolicitudCuis el cual contiene la información descrita en el siguiente cuadro:
 
Nombre Método	cuis    
Entrada	Tipo Dato	Obligatorio	Descripción	Salida	Tipo Dato
codigoAmbiente	Numérico	Si	Describe el tipo de ambiente utilizado, los valores permitidos son:
Producción: 1
Pruebas y Piloto: 2	codigoCUIS	Alfanumérico
codigoSistema	Alfanumérico	Si	Código de Sistema que le fue asignado al momento de realizar la solicitud de autorización.	transaccion	Boolean
nit	Numérico	Si	NIT perteneciente al emisor de la Factura. 	CodigosRespuestas	DTO[CodigosRespuesta]
codigoModalidad	Numérico	Si	Modalidad utilizada por el Sistema Informático de Facturación para la emisión de Facturas, pudiendo ser:
Electrónica en Línea: 1
Computarizada en Línea: 2
 	fechaVigencia	Fecha UTC extendida
codigoSucursal	Numérico	Si	Valor que identifica la sucursal donde se realiza la emisión de la Factura:
Casa Matriz: 0
Sucursal: 1,2,..,n	 	 
codigoPuntoVenta	Numérico	No	Solo se envía cuando la transacción se realiza utilizando un punto de venta. Caso contrario enviar 0.	 	 
Notas:
Este servicio requiere el uso del Token Delegado.
El Código Unico de Inicio de Sistemas (CUIS) puede ser renovado a partir del quinto día anterior a su vencimiento. El sistema alertara sobre la proximidad del vencimiento del CUIS cuando se obtenga un CUFD y la fecha de vigencia este próxima a su fin.
Por otro lado, se debe tomar en cuenta que una vez renovado el CUIS y para poder seguir operando con normalidad, debe también obtenerse un nuevo CUFD.  


FIN DE LINK CUIS
Portal Web en Línea
Modalidad de Facturación implementada por la Administración Tributaria en su Página Web para todos los contribuyentes previa suscripción y acceso con credenciales de acceso autorizadas para la emisión de facturas en linea. Las Facturas Digitales emitidas a través de esta modalidad, son validadas y registradas en la Base de Datos de la Administración Tributaria. 
Nota: Esta modalidad excepcionalmente podrá ser utilizada a manera de contingencia para las modalidades Computarizada y Electrónica en línea.
Características:
•	Impresión de la Factura de manera opcional.
 Esquema de Interoperabilidad
 
Procedimiento
1.	El Contribuyente solicita la autorización para el uso de esta modalidad a través de la opción correspondiente en el portal de la Administración Tributaria.
2.	El SIN valida y autoriza la solicitud para poder emitir Facturas Digitales a través del Portal Web.
3.	El SIN habilita la modalidad, para el contribuyente.
4.	El contribuyente registra productos, clientes y sincroniza catálogos.
5.	El Contribuyente emite las Facturas o Nota Crédito Débito.
6.	El SIN Genera y almacena el archivo XML.
7.	El SIN envía al comprador el XML de la Factura o Nota Crédito Débito  y el formato PDF para su impresión de manera opcional.
Contingencia
Para poder utilizar esta modalidad como contingencia, el contribuyente deberá solicitar la autorización a través de la opción correspondiente en el portal web de la Administración tributaria.
1.	Ingresar a la opción Autorización de Portal Web como Contingencia.
2.	Seleccionar el Sistema Autorizado asociado al contribuyente que utilizara esta modalidad como respaldo.
3.	El SIN valida y autoriza la solicitud para poder emitir Facturas Digitales a través del Portal Web.
4.	El SIN habilita la modalidad excepcional, para el contribuyente.
5.	El contribuyente registra productos, clientes y sincroniza catálogos.
6.	El contribuyentes emite la factura a través de la modalidad.
 Tipos de Documentos Fiscales
 
 Se consideran cuatro tipos de Documentos Fiscales:
1.	Facturas con derecho a crédito fiscal. Son aquellas Facturas que generan crédito fiscal para el Comprador y débito fiscal para el vendedor.
2.	Facturas sin derecho a crédito fiscal. Son aquellas Facturas que no generan crédito fiscal para el Comprador, ni débito fiscal para el vendedor.
3.	Documento de ajuste. Normativamente existe la Nota de Crédito - Débito como documento de ajuste del crédito y débito fiscal, cuando se realice una devolución parcial o total o rescisión de contrato, pudiendo emitirse hasta dieciocho (18) meses después de generada la factura original y la Nota de Conciliación para realizar ajustes en el Crédito y en el Débito Fiscal de los Sujetos Pasivos del IVA por transacciones facturadas en periodos anteriores no mayores a doce (12) meses.
4.	Documento Equivalente. Es el documento, que si bien no se constituye en una Factura o Nota Fiscal propiamente dicha, su emisión implica la realización de una operación gravada por el IVA, dando lugar al cómputo del Crédito Fiscal para el comprador. 
Documentos por Sector
 
En función del tipo de sector económico y a la clasificación normativa a la que pertenece, una Factura Electrónica debe ser construida y enviada a la Administración Tributaria utilizando los Servicios Web correspondientes. 
Las Facturas por Sector son las siguientes:
  

Código	Descripción	Características	Tipo Factura/Documento
1	Factura de Compra y Venta
Habilitada para transacciones por bienes o servicios en general, incluyen línea blanca, negra y cualquier actividad que involucre un intercambio de estos.	Con derecho a crédito fiscal
2	Factura de Alquiler de Bienes Inmuebles
Habilitado para alquiler de bienes inmuebles propios.	Con derecho a crédito fiscal
3	Factura Comercial de Exportación
Habilitada para transacciones de exportación de bienes, no se incluyen minerales.	Sin derecho a crédito fiscal
4	Factura de Comercial de Exportación en Libre Consignación
Habilitada para transacciones de exportación de bienes en libre consignación.	Sin derecho a crédito fiscal
5	Factura de Venta en Zona Franca
Habilitada para transacciones en zonas francas a concesionario o usuario.	Sin derecho a crédito fiscal
6	Factura de  Servicio Turístico y Hospedaje
Habilitada para la exportación de servicios turísticos y hospedaje, alcanzados por el Artículo 30 de la Ley N° 292.	Sin derecho a crédito fiscal
7	Factura de Seguridad Alimentaria y Abastecimiento
Habilitada para comercialización de alimentos exentos de impuestos.	Sin derecho a crédito fiscal
8	Factura  Tasa Cero Venta de Libros y Transporte Internacional de Carga por Carretera
Habilitada para los que se encuentren alcanzados por el Régimen Tasa Cero en el IVA. Para la venta de libros nacionales o importados y publicaciones oficiales. Por el transporte internacional de carga por carretera.	Sin derecho a crédito fiscal
9	Facturas de Compra y Venta de Moneda Extranjera
Habilitada para transacciones de compra/venta de moneda extranjera.	Sin derecho a crédito fiscal
10	Factura Dutty Free
Habilitada para los que realicen ventas en tiendas libres o Dutty Free.	Sin derecho a crédito fiscal
11	Factura Sectores Educativos
Habilitada para la facturación de unidades educativas preescolares, primaria, secundaria, de educación superior, institutos educativos, enseñanza de adultos y otros tipos de enseñanza.	Con derecho a crédito fiscal
12	Factura de Comercialización de Hidrocarburos
Habilitada para la venta de combustible diésel oíl, venta de combustible gasolina especial y/o gasolina Premium, venta de combustible para automotores.	Con derecho a crédito fiscal
13	Factura de Servicios Básicos
Habilitada para la distribución de agua, electricidad y Cooperativas Telefónicas que dentro de sus operaciones utilicen otras tasas.	Con derecho a crédito fiscal
14	Factura Productos Alcanzados por el ICE
Habilitada a los productos que estén alcanzados por el ICE, por ejemplo: cigarrillos, bebidas alcohólicas y otros.	Con derecho a crédito fiscal
15	Factura de Entidades Financieras
Habilitada para entidades de carácter financiero, por ejemplo: bancos, cooperativas y otros. No incluyen casas de cambio.	Con derecho a crédito fiscal
16	Factura de Hoteles
Habilitada para hoteles, hostales, alojamientos y otros, cuando los huéspedes sean de origen nacional o residentes en Bolivia.	Con derecho a crédito fiscal
17	Factura de Hospitales/Clínicas
Habilitada para hospitales y clínicas, deberá incluir información de los pacientes y médicos cuando sea una intervención quirúrgica.	Con derecho a crédito fiscal
18	Factura de Juegos de Azar
Habilitada para las actividades que incluyan sorteos, concursos o juegos de azar.	Con derecho a crédito fiscal
19	Factura de Hidrocarburos Alcanzada IEHD
Habilitada para empresas dedicadas a la comercialización de hidrocarburos o sus derivados en primera fase	Con derecho a crédito fiscal
20	Factura Comercial de Exportación de Minerales
Habilitada para transacciones de exportación de minerales.	Sin derecho a crédito fiscal
21	Factura de Venta de Minerales
Habilitada para la venta de minerales en el territorio nacional.	Con derecho a crédito fiscal
22	Factura de Telecomunicaciones
Habilitada para servicios de telecomunicaciones.	Con derecho a crédito fiscal
23	Factura Prevalorada
Habilitada para actividades de cobro de tasa aeroportuaria y terrestre, y para entradas a ferias.	Con derecho a crédito fiscal
24	Nota de Crédito - Débito
Habilitada para realizar ajustes en el crédito y débito fiscal de los Sujetos Pasivos o compradores.	Documento de Ajuste
28	Factura Comercial de Exportación de Servicios
Habilitada para Contribuyentes que Exportan Servicios	Sin derecho a crédito fiscal
29	Nota de Conciliación
Habilitada para realizar ajustes en el Crédito y en el Débito Fiscal de los Sujetos Pasivos del IVA por transacciones facturadas en periodos anteriores no mayores a doce (12) meses, por servicios de energía eléctrica, telecomunicaciones, agua potable e hidrocarburos.	 Documento de Ajuste
30	Boleto Aéreo
Habilitada para el registro de pasajes aéreos.	 Documento Equivalente
31	Factura de Suministro de Energía
Habilitada para la recarga de Energía Eléctrica a Vehículos Eléctricos.	 Con derecho a crédito fiscal
33	Factura Tasa Cero IVA Ley N° 1613
 Habilitada para la importación y comercialización de bienes de capital y plantas industriales	Sin derecho a crédito fiscal
34	Factura de Seguros
Habilitada para transacciones específicas del Sector Seguros	Con derecho a crédito fiscal
35	Factura Compra Venta Bonificaciones
Habilitada para transacciones por bienes o servicios en general, incluyen línea blanca, negra y cualquier actividad que involucre un intercambio de estos. Permite descuento total en algunos de los productos en el detalle.	Con derecho a crédito fiscal
36	Factura Prevalorada Sin Derecho Crédito Fiscal
Habilitada para actividades de realización de Espectáculos Públicos Eventuales, Zona Franza e Importación y Venta de Libros	Sin derecho a crédito fiscal
37	Factura de Comercialización de GNV
Habilitada para la venta de Gas Natural Vehicular	Con derecho a crédito fiscal
38	Factura Hidrocarburos No Alcanzada IEHD
Habilitada para todas aquellas actividades exentas del pago del IEHD	Con Derecho a crédito fiscal
39	Factura de Comercialización De GN y GLP
Habilitada para la comercialización de Gas Natural y Gas Licuado de Petróleo	Con Derecho a Crédito Fiscal
40	Factura de Servicios Básicos Zona Franca
Habilitada para la distribución de agua, electricidad o cualquier servicio que se considere básico, de acuerdo a normativa vigente en Zona Franca	Sin Derecho a Crédito Fiscal
41	Factura de Compra Venta Tasas
Habilitada para transacciones por bienes o servicios en general, incluyen línea blanca, negra y cualquier actividad que involucre un intercambio de estos, permite incluir tasas no sujetas a Crédito Fiscal	Con Derecho a Crédito Fiscal
42	Factura Alquiler Zona Franca
Habilitada para el alquiler de Bienes Inmuebles en zona Franca	Sin Derecho a Crédito Fiscal
43	Factura Comercial de Exportación Hidrocarburos
 Habilitada para transacciones de exportación del sector Hidrocarburos adecuado a legislativa vigente	 Sin Derecho a Crédito Fiscal
44	Factura Importación y Comercialización de Lubricantes
Habilitada para empresas que importen de forma directa lubricantes y que comercialicen los mismos al consumidor final o distribuidor (No utilizada para servicios, solo venta de productos)	Con Derecho a Crédito Fiscal
45	Factura Comercial de Exportación Precio Venta
Habilitada para transacciones de exportación de bienes, no se incluye a la exportación de minerales.	Sin Derecho a Crédito Fiscal
46	Factura Sector Educativo Zona Franca
Habilitada para la facturación de unidades educativas preescolares, primaria, secundaria, de educación superior, institutos educativos, enseñanza de adultos y otros tipos de enseñanza al interior de Zona Franca	Sin Derecho a Crédito Fiscal
47	Nota Crédito Débito Descuentos
Habilitada para realizar ajustes en el crédito y débito fiscal de los Sujetos Pasivos o compradores a facturas afectadas con un Descuento Adicional	Documento de Ajuste
48	Nota Crédito Débito ICE
Habilitada para realizar ajustes en el crédito y débito fiscal de los Sujetos Pasivos o compradores a facturas emitidas con ICE	Documento de Ajuste
49	Factura Telecomunicaciones Zona Franca
Habilitada para servicios de telecomunicaciones en Zona Franca	Sin Derecho a Crédito Fiscal
50	Factura Hospitales/ Clínicas Zona Franca
Habilitada para hospitales y clínicas en Zona Franca, deberá incluir información de los pacientes y médicos cuando sea una intervención quirúrgica.	Sin Derecho a Crédito Fiscal
51	Factura Engarrafadoras
Habilitada para empresas dedicadas a la recarga o llenado de gas en Garrafas y Contenedores	Con Derecho a Crédito Fiscal
52	Factura Venta Minerales Banco Central
Habilitada para la Venta de Minerales al Banco Central y solo en la modalidad electrónica	Sin Derecho a Crédito Fiscal
53	Factura Importación y Comercialización de Lubricantes IEHD
Habilitada para empresas que importen de forma directa lubricantes y que comercialicen los mismos al consumidor final o distribuidor (No utilizada para servicios, solo venta de productos)	Con Derecho a Crédito Fiscal
54	Factura Compra-Venta de Insumos para la Producción de Biodiésel y/o Diésel Ecológico
Habilitada para ventas en el mercado interno de productos de soya, cusi, totaí y otras especies cultivados o silvestres, y/o sus derivados, destinadas exclusivamente a la producción de biodiésel y/o diésel ecológico para las plantas de Yacimientos Petrolíferos Fiscales Bolivianos - YPFB	Sin Derecho a Crédito Fiscal
55	Factura Comercialización de Combustible
Habilitada para la venta de combustible para automotores.	Con Derecho a Crédito Fiscal
 
Códigos de Autorización
 
Los Códigos de Autorización otorgados por el SIN o generados por el Sistema Informático de Facturación autorizan la emisión de Documentos Fiscales en función a parámetros establecidos. De acuerdo a su característica podrán o no ser consignados en los documentos fiscales autorizados por la Administración Tributaria, de acuerdo a la modalidad de facturación utilizada pueden ser:
CUIS (Código Único de Inicio de Sistemas). Dato alfanumérico generado por la Administración Tributaria que identifica la relación entre el Sistema de Facturación, credenciales, contribuyente, sucursal y opcionalmente al punto de venta. Tiene una vigencia de  365 días calendario. Para su obtención se utiliza Token para validar la autenticidad del contribuyente.
CUFD (Código Único de Facturación Diaria). Dato alfanumérico generado por la Administración Tributaria con la información del Sistema de Facturación, que permite al Sujeto Pasivo o Tercero Responsable la emisión de Documentos Fiscales Electrónicos durante 24 horas. Para su obtención se utiliza Token para validar la autenticidad del contribuyente.
CUF (Código Único de Factura). Generado de forma automática al momento de la emisión de la Factura por el Sistema Informático de Facturación, en las Modalidades de Facturación en Línea,  permite la individualización de cada factura. 

CAED (Código Autorización para la Emisión de Documentos Fiscales). Generado por la Administración Tributaria para la emisión de Documentos Fiscales en las modalidades de facturación Manual y Prevalorada Preimpresa.
CAFC (Código Autorización Facturas Contingencia). Generado por la Administración Tributaria para la impresión y posterior emisión de facturas de contingencia. Se lo obtiene cuando al efectuar la solicitud de impresión de facturas manuales de contingencia.
Número de Autorización. Generado Automáticamente para la emisión de Facturas en la modalidad Computarizada SFV.
Nota. En el caso del uso de Prevaloradas en Línea, el sistema informático de facturación deberá solicitar la autorización de emisión para este tipo de documento, considerando el periodo, los rangos de emisión y precios fijos para dichos documentos. Esta solicitud devolverá un código de autorización que deberá ser incluido en la solicitud de emisión.
En los registros obligatorios a enviar a la Administración Tributaria, excepto en el Registro de Compras y Ventas o aplicativos SIAT o Mis facturas, donde se solicite el Numero de Autorización deberá registrarse el valor noventa y nueve (99) cuando las citadas facturas consignen Códigos de Autorización emitidas en la Modalidad de Facturación Electrónica en Línea, Computarizada en Línea o Portal Web en Línea o Modalidad Manual del Sistema de Facturación vigente.


