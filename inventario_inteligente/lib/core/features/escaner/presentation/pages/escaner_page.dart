import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  bool _codigoEnviado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras o QR'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_codigoEnviado) return;
          final codigoLeido = capture.barcodes
              .map((barcode) => barcode.rawValue?.trim())
              .whereType<String>()
              .where((codigo) => codigo.isNotEmpty)
              .firstOrNull;
          if (codigoLeido == null) return;
          _codigoEnviado = true;
          Navigator.pop(context, codigoLeido);
        },
        errorBuilder: (context, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo acceder a la cámara. Revisa los permisos o usa la búsqueda manual.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver a búsqueda manual'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
