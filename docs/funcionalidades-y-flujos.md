# Funcionalidades, estado y flujo de información

## Catálogo de productos

La pantalla principal muestra productos, código, categoría, stock, mínimo,
estado y precio de venta. Busca sin distinguir mayúsculas/minúsculas por
nombre o código y destaca los productos con stock igual o inferior al mínimo.
Las acciones permiten consultar detalles, editar y activar/desactivar. El
formulario valida datos obligatorios, precios y stock mínimo; permite
seleccionar fotografía desde la galería. Al editar, el stock es de solo
lectura.

La consulta de detalle muestra información, etiqueta Code 128 y QR y ofrece
registrar entrada/salida, compartir etiqueta PDF o imprimirla. Los ajustes se
seleccionan desde el formulario de movimientos.

## Movimientos de existencias

- **Entrada:** `stockResultante = stockAnterior + cantidad`.
- **Salida:** `stockResultante = stockAnterior - cantidad`; no se permite
  resultado negativo.
- **Ajuste:** `cantidad` es el conteo físico y `stockResultante = cantidad`.

Todo movimiento almacena el estado previo y posterior, motivo, responsable y
fecha/hora. Al guardar, el datasource vuelve a consultar el registro para
verificar que el producto siga activo y que el stock no haya cambiado desde que
se abrió el formulario.

## Historial e informes

El historial se ordena por fecha descendente y se filtra por producto, tipo y
rango inclusivo de fechas. La fecha final se interpreta hasta el final de ese
día. El informe de valor suma `existencias × precio de compra`. La exportación
CSV incluye catálogo activo e inactivo y los campos indicados en
[Modelo de datos](./modelo-de-datos.md).

## Escaneo

El lector devuelve el primer valor no vacío detectado. Si el código coincide
con un producto, abre su detalle. Si no coincide, ofrece crear un producto con
ese código precargado. El lector no modifica existencias automáticamente.

## Gestión del estado

`ProductoProvider` (`ChangeNotifier`) mantiene:

- Lista completa de productos y lista filtrada.
- Texto de búsqueda actual.
- Indicador de carga y último error.

Al cargar y después de operaciones del catálogo, el provider actualiza las
listas y notifica consumidores. Las pantallas locales mantienen estado de
formularios, selección de filtros, proceso de guardado y resultado de escaneo.
El historial se carga en estado local de su página. No existe un almacén global
de movimientos.

## Flujo de datos representativo

```text
Formulario → validación de presentación → caso de uso
           → contrato de repositorio → implementación/modelo
           → datasource → transacción SQLite
           → recarga de ProductoProvider → interfaz actualizada
```

La lectura del scanner sigue otra ruta: cámara → valor decodificado →
consulta de código en SQLite → detalle del producto o propuesta de alta.
Compartir CSV/PDF delega al mecanismo nativo de compartir; no sincroniza datos
con un servidor.
