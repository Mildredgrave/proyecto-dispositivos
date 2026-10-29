import 'dart:io';

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../inventario/presentation/pages/movimiento_form_page.dart';
import '../../domain/entities/producto.dart';
import '../provider/producto_provider.dart';
import '../services/etiqueta_producto_pdf.dart';

class ProductoDetallePage extends StatefulWidget {
  final Producto producto;

  const ProductoDetallePage({super.key, required this.producto});

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  bool _procesandoEtiqueta = false;
  late Producto _productoActual;

  @override
  void initState() {
    super.initState();
    _productoActual = widget.producto;
  }

  @override
  Widget build(BuildContext context) {
    final producto = _productoActual;
    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            enabled: !_procesandoEtiqueta,
            tooltip: 'Exportar etiqueta',
            onSelected: (accion) => _exportarEtiqueta(accion),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'compartir',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Compartir etiqueta PDF'),
                ),
              ),
              PopupMenuItem(
                value: 'imprimir',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Imprimir etiqueta'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.fotografia != null &&
                File(producto.fotografia!).existsSync())
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(producto.fotografia!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Tarjeta de información general
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Código Único: ${producto.codigoUnico}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Descripción: ${producto.descripcion ?? 'Sin descripción'}',
                    ),
                    Text(
                      'Categoría: ${producto.categoriaNombre ?? 'Sin categoría'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio de Compra: Q.${producto.precioCompra.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Precio de Venta: Q.${producto.precioVenta.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stock Actual: ${producto.stockActual}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Stock Mínimo: ${producto.stockMinimo}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sección de Etiquetas (Código de Barras y QR exigidos por la UMES)
            const Text(
              'Etiquetas del Producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 1. Código de Barras (Code 128)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Código de Barras (Code 128)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: producto.codigoUnico,
                      width: double.infinity,
                      height: 80,
                      drawText: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 2. Código QR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Código QR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: producto.codigoUnico,
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El QR identifica al producto (el stock se consulta en la base de datos).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: producto.activo
            ? Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _registrarMovimiento('ENTRADA'),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Registrar entrada'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _registrarMovimiento('SALIDA'),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Registrar salida'),
                    ),
                  ),
                ],
              )
            : const Text(
                'Producto inactivo: no se pueden registrar movimientos.',
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  Future<void> _registrarMovimiento(String tipo) async {
    final navigator = Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) =>
            MovimientoFormPage(producto: _productoActual, tipoInicial: tipo),
      ),
    );

    if (!mounted) return;
    final provider = context.read<ProductoProvider>();
    await provider.cargarProductos();
    if (!mounted) return;
    final actualizado = provider.todosLosProductos
        .where((producto) => producto.id == _productoActual.id)
        .firstOrNull;
    if (actualizado != null) {
      setState(() => _productoActual = actualizado);
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron actualizar las existencias: ${provider.error}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportarEtiqueta(String accion) async {
    setState(() => _procesandoEtiqueta = true);
    try {
      final producto = widget.producto;
      final pdf = await EtiquetaProductoPdf.generar(producto);
      final nombreArchivo =
          'etiqueta_${producto.codigoUnico.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';

      final completado = accion == 'compartir'
          ? await Printing.sharePdf(
              bytes: pdf,
              filename: nombreArchivo,
              subject: 'Etiqueta de ${producto.nombre}',
              body: 'Etiqueta de producto ${producto.codigoUnico}',
            )
          : await Printing.layoutPdf(
              name: nombreArchivo,
              format: PdfPageFormat(
                100 * PdfPageFormat.mm,
                85 * PdfPageFormat.mm,
              ),
              onLayout: (_) async => pdf,
            );

      if (!completado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accion == 'compartir'
                  ? 'No se compartió la etiqueta.'
                  : 'La impresión fue cancelada.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accion == 'compartir'
                ? 'Etiqueta PDF preparada para compartir.'
                : 'Etiqueta enviada a impresión.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo exportar la etiqueta: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesandoEtiqueta = false);
    }
  }
}
