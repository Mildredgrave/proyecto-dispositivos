import '../entities/producto.dart';

void validarDatosProducto(Producto producto) {
  if (producto.codigoUnico.trim().isEmpty) {
    throw ArgumentError('El código único del producto es obligatorio.');
  }
  if (producto.nombre.trim().isEmpty) {
    throw ArgumentError('El nombre del producto es obligatorio.');
  }
  if (producto.categoriaNombre?.trim().isNotEmpty != true) {
    throw ArgumentError('La categoría del producto es obligatoria.');
  }
  if (!producto.precioCompra.isFinite ||
      producto.precioCompra <= 0 ||
      !producto.precioVenta.isFinite ||
      producto.precioVenta <= 0) {
    throw ArgumentError('Los precios deben ser números mayores a cero.');
  }
  if (producto.stockMinimo < 0) {
    throw ArgumentError('El stock mínimo no puede ser negativo.');
  }
}
