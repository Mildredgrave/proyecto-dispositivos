import '../entities/producto.dart';
import '../repositories/producto_repository.dart';
import 'validar_datos_producto.dart';

class ActualizarProducto {
  final ProductoRepository repository;

  ActualizarProducto(this.repository);

  Future<void> call(Producto producto) async {
    if (producto.id == null || producto.id! <= 0) {
      throw ArgumentError(
        'No se puede actualizar un producto sin identificador.',
      );
    }
    validarDatosProducto(producto);

    await repository.actualizarProducto(producto);
  }
}
