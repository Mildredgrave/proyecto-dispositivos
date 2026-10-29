import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/features/inventario/domain/entities/movimiento.dart';
import 'package:inventario_inteligente/core/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:inventario_inteligente/core/features/inventario/domain/usecases/registrar_movimiento.dart';
import 'package:inventario_inteligente/core/features/productos/domain/entities/producto.dart';

void main() {
  late _InventarioRepositoryFake repository;
  late RegistrarMovimiento registrarMovimiento;
  late Producto producto;

  setUp(() {
    repository = _InventarioRepositoryFake();
    registrarMovimiento = RegistrarMovimiento(repository);
    producto = Producto(
      id: 1,
      codigoUnico: 'P-1',
      nombre: 'Producto de prueba',
      precioCompra: 1,
      precioVenta: 2,
      stockActual: 5,
      stockMinimo: 1,
    );
  });

  test('rechaza entradas con cantidad cero', () async {
    await expectLater(
      registrarMovimiento(
        producto: producto,
        tipo: 'ENTRADA',
        cantidad: 0,
        motivo: 'Compra',
        responsable: 'Prueba',
      ),
      throwsA(isA<Exception>()),
    );

    expect(repository.movimiento, isNull);
  });

  test('rechaza salidas con cantidad negativa', () async {
    await expectLater(
      registrarMovimiento(
        producto: producto,
        tipo: 'SALIDA',
        cantidad: -1,
        motivo: 'Venta',
        responsable: 'Prueba',
      ),
      throwsA(isA<Exception>()),
    );

    expect(repository.movimiento, isNull);
  });

  test('rechaza salidas superiores al stock disponible', () async {
    await expectLater(
      registrarMovimiento(
        producto: producto,
        tipo: 'SALIDA',
        cantidad: 6,
        motivo: 'Venta',
        responsable: 'Prueba',
      ),
      throwsA(isA<Exception>()),
    );

    expect(repository.movimiento, isNull);
  });

  test('registra una entrada positiva con el stock resultante', () async {
    await registrarMovimiento(
      producto: producto,
      tipo: 'ENTRADA',
      cantidad: 3,
      motivo: 'Compra',
      responsable: 'Prueba',
    );

    expect(repository.movimiento?.stockAnterior, 5);
    expect(repository.movimiento?.stockResultante, 8);
  });

  test('el ajuste guarda como cantidad el conteo físico ingresado', () async {
    await registrarMovimiento(
      producto: producto,
      tipo: 'AJUSTE',
      cantidad: 7,
      motivo: 'Conteo físico',
      responsable: 'Prueba',
    );

    expect(repository.movimiento?.cantidad, 7);
    expect(repository.movimiento?.stockAnterior, 5);
    expect(repository.movimiento?.stockResultante, 7);
  });

  test('rechaza movimientos para productos inactivos', () async {
    final productoInactivo = Producto(
      id: producto.id,
      codigoUnico: producto.codigoUnico,
      nombre: producto.nombre,
      precioCompra: producto.precioCompra,
      precioVenta: producto.precioVenta,
      stockActual: producto.stockActual,
      stockMinimo: producto.stockMinimo,
      activo: false,
    );

    await expectLater(
      registrarMovimiento(
        producto: productoInactivo,
        tipo: 'ENTRADA',
        cantidad: 1,
        motivo: 'Compra',
        responsable: 'Prueba',
      ),
      throwsA(isA<StateError>()),
    );

    expect(repository.movimiento, isNull);
  });
}

class _InventarioRepositoryFake implements InventarioRepository {
  Movimiento? movimiento;

  @override
  Future<void> registrarMovimiento({
    required Movimiento movimiento,
    required int productoId,
  }) async {
    this.movimiento = movimiento;
  }

  @override
  Future<List<Movimiento>> obtenerHistorialMovimientos() async => [];
}
