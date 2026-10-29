import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../database/database_helper.dart';
import '../../../productos/domain/entities/producto.dart';
import '../../../productos/presentation/provider/producto_provider.dart';
import '../../data/datasources/inventario_local_datasource.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/usecases/registrar_movimiento.dart';

class MovimientoFormPage extends StatefulWidget {
  final Producto producto;
  final String tipoInicial;
  final bool soloEntrada;

  const MovimientoFormPage({
    super.key,
    required this.producto,
    this.tipoInicial = 'ENTRADA',
    this.soloEntrada = false,
  });

  @override
  State<MovimientoFormPage> createState() => _MovimientoFormPageState();
}

class _MovimientoFormPageState extends State<MovimientoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _responsableController = TextEditingController();

  late String _tipoSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.soloEntrada ? 'ENTRADA' : widget.tipoInicial;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movimiento: ${widget.producto.nombre}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto: ${widget.producto.nombre}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Código: ${widget.producto.codigoUnico}'),
                      const SizedBox(height: 4),
                      Text(
                        'Stock Actual Disponible: ${widget.producto.stockActual}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.soloEntrada)
                const InputDecorator(
                  decoration: InputDecoration(labelText: 'Tipo de movimiento'),
                  child: Text('Entrada (stock inicial)'),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Movimiento *',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ENTRADA',
                      child: Text('Entrada (Compra / Devolución)'),
                    ),
                    DropdownMenuItem(
                      value: 'SALIDA',
                      child: Text('Salida (Venta / Daño)'),
                    ),
                    DropdownMenuItem(
                      value: 'AJUSTE',
                      child: Text('Ajuste por Conteo Físico'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoSeleccionado = value!;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tipoSeleccionado == 'AJUSTE'
                      ? 'Conteo Físico Real (Nuevo Stock) *'
                      : 'Cantidad *',
                  helperText: _tipoSeleccionado == 'AJUSTE'
                      ? 'Ingrese el total de unidades contadas físicamente.'
                      : null,
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Ingrese una cantidad numérica válida';
                  }
                  final int cant = int.parse(value);
                  if (_tipoSeleccionado != 'AJUSTE' && cant <= 0) {
                    return 'La cantidad debe ser mayor a cero[cite: 2].';
                  }
                  if (_tipoSeleccionado == 'AJUSTE' && cant < 0) {
                    return 'El conteo físico no puede ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _tipoSeleccionado == 'AJUSTE'
                      ? 'Justificación Obligatoria del Ajuste *'
                      : 'Motivo del Movimiento (Ej. Factura #123, Venta al cliente) *',
                ),
                validator: (value) {
                  if (_tipoSeleccionado == 'AJUSTE' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Los ajustes físicos exigen una justificación obligatoria.';
                  }
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un motivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsableController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Responsable *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre del responsable';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _guardando
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final int cantidadInput = int.parse(
                            _cantidadController.text,
                          );

                          setState(() => _guardando = true);
                          try {
                            // Configuración de repositorios y casos de uso
                            final dbHelper = DatabaseHelper();
                            final invDataSource = InventarioLocalDataSource(
                              databaseHelper: dbHelper,
                            );
                            final invRepo = InventarioRepositoryImpl(
                              localDataSource: invDataSource,
                            );
                            final registrarMovimientoUseCase =
                                RegistrarMovimiento(invRepo);

                            // Ejecutando la lógica de negocio (validaciones de stock, salidas, ajustes)
                            await registrarMovimientoUseCase(
                              producto: widget.producto,
                              tipo: _tipoSeleccionado,
                              cantidad: cantidadInput,
                              motivo: _motivoController.text.trim(),
                              responsable: _responsableController.text.trim(),
                            );

                            if (!context.mounted) return;

                            // Actualizar el proveedor global de productos
                            Provider.of<ProductoProvider>(
                              context,
                              listen: false,
                            ).cargarProductos();

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Movimiento registrado y existencias actualizadas.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => _guardando = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: ${e.toString().replaceAll('Exception: ', '')}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmar Movimiento',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
