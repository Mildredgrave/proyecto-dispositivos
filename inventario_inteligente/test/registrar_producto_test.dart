import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/features/productos/domain/entities/producto.dart';
import 'package:inventario_inteligente/core/features/productos/domain/repositories/producto_repository.dart';
import 'package:inventario_inteligente/core/features/productos/domain/usecases/registrar_producto.dart';

void main() {
  late _ProductoRepositoryFake repository;
  late RegistrarProducto registrarProducto;

  setUp(() {
    repository = _ProductoRepositoryFake();
    registrarProducto = RegistrarProducto(repository);
  });

  test('permite crear productos sin existencias iniciales', () async {
    await registrarProducto(_producto(stockActual: 0));

    expect(repository.productoRegistrado?.stockActual, 0);
  });

  test('rechaza existencias iniciales sin un movimiento de entrada', () async {
    await expectLater(
      registrarProducto(_producto(stockActual: 4)),
      throwsA(isA<ArgumentError>()),
    );

    expect(repository.productoRegistrado, isNull);
  });

  test('requiere una categoría para el producto', () async {
    await expectLater(
      registrarProducto(_producto(categoriaNombre: '  ')),
      throwsA(isA<ArgumentError>()),
    );

    expect(repository.productoRegistrado, isNull);
  });

  test('requiere código y nombre no vacíos', () async {
    for (final producto in [
      _producto(codigoUnico: '  '),
      _producto(nombre: '  '),
    ]) {
      await expectLater(
        registrarProducto(producto),
        throwsA(isA<ArgumentError>()),
      );
    }

    expect(repository.productoRegistrado, isNull);
  });

  test('rechaza precios no finitos y stock mínimo negativo', () async {
    for (final producto in [
      _producto(precioCompra: double.nan),
      _producto(precioVenta: double.infinity),
      _producto(stockMinimo: -1),
    ]) {
      await expectLater(
        registrarProducto(producto),
        throwsA(isA<ArgumentError>()),
      );
    }

    expect(repository.productoRegistrado, isNull);
  });

  test('marca alerta cuando el stock es igual o inferior al mínimo', () {
    expect(_producto(stockActual: 3, stockMinimo: 3).tieneStockBajo, isTrue);
    expect(_producto(stockActual: 2, stockMinimo: 3).tieneStockBajo, isTrue);
    expect(_producto(stockActual: 4, stockMinimo: 3).tieneStockBajo, isFalse);
  });
}

Producto _producto({
  int stockActual = 0,
  int stockMinimo = 0,
  String? categoriaNombre = 'Bebidas',
  String codigoUnico = 'P-1',
  String nombre = 'Producto de prueba',
  double precioCompra = 1,
  double precioVenta = 2,
}) {
  return Producto(
    codigoUnico: codigoUnico,
    nombre: nombre,
    categoriaNombre: categoriaNombre,
    precioCompra: precioCompra,
    precioVenta: precioVenta,
    stockActual: stockActual,
    stockMinimo: stockMinimo,
  );
}

class _ProductoRepositoryFake implements ProductoRepository {
  Producto? productoRegistrado;

  @override
  Future<void> insertarProducto(Producto producto) async {
    productoRegistrado = producto;
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {}

  @override
  Future<void> cambiarEstadoProducto(int id, bool activo) async {}

  @override
  Future<List<Producto>> obtenerProductos() async => [];

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigoUnico) async => null;
}
