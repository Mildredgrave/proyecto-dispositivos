import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../database/database_helper.dart';
import '../../../escaner/presentation/pages/escaner_page.dart';
import '../../../inventario/presentation/pages/historial_reportes_page.dart';
import '../../../productos/data/datasource/producto_local_datasource.dart';
import '../../domain/entities/producto.dart';
import '../provider/producto_provider.dart';
import '../pages/producto_detalle_page.dart';
import '../pages/producto_form_page.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  int _indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pantallas = [
      const _ListaProductosTab(),
      const HistorialReportesPage(),
    ];

    return Scaffold(
      body: pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        selectedItemColor: Colors.blue.shade700,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Historial y Reportes',
          ),
        ],
      ),
    );
  }
}

class _ListaProductosTab extends StatefulWidget {
  const _ListaProductosTab();

  @override
  State<_ListaProductosTab> createState() => _ListaProductosTabState();
}

class _ListaProductosTabState extends State<_ListaProductosTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Inteligente - UMES'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Botón del Escáner con cámara
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Escanear Código o QR',
            onPressed: () async {
              final codigoEscaneado = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const EscanerPage()),
              );

              if (codigoEscaneado != null && context.mounted) {
                _manejarProductoEscaneado(context, codigoEscaneado);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Búsqueda Manual (por código o nombre)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                Provider.of<ProductoProvider>(
                  context,
                  listen: false,
                ).buscarProductos(query);
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o código de producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductoProvider>(
                            context,
                            listen: false,
                          ).buscarProductos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Listado de productos filtrados
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(child: Text('Error: ${provider.error}'));
                }

                if (provider.productos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron productos con ese criterio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.productos.length,
                  itemBuilder: (context, index) {
                    final Producto producto = provider.productos[index];
                    final bool stockBajo = producto.tieneStockBajo;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: stockBajo ? Colors.red.shade50 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            producto.nombre.isNotEmpty
                                ? producto.nombre[0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          producto.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${producto.codigoUnico}'),
                            Text(
                              'Stock: ${producto.stockActual} (Mín: ${producto.stockMinimo})',
                              style: TextStyle(
                                color: stockBajo
                                    ? Colors.red.shade700
                                    : Colors.black87,
                                fontWeight: stockBajo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (stockBajo)
                              Text(
                                'Alerta: stock igual o inferior al mínimo',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              'Categoría: ${producto.categoriaNombre ?? 'Sin categoría'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              producto.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: producto.activo
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Q.${producto.precioVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Acciones del producto',
                              onSelected: (accion) {
                                if (accion == 'estado') {
                                  _cambiarEstadoProducto(context, producto);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductoFormPage(
                                        productoAEditar: producto,
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'estado',
                                  child: Text(
                                    producto.activo
                                        ? 'Desactivar producto'
                                        : 'Activar producto',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar producto'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          // Al tocar, muestra detalles y existencias
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductoDetallePage(producto: producto),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        tooltip: 'Agregar Producto',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductoFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _cambiarEstadoProducto(
    BuildContext context,
    Producto producto,
  ) async {
    final nuevoEstado = !producto.activo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nuevoEstado ? 'Activar producto' : 'Desactivar producto'),
        content: Text(
          nuevoEstado
              ? '¿Deseas volver a activar "${producto.nombre}"?'
              : '¿Deseas desactivar "${producto.nombre}"? '
                    'Su historial de movimientos se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(nuevoEstado ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;
    final id = producto.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede cambiar el estado de un producto sin ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<ProductoProvider>();
    final actualizado = await provider.cambiarEstadoProducto(id, nuevoEstado);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actualizado
              ? 'Producto ${nuevoEstado ? 'activado' : 'desactivado'} correctamente.'
              : 'No se pudo cambiar el estado: ${provider.error ?? 'error desconocido'}',
        ),
        backgroundColor: actualizado ? null : Colors.red,
      ),
    );
  }

  // Busca el producto escaneado y permite consultarlo antes de registrar un movimiento.
  void _manejarProductoEscaneado(BuildContext context, String codigo) async {
    final codigoNormalizado = codigo.trim();
    if (codigoNormalizado.isEmpty) return;
    try {
      final dbHelper = DatabaseHelper();
      final dataSource = ProductoLocalDataSource(databaseHelper: dbHelper);
      final producto = await dataSource.obtenerProductoPorCodigo(
        codigoNormalizado,
      );

      if (!context.mounted) return;

      if (producto != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductoDetallePage(producto: producto),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Producto no encontrado'),
            content: Text(
              'El código escaneado "$codigoNormalizado" no está registrado en el inventario. ¿Deseas crearlo ahora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductoFormPage(codigoInicial: codigoNormalizado),
                    ),
                  );
                },
                child: const Text('Crear Producto'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo buscar el producto: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
