import '../repositories/producto_repository.dart';

class CambiarEstadoProducto {
  final ProductoRepository repository;

  CambiarEstadoProducto(this.repository);

  Future<void> call({required int productoId, required bool activo}) async {
    if (productoId <= 0) {
      throw ArgumentError('El identificador del producto no es válido.');
    }
    await repository.cambiarEstadoProducto(productoId, activo);
  }
}
