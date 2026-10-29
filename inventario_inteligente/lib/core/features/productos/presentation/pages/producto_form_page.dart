import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../inventario/presentation/pages/movimiento_form_page.dart';
import '../../domain/entities/producto.dart';
import '../provider/producto_provider.dart';

class ProductoFormPage extends StatefulWidget {
  final Producto? productoAEditar;
  final String? codigoInicial;

  const ProductoFormPage({super.key, this.productoAEditar, this.codigoInicial});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _precioCompraController;
  late final TextEditingController _precioVentaController;
  late final TextEditingController _stockActualController;
  late final TextEditingController _stockMinimoController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _fotografiaSeleccionada;
  String? _fotografiaActual;
  bool _quitarFotografia = false;
  bool _guardando = false;

  bool get _esEdicion => widget.productoAEditar != null;

  @override
  void initState() {
    super.initState();
    final producto = widget.productoAEditar;
    _fotografiaActual = producto?.fotografia;
    _codigoController = TextEditingController(
      text: producto?.codigoUnico ?? widget.codigoInicial ?? '',
    );
    _nombreController = TextEditingController(text: producto?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    _categoriaController = TextEditingController(
      text: producto?.categoriaNombre ?? '',
    );
    _precioCompraController = TextEditingController(
      text: producto?.precioCompra.toString() ?? '',
    );
    _precioVentaController = TextEditingController(
      text: producto?.precioVenta.toString() ?? '',
    );
    _stockActualController = TextEditingController(
      text: producto?.stockActual.toString() ?? '0',
    );
    _stockMinimoController = TextEditingController(
      text: producto?.stockMinimo.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código único *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: _validarCodigoUnico,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto *',
                border: OutlineInputBorder(),
              ),
              validator: _validarTextoRequerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                helperText: 'Se crea automáticamente si aún no existe.',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: _validarTextoRequerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioCompraController,
              decoration: const InputDecoration(
                labelText: 'Precio de compra *',
                prefixText: 'Q. ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => _validarPrecio(value, 'compra'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioVentaController,
              decoration: const InputDecoration(
                labelText: 'Precio de venta *',
                prefixText: 'Q. ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => _validarPrecio(value, 'venta'),
            ),
            const SizedBox(height: 16),
            if (_esEdicion)
              TextFormField(
                controller: _stockActualController,
                decoration: const InputDecoration(
                  labelText: 'Stock actual',
                  helperText: 'El stock solo se modifica mediante movimientos.',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            if (!_esEdicion)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('El producto inicia con 0 existencias.'),
                subtitle: Text(
                  'Registra el stock inicial como una entrada después de guardarlo.',
                ),
              ),
            const SizedBox(height: 16),
            _construirCampoFotografia(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockMinimoController,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _validarEnteroNoNegativo(value, 'stock mínimo'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardarProducto,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validarTextoRequerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _validarCodigoUnico(String? value) {
    return _validarTextoRequerido(value);
  }

  String? _validarPrecio(String? value, String nombre) {
    final precio = double.tryParse(value?.trim() ?? '');
    if (precio == null || !precio.isFinite || precio <= 0) {
      return 'Ingrese un precio de $nombre mayor a cero';
    }
    return null;
  }

  String? _validarEnteroNoNegativo(String? value, String nombre) {
    final cantidad = int.tryParse(value?.trim() ?? '');
    if (cantidad == null || cantidad < 0) {
      return 'Ingrese un valor válido para $nombre (cero o mayor)';
    }
    return null;
  }

  Widget _construirCampoFotografia() {
    final archivo =
        _fotografiaSeleccionada ??
        (_quitarFotografia || _fotografiaActual == null
            ? null
            : File(_fotografiaActual!));
    final existeArchivo = archivo != null && archivo.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fotografía (opcional)'),
        const SizedBox(height: 8),
        if (existeArchivo)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              archivo,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 80,
                child: Center(child: Text('No se pudo mostrar la fotografía.')),
              ),
            ),
          )
        else
          const Text('No se ha seleccionado una fotografía.'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _guardando ? null : _seleccionarFotografia,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Seleccionar fotografía'),
            ),
            if (existeArchivo)
              TextButton.icon(
                onPressed: _guardando
                    ? null
                    : () => setState(() {
                        _fotografiaSeleccionada = null;
                        _fotografiaActual = null;
                        _quitarFotografia = true;
                      }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _seleccionarFotografia() async {
    try {
      final imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagen == null || !mounted) return;
      setState(() {
        _fotografiaSeleccionada = File(imagen.path);
        _quitarFotografia = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la fotografía: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _persistirFotografia(String codigoUnico) async {
    if (_quitarFotografia) return null;
    final seleccionada = _fotografiaSeleccionada;
    if (seleccionada == null) return _fotografiaActual;

    final documents = await getApplicationDocumentsDirectory();
    final directorio = Directory(path.join(documents.path, 'fotografias'));
    await directorio.create(recursive: true);
    final codigoSeguro = codigoUnico.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final extension = path.extension(seleccionada.path);
    final destino = path.join(
      directorio.path,
      'producto_${codigoSeguro}_${DateTime.now().microsecondsSinceEpoch}'
      '${extension.isEmpty ? '.jpg' : extension}',
    );
    return (await seleccionada.copy(destino)).path;
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProductoProvider>();
    setState(() {
      _guardando = true;
    });

    final productoOriginal = widget.productoAEditar;
    final codigoUnico = _codigoController.text.trim().toUpperCase();
    String? fotografia;
    try {
      fotografia = await _persistirFotografia(codigoUnico);
    } catch (error) {
      if (!mounted) return;
      setState(() => _guardando = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la fotografía: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final producto = Producto(
      id: productoOriginal?.id,
      codigoUnico: codigoUnico,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      categoriaId: productoOriginal?.categoriaId,
      categoriaNombre: _categoriaController.text.trim(),
      precioCompra: double.parse(_precioCompraController.text.trim()),
      precioVenta: double.parse(_precioVentaController.text.trim()),
      stockActual: productoOriginal?.stockActual ?? 0,
      stockMinimo: int.parse(_stockMinimoController.text.trim()),
      fotografia: fotografia,
      activo: productoOriginal?.activo ?? true,
    );
    final guardado = _esEdicion
        ? await provider.actualizarProducto(producto)
        : await provider.agregarProducto(producto);

    if (!mounted) return;
    setState(() {
      _guardando = false;
    });

    if (guardado) {
      final productoCreado = _esEdicion
          ? null
          : provider.todosLosProductos
                .where((p) => p.codigoUnico == producto.codigoUnico)
                .firstOrNull;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Producto actualizado correctamente'
                : 'Producto agregado correctamente',
          ),
        ),
      );
      if (productoCreado != null) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => MovimientoFormPage(
              producto: productoCreado,
              tipoInicial: 'ENTRADA',
              soloEntrada: true,
            ),
          ),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el producto: ${provider.error ?? 'error desconocido'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
