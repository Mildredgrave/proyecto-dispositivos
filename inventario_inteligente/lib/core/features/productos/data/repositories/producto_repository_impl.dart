import '../../domain/entities/producto.dart';
import '../../domain/repositories/producto_repository.dart';
import '../datasource/producto_local_datasource.dart';
import '../models/producto_model.dart';

class ProductoRepositoryImpl implements ProductoRepository {
  final ProductoLocalDataSource localDataSource;

  ProductoRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Producto>> obtenerProductos() async {
    final productoModels = await localDataSource.obtenerProductos();
    return productoModels; // ProductoModel extiende de Producto, por lo que es compatible
  }

  @override
  Future<void> insertarProducto(Producto producto) async {
    final productoModel = ProductoModel.fromEntity(producto);
    await localDataSource.insertarProducto(productoModel);
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    final productoModel = ProductoModel.fromEntity(producto);
    await localDataSource.actualizarProducto(productoModel);
  }

  @override
  Future<void> cambiarEstadoProducto(int id, bool activo) async {
    final filasActualizadas = await localDataSource.cambiarEstadoProducto(
      id,
      activo,
    );
    if (filasActualizadas != 1) {
      throw StateError('No se encontró el producto para cambiar su estado.');
    }
  }

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigoUnico) async {
    return await localDataSource.obtenerProductoPorCodigo(codigoUnico);
  }
}
