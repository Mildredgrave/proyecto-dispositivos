import '../entities/producto.dart';
import '../repositories/producto_repository.dart';
import 'validar_datos_producto.dart';

class RegistrarProducto {
  final ProductoRepository repository;

  RegistrarProducto(this.repository);

  Future<void> call(Producto producto) async {
    validarDatosProducto(producto);
    if (producto.stockActual != 0) {
      throw ArgumentError(
        'El stock inicial debe registrarse mediante un movimiento de entrada.',
      );
    }

    await repository.insertarProducto(producto);
  }
}
