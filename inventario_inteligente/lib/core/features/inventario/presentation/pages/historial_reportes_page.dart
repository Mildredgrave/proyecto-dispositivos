import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../database/database_helper.dart';
import '../../../productos/presentation/provider/producto_provider.dart';
import '../../data/datasources/inventario_local_datasource.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/entities/movimiento.dart';

class HistorialReportesPage extends StatefulWidget {
  const HistorialReportesPage({super.key});

  @override
  State<HistorialReportesPage> createState() => _HistorialReportesPageState();
}

class _HistorialReportesPageState extends State<HistorialReportesPage> {
  List<Movimiento> _historial = [];
  bool _cargando = true;
  int? _productoFiltro;
  String _tipoFiltro = 'TODOS';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final dbHelper = DatabaseHelper();
    final dataSource = InventarioLocalDataSource(databaseHelper: dbHelper);
    final repo = InventarioRepositoryImpl(localDataSource: dataSource);

    final movimientos = await repo.obtenerHistorialMovimientos();

    setState(() {
      _historial = movimientos;
      _cargando = false;
    });
  }

  // Método para exportar el inventario a un archivo CSV
  Future<void> _exportarCSV(BuildContext context) async {
    final provider = Provider.of<ProductoProvider>(context, listen: false);
    final productos = provider.todosLosProductos;

    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos para exportar.')),
      );
      return;
    }

    // Cabecera del archivo CSV
    List<List<dynamic>> filas = [
      [
        'ID',
        'Código Único',
        'Nombre',
        'Descripción',
        'Categoría',
        'Precio Compra',
        'Precio Venta',
        'Stock Actual',
        'Stock Mínimo',
        'Estado',
      ],
    ];

    // Mapear cada producto a una fila del CSV
    for (var p in productos) {
      filas.add([
        p.id,
        p.codigoUnico,
        p.nombre,
        p.descripcion ?? '',
        p.categoriaNombre ?? '',
        p.precioCompra,
        p.precioVenta,
        p.stockActual,
        p.stockMinimo,
        p.activo ? 'Activo' : 'Inactivo',
      ]);
    }

    final csvData = Csv().encode(filas);

    late final String path;
    try {
      final directory = await getApplicationDocumentsDirectory();
      path =
          '${directory.path}/inventario_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear el CSV del inventario: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final resultadoCompartir = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          text: 'Inventario exportado en formato CSV.',
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultadoCompartir.status == ShareResultStatus.success
                ? 'CSV exportado y compartido desde:\n$path'
                : 'CSV guardado en:\n$path\nNo se compartió.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV guardado en $path, pero no se pudo compartir: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial y Reportes'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Historial'),
              Tab(icon: Icon(Icons.analytics), text: 'Valor e Informes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Historial de Movimientos
            Consumer<ProductoProvider>(
              builder: (context, provider, child) {
                final historialFiltrado = _filtrarHistorial();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: DropdownButtonFormField<int?>(
                        initialValue: _productoFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por producto',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos los productos'),
                          ),
                          ...provider.todosLosProductos
                              .where((producto) => producto.id != null)
                              .map(
                                (producto) => DropdownMenuItem<int?>(
                                  value: producto.id,
                                  child: Text(
                                    '${producto.nombre} (${producto.codigoUnico})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (value) =>
                            setState(() => _productoFiltro = value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por tipo',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'TODOS',
                            child: Text('Todos los tipos'),
                          ),
                          DropdownMenuItem(
                            value: 'ENTRADA',
                            child: Text('Entrada'),
                          ),
                          DropdownMenuItem(
                            value: 'SALIDA',
                            child: Text('Salida'),
                          ),
                          DropdownMenuItem(
                            value: 'AJUSTE',
                            child: Text('Ajuste'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _tipoFiltro = value);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _seleccionarFecha(desde: true),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _fechaDesde == null
                                    ? 'Desde'
                                    : _formatearFecha(_fechaDesde!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _seleccionarFecha(desde: false),
                              icon: const Icon(Icons.event),
                              label: Text(
                                _fechaHasta == null
                                    ? 'Hasta'
                                    : _formatearFecha(_fechaHasta!),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Limpiar filtros',
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.filter_alt_off),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : historialFiltrado.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay movimientos que coincidan con los filtros.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: historialFiltrado.length,
                              itemBuilder: (context, index) {
                                final m = historialFiltrado[index];
                                final producto = provider.todosLosProductos
                                    .where((p) => p.id == m.productoId)
                                    .firstOrNull;
                                final colorTipo = switch (m.tipo) {
                                  'ENTRADA' => Colors.green,
                                  'SALIDA' => Colors.red,
                                  _ => Colors.orange,
                                };

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: colorTipo.withAlpha(50),
                                      child: Icon(
                                        m.tipo == 'ENTRADA'
                                            ? Icons.arrow_downward
                                            : m.tipo == 'SALIDA'
                                            ? Icons.arrow_upward
                                            : Icons.sync,
                                        color: colorTipo,
                                      ),
                                    ),
                                    title: Text(
                                      m.tipo == 'AJUSTE'
                                          ? 'AJUSTE: conteo físico ${m.cantidad} unidad(es)'
                                          : '${m.tipo}: ${m.cantidad} unidad(es)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorTipo,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Producto: ${producto?.nombre ?? 'ID ${m.productoId}'}'
                                      '${producto == null ? '' : ' (${producto.codigoUnico})'}\n'
                                      'Motivo: ${m.motivo}\n'
                                      'Stock: ${m.stockAnterior} ➔ ${m.stockResultante}\n'
                                      'Resp: ${m.responsable}',
                                    ),
                                    trailing: Text(
                                      _formatearFechaHora(m.fechaHora),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),

            // TAB 2: Valor del Inventario y Exportación CSV
            Consumer<ProductoProvider>(
              builder: (context, provider, child) {
                // Cálculo del valor del inventario (stockActual * precioCompra)
                double valorTotal = provider.todosLosProductos.fold(
                  0.0,
                  (sum, p) => sum + (p.stockActual * p.precioCompra),
                );

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text(
                                'Valor Estimado del Inventario',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Q.${valorTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '(Calculado como existencias × precio de compra)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Estimación basada en el precio de compra registrado; no es una valoración contable.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.file_download),
                        label: const Text('Exportar Inventario a CSV'),
                        onPressed: () => _exportarCSV(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFechaHora(String valor) {
    final fechaHora = DateTime.tryParse(valor);
    if (fechaHora == null) return valor;
    final fechaLocal = fechaHora.toLocal();
    String dosDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${dosDigitos(fechaLocal.day)}/${dosDigitos(fechaLocal.month)}/'
        '${fechaLocal.year}\n${dosDigitos(fechaLocal.hour)}:'
        '${dosDigitos(fechaLocal.minute)}:${dosDigitos(fechaLocal.second)}';
  }

  List<Movimiento> _filtrarHistorial() {
    final inicio = _fechaDesde == null
        ? null
        : DateUtils.dateOnly(_fechaDesde!);
    final finExclusivo = _fechaHasta == null
        ? null
        : DateUtils.dateOnly(_fechaHasta!).add(const Duration(days: 1));

    return _historial.where((movimiento) {
      if (_productoFiltro != null && movimiento.productoId != _productoFiltro) {
        return false;
      }
      if (_tipoFiltro != 'TODOS' && movimiento.tipo != _tipoFiltro) {
        return false;
      }
      final fecha = DateTime.tryParse(movimiento.fechaHora)?.toLocal();
      if (fecha == null) return inicio == null && finExclusivo == null;
      if (inicio != null && fecha.isBefore(inicio)) return false;
      if (finExclusivo != null && !fecha.isBefore(finExclusivo)) return false;
      return true;
    }).toList();
  }

  Future<void> _seleccionarFecha({required bool desde}) async {
    final ahora = DateUtils.dateOnly(DateTime.now());
    final inicial = desde ? _fechaDesde ?? ahora : _fechaHasta ?? ahora;
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null || !mounted) return;

    if (!desde &&
        _fechaDesde != null &&
        seleccionada.isBefore(DateUtils.dateOnly(_fechaDesde!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha final no puede ser anterior a la inicial.'),
        ),
      );
      return;
    }

    setState(() {
      if (desde) {
        _fechaDesde = seleccionada;
        if (_fechaHasta != null &&
            _fechaHasta!.isBefore(DateUtils.dateOnly(seleccionada))) {
          _fechaHasta = null;
        }
      } else {
        _fechaHasta = seleccionada;
      }
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _productoFiltro = null;
      _tipoFiltro = 'TODOS';
      _fechaDesde = null;
      _fechaHasta = null;
    });
  }

  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }
}
