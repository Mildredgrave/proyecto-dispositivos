# Objetivo, alcance y reglas de negocio

## Objetivo

Inventario Inteligente permite mantener un catálogo local de productos y
controlar sus existencias mediante movimientos trazables. Cada producto se
identifica por un código único que también se puede representar con un código
de barras Code 128 o un QR.

## Alcance funcional

La aplicación móvil permite:

- Crear, consultar, editar, activar y desactivar productos.
- Buscar productos por nombre o código y consultar un producto escaneando su
  etiqueta.
- Registrar entradas, salidas y ajustes de existencias con motivo y
  responsable.
- Consultar y filtrar el historial de movimientos.
- Ver alertas de stock bajo, calcular una estimación del valor del inventario y
  exportar el catálogo como CSV.
- Generar, compartir e imprimir etiquetas PDF.

Los datos se guardan en SQLite en el dispositivo. No se implementan cuentas,
autenticación, roles, sincronización entre dispositivos, servidor ni copias de
seguridad remotas. La aplicación no reemplaza un sistema contable.

## Requisitos

- Flutter con Dart SDK compatible con `^3.13.7`, según
  [`pubspec.yaml`](../inventario_inteligente/pubspec.yaml).
- Android SDK y las herramientas de compilación configuradas para Flutter.
  Android es el destino de APK documentado y validado en este repositorio.
- Permiso de cámara concedido por el usuario para escanear códigos.
- Dispositivo o emulador para ejecutar la aplicación; una cámara física es
  necesaria para verificar el escaneo real.

## Reglas de negocio

1. Código, nombre y categoría son obligatorios. Al guardar, el código se
   recorta y se convierte a mayúsculas; no se aceptan códigos duplicados sin
   distinguir mayúsculas/minúsculas.
2. La categoría se busca sin distinguir mayúsculas/minúsculas y se crea si no
   existe.
3. Los precios de compra y venta deben ser finitos y mayores que cero. El stock
   mínimo debe ser cero o mayor.
4. Un producto nuevo comienza con stock cero. Su stock inicial se registra con
   un movimiento de entrada, no desde el formulario del producto.
5. El stock existente solo cambia por movimientos. Las entradas y salidas
   requieren una cantidad mayor que cero; una salida no puede superar el stock
   disponible.
6. Un ajuste captura el conteo físico total (que puede ser cero), no una
   diferencia. El movimiento conserva el stock previo y el resultante.
7. Todo movimiento requiere producto existente y activo, tipo válido, motivo,
   responsable y fecha/hora. El stock se vuelve a comprobar al guardar para
   detectar formularios abiertos con información obsoleta.
8. Guardar un movimiento y actualizar existencias son una única transacción.
   Si cualquiera de los pasos falla, SQLite revierte ambos.
9. Los movimientos confirmados no se editan ni eliminan. Un producto con
   movimientos no se elimina definitivamente; se conserva su historial y se
   puede desactivar.
10. Un producto inactivo no admite movimientos. Activarlo permite volver a
    operar con él.
11. El stock se considera bajo cuando `stockActual <= stockMinimo`.
12. El valor estimado suma `stockActual * precioCompra` para cada producto; es
    una estimación informativa, no una valoración contable.
13. El QR y el Code 128 contienen únicamente el código del producto. El stock
    se obtiene de la base local después de identificar el producto.
14. El CSV exporta todos los productos cargados, incluyendo los inactivos, con
    código, nombre, descripción, categoría, precios, existencias y estado.
