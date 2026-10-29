import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/features/productos/domain/entities/producto.dart';
import 'package:inventario_inteligente/core/features/productos/presentation/services/etiqueta_producto_pdf.dart';

void main() {
  test('genera un PDF imprimible para la etiqueta del producto', () async {
    final producto = Producto(
      id: 1,
      codigoUnico: 'COD-123',
      nombre: 'Producto de prueba',
      precioCompra: 1,
      precioVenta: 2,
      stockActual: 14,
      stockMinimo: 2,
    );

    final pdf = await EtiquetaProductoPdf.generar(producto);

    expect(pdf, isNotEmpty);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });
}
