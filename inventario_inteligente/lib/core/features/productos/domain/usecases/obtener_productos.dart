import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

class ObtenerProductos {
  final ProductoRepository repository;

  ObtenerProductos(this.repository);

  Future<List<Producto>> call() async {
    return await repository.obtenerProductos();
  }
}
