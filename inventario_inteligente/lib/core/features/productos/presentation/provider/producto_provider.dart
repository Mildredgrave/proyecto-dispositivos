import 'package:flutter/foundation.dart';

import '../../domain/entities/producto.dart';
import '../../domain/usecases/obtener_productos.dart';
import '../../domain/usecases/actualizar_producto.dart';
import '../../domain/usecases/cambiar_estado_producto.dart';
import '../../domain/usecases/registrar_producto.dart';

class ProductoProvider extends ChangeNotifier {
  final ObtenerProductos obtenerProductosUseCase;
  final ActualizarProducto actualizarProductoUseCase;
  final CambiarEstadoProducto cambiarEstadoProductoUseCase;
  final RegistrarProducto registrarProductoUseCase;

  ProductoProvider({
    required this.obtenerProductosUseCase,
    required this.actualizarProductoUseCase,
    required this.cambiarEstadoProductoUseCase,
    required this.registrarProductoUseCase,
  });

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoading = false;
  String? _error;
  String _filtroActual = '';

  List<Producto> get productos =>
      _filtroActual.isEmpty ? _productos : _productosFiltrados;
  List<Producto> get todosLosProductos => List.unmodifiable(_productos);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroActual => _filtroActual;

  Future<void> cargarProductos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await obtenerProductosUseCase();
      _aplicarFiltro(_filtroActual);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Búsqueda manual por código o nombre
  void buscarProductos(String query) {
    _filtroActual = query;
    _aplicarFiltro(query);
    notifyListeners();
  }

  void _aplicarFiltro(String query) {
    if (query.isEmpty) {
      _productosFiltrados = List.from(_productos);
    } else {
      final q = query.toLowerCase();
      _productosFiltrados = _productos.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.codigoUnico.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<bool> agregarProducto(Producto producto) async {
    try {
      await registrarProductoUseCase(producto);
      await cargarProductos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarProducto(Producto producto) async {
    try {
      await actualizarProductoUseCase(producto);
      await cargarProductos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cambiarEstadoProducto(int productoId, bool activo) async {
    try {
      await cambiarEstadoProductoUseCase(
        productoId: productoId,
        activo: activo,
      );
      await cargarProductos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
