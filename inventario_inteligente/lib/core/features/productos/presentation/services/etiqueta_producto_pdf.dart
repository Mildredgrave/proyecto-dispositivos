import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/producto.dart';

class EtiquetaProductoPdf {
  static Future<Uint8List> generar(Producto producto) async {
    final documento = pw.Document();
    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          100 * PdfPageFormat.mm,
          85 * PdfPageFormat.mm,
        ),
        margin: pw.EdgeInsets.all(5 * PdfPageFormat.mm),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              producto.nombre,
              maxLines: 2,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3 * PdfPageFormat.mm),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: producto.codigoUnico,
              width: 85 * PdfPageFormat.mm,
              height: 20 * PdfPageFormat.mm,
              drawText: true,
            ),
            pw.SizedBox(height: 3 * PdfPageFormat.mm),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: producto.codigoUnico,
              width: 22 * PdfPageFormat.mm,
              height: 22 * PdfPageFormat.mm,
            ),
            pw.SizedBox(height: 2 * PdfPageFormat.mm),
            pw.Text(
              'Codigo: ${producto.codigoUnico}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
    return documento.save();
  }
}
