# inventario_inteligente

## Reglas de negocio del inventario

- Las cantidades de entrada y salida deben ser mayores que cero.
- Una salida no puede superar el stock disponible. El stock se vuelve a validar
  dentro de la transacción para evitar registrar movimientos con datos
  desactualizados.
- Un producto con movimientos no se puede eliminar definitivamente. Se puede
  desactivar y conservar su historial.
- Los movimientos confirmados no se pueden editar ni eliminar; los errores se
  corrigen registrando un nuevo movimiento.
- El registro de cada movimiento y la actualización de existencias se ejecutan
  dentro de una única transacción de base de datos.
- El stock de un producto existente solo se modifica mediante movimientos, no
  desde el formulario de edición.
- Los ajustes guardan como cantidad el conteo físico; el stock anterior y el
  resultado quedan registrados por separado.
- Todo movimiento requiere motivo y responsable. La fecha y hora se muestran
  en el historial.
- Los códigos de producto se guardan en mayúsculas y no se permiten duplicados
  que solo difieran en mayúsculas/minúsculas.
- Las etiquetas con nombre, código Code 128 y QR se pueden compartir como PDF o
  enviar a impresión. El QR contiene solo el código del producto, no el stock.
- El listado permite buscar productos y marca como alerta los que tienen
  existencias iguales o inferiores al mínimo.
- El historial se puede filtrar por producto, tipo de movimiento y rango de
  fechas.
- El CSV contiene todos los productos y sus datos de categoría, existencias,
  precios y estado; puede compartirse desde el dispositivo.
- El valor estimado del inventario suma existencias por precio de compra
  registrado, sin aplicar métodos contables de valoración.
- Los productos se pueden crear, consultar, editar y desactivar. La categoría
  es obligatoria y se crea automáticamente si no existe; la fotografía es
  opcional.
- Un producto nuevo comienza con cero existencias y abre el formulario para
  registrar el stock inicial como una entrada trazable.
