# Modelo de datos y persistencia

## Almacenamiento

`DatabaseHelper` abre `inventario_inteligente.db` y declara el esquema versión
3. La primera creación configura las tablas y triggers. Al actualizar desde
una versión menor que 3, la migración convierte `cantidad` de movimientos
`AJUSTE` al stock resultante y recrea las reglas de inmutabilidad de
movimientos.

La base local es la fuente de verdad de existencias; no hay sincronización,
exportación de restauración ni copias remotas automáticas. `categoriaNombre` es
un valor de consulta derivado mediante `JOIN`, no una columna de `productos`.

## Tablas y diccionario

### `categorias`

| Campo | Tipo SQLite | Nulo | Descripción |
| --- | --- | --- | --- |
| `id` | `INTEGER` | No | Clave primaria autoincremental. |
| `nombre` | `TEXT` | No | Nombre de la categoría. El datasource busca coincidencias sin distinguir mayúsculas/minúsculas antes de crear una nueva. |

### `productos`

| Campo | Tipo SQLite | Nulo | Descripción |
| --- | --- | --- | --- |
| `id` | `INTEGER` | No | Clave primaria autoincremental. |
| `codigoUnico` | `TEXT` | No | Código para búsqueda y etiquetas; índice `UNIQUE` y triggers evitan duplicados sin distinguir mayúsculas/minúsculas. |
| `nombre` | `TEXT` | No | Nombre visible del producto. |
| `descripcion` | `TEXT` | Sí | Descripción opcional. |
| `categoriaId` | `INTEGER` | Sí en SQL | Identificador de categoría; referencia declarada a `categorias.id`. La lógica de alta exige categoría. |
| `precioCompra` | `REAL` | No | Precio de compra unitario. |
| `precioVenta` | `REAL` | No | Precio de venta unitario. |
| `stockActual` | `INTEGER` | No | Existencias disponibles; cambia al registrar movimientos. |
| `stockMinimo` | `INTEGER` | No | Umbral de alerta, igual o mayor a cero. |
| `fotografia` | `TEXT` | Sí | Ruta de archivo local de la fotografía. |
| `activo` | `INTEGER` | No | Booleano SQLite: `1` activo, `0` inactivo; predeterminado `1`. |

### `movimientos`

| Campo | Tipo SQLite | Nulo | Descripción |
| --- | --- | --- | --- |
| `id` | `INTEGER` | No | Clave primaria autoincremental. |
| `productoId` | `INTEGER` | No | Producto relacionado, referencia declarada a `productos.id`. |
| `tipo` | `TEXT` | No | `ENTRADA`, `SALIDA` o `AJUSTE`; validado por la aplicación. |
| `cantidad` | `INTEGER` | No | Unidades de entrada/salida o conteo físico total en ajuste. |
| `stockAnterior` | `INTEGER` | No | Stock validado antes del movimiento. |
| `stockResultante` | `INTEGER` | No | Stock calculado después del movimiento. |
| `motivo` | `TEXT` | No | Justificación o motivo obligatorio. |
| `responsable` | `TEXT` | No | Persona responsable, obligatoria. |
| `fechaHora` | `TEXT` | No | Fecha y hora ISO 8601 del registro. |

## Relaciones y reglas de integridad

- Una categoría puede estar asociada a varios productos; la relación usa
  `productos.categoriaId`.
- Un producto puede tener varios movimientos; cada movimiento usa
  `movimientos.productoId`.
- El código SQL declara claves foráneas. `DatabaseHelper` no configura
  explícitamente `PRAGMA foreign_keys = ON`; por tanto, no se debe asumir que
  SQLite las hace cumplir en tiempo de ejecución. Las operaciones de la
  aplicación validan los productos antes de registrar movimientos y los
  triggers impiden borrar productos con historial.
- Triggers bloquean actualización y eliminación de movimientos, eliminación de
  productos con movimientos y códigos duplicados sin distinguir
  mayúsculas/minúsculas.

## Otros archivos persistentes

- Fotografías seleccionadas se copian al directorio privado de documentos de
  la app, dentro de `fotografias/`; la base guarda la ruta local. Una ruta puede
  dejar de ser válida si el archivo desaparece o se reinstala/migra la app.
- El CSV se crea en el directorio privado de documentos antes de invocar el
  diálogo de compartir del sistema.
- El PDF de etiqueta se genera en memoria y se entrega a la API de compartir o
  impresión; no se registra como dato del producto.
