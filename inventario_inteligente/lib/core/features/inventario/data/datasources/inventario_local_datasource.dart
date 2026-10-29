import '../../../../database/database_helper.dart';
import '../models/movimiento_model.dart';

class InventarioLocalDataSource {
  final DatabaseHelper databaseHelper;

  InventarioLocalDataSource({required this.databaseHelper});

  // Registrar un movimiento y actualizar el stock en una transacción atómica
  Future<void> registrarMovimiento({
    required MovimientoModel movimiento,
    required int productoId,
  }) async {
    if (movimiento.productoId != productoId) {
      throw ArgumentError('El producto del movimiento no coincide.');
    }
    if (movimiento.motivo.trim().isEmpty ||
        movimiento.responsable.trim().isEmpty ||
        movimiento.fechaHora.trim().isEmpty) {
      throw ArgumentError(
        'El motivo, el responsable y la fecha del movimiento son obligatorios.',
      );
    }
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      final productos = await txn.query(
        'productos',
        columns: ['stockActual', 'activo'],
        where: 'id = ?',
        whereArgs: [productoId],
        limit: 1,
      );
      if (productos.isEmpty) {
        throw StateError('El producto ya no existe.');
      }

      final producto = productos.first;
      if (producto['activo'] != 1) {
        throw StateError(
          'No se pueden registrar movimientos para un producto inactivo.',
        );
      }

      final stockActual = producto['stockActual'] as int;
      if (movimiento.stockAnterior != stockActual) {
        throw StateError(
          'El stock cambió desde que se abrió este formulario. '
          'Actualiza el producto y vuelve a registrar el movimiento.',
        );
      }

      late final int stockResultanteEsperado;
      switch (movimiento.tipo) {
        case 'ENTRADA':
          if (movimiento.cantidad <= 0) {
            throw ArgumentError(
              'La cantidad de entrada debe ser mayor a cero.',
            );
          }
          stockResultanteEsperado = stockActual + movimiento.cantidad;
        case 'SALIDA':
          if (movimiento.cantidad <= 0) {
            throw ArgumentError('La cantidad de salida debe ser mayor a cero.');
          }
          if (movimiento.cantidad > stockActual) {
            throw StateError(
              'No hay suficiente stock disponible para esta salida.',
            );
          }
          stockResultanteEsperado = stockActual - movimiento.cantidad;
        case 'AJUSTE':
          if (movimiento.stockResultante < 0 ||
              movimiento.cantidad != movimiento.stockResultante) {
            throw ArgumentError('El ajuste de inventario no es válido.');
          }
          stockResultanteEsperado = movimiento.stockResultante;
        default:
          throw ArgumentError('El tipo de movimiento no es válido.');
      }

      if (movimiento.stockResultante != stockResultanteEsperado) {
        throw ArgumentError('El stock resultante del movimiento no es válido.');
      }

      await txn.insert('movimientos', movimiento.toMap());

      final productosActualizados = await txn.update(
        'productos',
        {'stockActual': stockResultanteEsperado},
        where: 'id = ? AND stockActual = ? AND activo = 1',
        whereArgs: [productoId, stockActual],
      );
      if (productosActualizados != 1) {
        throw StateError('No se pudo actualizar el stock del producto.');
      }
    });
  }

  // Obtener el historial de movimientos
  Future<List<MovimientoModel>> obtenerHistorialMovimientos() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movimientos',
      orderBy: 'fechaHora DESC',
    );
    return maps.map((map) => MovimientoModel.fromMap(map)).toList();
  }
}
