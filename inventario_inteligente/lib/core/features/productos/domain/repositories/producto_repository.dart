import '../entities/producto.dart';

abstract class ProductoRepository {
  Future<List<Producto>> obtenerProductos();
  Future<void> insertarProducto(Producto producto);
  Future<void> actualizarProducto(Producto producto);
  Future<void> cambiarEstadoProducto(int id, bool activo);
  Future<Producto?> obtenerProductoPorCodigo(String codigoUnico);
}
