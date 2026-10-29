import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/features/productos/domain/entities/producto.dart';
import 'package:inventario_inteligente/core/features/productos/domain/repositories/producto_repository.dart';
import 'package:inventario_inteligente/core/features/productos/domain/usecases/actualizar_producto.dart';
import 'package:inventario_inteligente/core/features/productos/domain/usecases/cambiar_estado_producto.dart';
import 'package:inventario_inteligente/core/features/productos/domain/usecases/obtener_productos.dart';
import 'package:inventario_inteligente/core/features/productos/domain/usecases/registrar_producto.dart';
import 'package:inventario_inteligente/core/features/productos/presentation/provider/producto_provider.dart';

void main() {
  test('la búsqueda manual encuentra productos por nombre o código', () async {
    final repository = _ProductoRepositoryFake([
      _producto(codigo: 'BEB-001', nombre: 'Agua mineral'),
      _producto(codigo: 'SNK-002', nombre: 'Galletas'),
    ]);
    final provider = ProductoProvider(
      obtenerProductosUseCase: ObtenerProductos(repository),
      actualizarProductoUseCase: ActualizarProducto(repository),
      cambiarEstadoProductoUseCase: CambiarEstadoProducto(repository),
      registrarProductoUseCase: RegistrarProducto(repository),
    );

    await provider.cargarProductos();
    provider.buscarProductos('AGUA');
    expect(provider.productos.map((producto) => producto.codigoUnico), [
      'BEB-001',
    ]);

    provider.buscarProductos('snk-002');
    expect(provider.productos.map((producto) => producto.nombre), ['Galletas']);

    provider.buscarProductos('');
    expect(provider.productos, hasLength(2));
  });
}

Producto _producto({required String codigo, required String nombre}) {
  return Producto(
    id: codigo == 'BEB-001' ? 1 : 2,
    codigoUnico: codigo,
    nombre: nombre,
    categoriaNombre: 'Prueba',
    precioCompra: 1,
    precioVenta: 2,
    stockActual: 8,
    stockMinimo: 2,
  );
}

class _ProductoRepositoryFake implements ProductoRepository {
  _ProductoRepositoryFake(this.productos);

  final List<Producto> productos;

  @override
  Future<void> insertarProducto(Producto producto) async {}

  @override
  Future<void> actualizarProducto(Producto producto) async {}

  @override
  Future<void> cambiarEstadoProducto(int id, bool activo) async {}

  @override
  Future<List<Producto>> obtenerProductos() async => productos;

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigoUnico) async {
    for (final producto in productos) {
      if (producto.codigoUnico.toLowerCase() == codigoUnico.toLowerCase()) {
        return producto;
      }
    }
    return null;
  }
}
