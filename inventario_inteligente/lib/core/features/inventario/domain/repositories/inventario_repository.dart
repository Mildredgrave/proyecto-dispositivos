import '../entities/movimiento.dart';

abstract class InventarioRepository {
  Future<void> registrarMovimiento({
    required Movimiento movimiento,
    required int productoId,
  });
  Future<List<Movimiento>> obtenerHistorialMovimientos();
}
