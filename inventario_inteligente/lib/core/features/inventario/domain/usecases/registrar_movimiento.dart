import '../../../productos/domain/entities/producto.dart';
import '../entities/movimiento.dart';
import '../repositories/inventario_repository.dart';

class RegistrarMovimiento {
  final InventarioRepository repository;

  RegistrarMovimiento(this.repository);

  Future<void> call({
    required Producto producto,
    required String tipo,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    if (producto.id == null) {
      throw ArgumentError(
        'No se puede registrar un movimiento sin identificador de producto.',
      );
    }
    if (!producto.activo) {
      throw StateError(
        'No se pueden registrar movimientos para un producto inactivo.',
      );
    }
    if (!['ENTRADA', 'SALIDA', 'AJUSTE'].contains(tipo)) {
      throw ArgumentError('El tipo de movimiento no es válido.');
    }
    if (motivo.trim().isEmpty) {
      throw ArgumentError('El motivo del movimiento es obligatorio.');
    }
    if (responsable.trim().isEmpty) {
      throw ArgumentError('El responsable del movimiento es obligatorio.');
    }
    if (tipo != 'AJUSTE' && cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a cero.');
    }
    if (tipo == 'AJUSTE' && cantidad < 0) {
      throw ArgumentError('El conteo físico no puede ser negativo.');
    }

    int stockAnterior = producto.stockActual;
    int stockResultante = stockAnterior;

    if (tipo == 'ENTRADA') {
      stockResultante = stockAnterior + cantidad;
    } else if (tipo == 'SALIDA') {
      if (cantidad > stockAnterior) {
        throw Exception('No hay suficiente stock disponible para esta salida.');
      }
      stockResultante = stockAnterior - cantidad;
    } else if (tipo == 'AJUSTE') {
      stockResultante = cantidad;
    }

    final movimiento = Movimiento(
      productoId: producto.id!,
      tipo: tipo,
      cantidad: cantidad,
      stockAnterior: stockAnterior,
      stockResultante: stockResultante,
      motivo: motivo,
      responsable: responsable,
      fechaHora: DateTime.now().toIso8601String(),
    );

    await repository.registrarMovimiento(
      movimiento: movimiento,
      productoId: producto.id!,
    );
  }
}
