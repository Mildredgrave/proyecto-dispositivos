import '../../domain/entities/movimiento.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../datasources/inventario_local_datasource.dart';
import '../models/movimiento_model.dart';

class InventarioRepositoryImpl implements InventarioRepository {
  final InventarioLocalDataSource localDataSource;

  InventarioRepositoryImpl({required this.localDataSource});

  @override
  Future<void> registrarMovimiento({
    required Movimiento movimiento,
    required int productoId,
  }) async {
    final movimientoModel = MovimientoModel.fromEntity(movimiento);
    await localDataSource.registrarMovimiento(
      movimiento: movimientoModel,
      productoId: productoId,
    );
  }

  @override
  Future<List<Movimiento>> obtenerHistorialMovimientos() async {
    return await localDataSource.obtenerHistorialMovimientos();
  }
}
