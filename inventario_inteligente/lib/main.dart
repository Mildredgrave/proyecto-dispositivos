import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/database_helper.dart';
import 'core/features/productos/data/datasource/producto_local_datasource.dart';
import 'core/features/productos/data/repositories/producto_repository_impl.dart';
import 'core/features/productos/domain/usecases/obtener_productos.dart';
import 'core/features/productos/domain/usecases/actualizar_producto.dart';
import 'core/features/productos/domain/usecases/cambiar_estado_producto.dart';
import 'core/features/productos/domain/usecases/registrar_producto.dart';
import 'core/features/productos/presentation/provider/producto_provider.dart';
// IMPORTANTE: Asegúrate de importar tu pantalla de productos principal
import 'core/features/productos/presentation/pages/productos_page.dart';

void main() async {
  // Asegurar que los enlaces de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el helper de la base de datos local
  final databaseHelper = DatabaseHelper();

  // Configurar la arquitectura en cascada (Datasource -> Repository -> UseCases)
  final productoDataSource = ProductoLocalDataSource(
    databaseHelper: databaseHelper,
  );
  final productoRepository = ProductoRepositoryImpl(
    localDataSource: productoDataSource,
  );

  final obtenerProductosUseCase = ObtenerProductos(productoRepository);
  final actualizarProductoUseCase = ActualizarProducto(productoRepository);
  final cambiarEstadoProductoUseCase = CambiarEstadoProducto(
    productoRepository,
  );
  final registrarProductoUseCase = RegistrarProducto(productoRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductoProvider(
            obtenerProductosUseCase: obtenerProductosUseCase,
            actualizarProductoUseCase: actualizarProductoUseCase,
            cambiarEstadoProductoUseCase: cambiarEstadoProductoUseCase,
            registrarProductoUseCase: registrarProductoUseCase,
          )..cargarProductos(), // Cargamos los productos al iniciar la app
        ),
      ],
      child: const InventarioInteligenteApp(),
    ),
  );
}

class InventarioInteligenteApp extends StatelessWidget {
  const InventarioInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Inteligente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // Apuntamos directamente a la página principal con el menú, búsqueda y botón de agregar
      home: const ProductosPage(),
    );
  }
}
