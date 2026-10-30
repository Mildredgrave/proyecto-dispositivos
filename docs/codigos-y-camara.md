# Códigos de barras, QR y cámara

## Contenido de las etiquetas

En el detalle del producto se representan:

- **Code 128:** generado por `barcode_widget`.
- **QR:** generado por `barcode_widget`.
- **PDF imprimible:** `EtiquetaProductoPdf` genera una página de 100 × 85 mm,
  con nombre, Code 128, QR y el código legible.

Ambos símbolos codifican exclusivamente `Producto.codigoUnico`. No contienen
nombre, precios, categoría ni existencias. El escaneo usa ese valor como clave
para consultar el inventario local; por tanto, otro dispositivo sin el mismo
catálogo no obtiene los datos del producto leyendo el QR.

El PDF se puede preparar para compartir o enviarse a la interfaz de impresión
mediante `printing`. La impresión física depende del sistema operativo y de una
impresora disponible.

## Lectura y permisos

`EscanerPage` usa `mobile_scanner` y recibe los valores de la cámara. Al detectar
el primer valor no vacío, cierra la pantalla y devuelve el código a la pantalla
del catálogo. El lector evita enviar más de una lectura durante esa sesión.
Si el plugin informa un error de cámara, la interfaz explica que se revisen los
permisos y ofrece volver a la búsqueda manual.

Android declara `android.permission.CAMERA` en el manifiesto principal. La
aplicación depende de `mobile_scanner` y del flujo de permisos de la plataforma;
no implementa una pantalla propia para solicitar permiso. Si el permiso se
deniega o no hay cámara, se puede buscar por nombre/código o volver desde el
error del escáner.

## Verificación manual

1. En un teléfono Android, conceder permiso de cámara y abrir el botón de
   escaneo desde el inventario.
2. Escanear una etiqueta de un producto ya registrado y comprobar que se abre
   su detalle.
3. Escanear un código desconocido y comprobar que se ofrece crear el producto
   con ese código precargado.
4. Denegar permiso o usar un dispositivo sin cámara y comprobar la opción de
   regresar a la búsqueda.
5. Abrir el detalle, compartir/imprimir la etiqueta y confirmar que el QR
   contiene el código, no las existencias.

Estas pruebas requieren dispositivo/cámara o plataforma nativa; no están
cubiertas por las pruebas unitarias automatizadas del repositorio.
