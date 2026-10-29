import 'package:sqflite/sqflite.dart';

import '../../../../database/database_helper.dart';
import '../models/producto_model.dart';

class ProductoLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProductoLocalDataSource({required this.databaseHelper});

  // 1. Obtener todos los productos
  Future<List<ProductoModel>> obtenerProductos() async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT productos.*, categorias.nombre AS categoriaNombre
      FROM productos
      LEFT JOIN categorias ON categorias.id = productos.categoriaId
    ''');
    return maps.map((map) => ProductoModel.fromMap(map)).toList();
  }

  // 2. Insertar un nuevo producto
  Future<int> insertarProducto(ProductoModel producto) async {
    final db = await databaseHelper.database;
    return db.transaction((txn) async {
      final categoriaId = await _obtenerOCrearCategoria(txn, producto);
      final valores = producto.toMap()..['categoriaId'] = categoriaId;
      return txn.insert(
        'productos',
        valores,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  // 3. Actualizar un producto existente
  Future<int> actualizarProducto(ProductoModel producto) async {
    final db = await databaseHelper.database;
    return db.transaction((txn) async {
      final categoriaId = await _obtenerOCrearCategoria(txn, producto);
      final valores = producto.toMap()
        ..remove('id')
        ..remove('stockActual')
        ..remove('activo')
        ..['categoriaId'] = categoriaId;
      return txn.update(
        'productos',
        valores,
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    });
  }

  Future<int> _obtenerOCrearCategoria(
    Transaction txn,
    ProductoModel producto,
  ) async {
    final nombre = producto.categoriaNombre?.trim();
    if (nombre == null || nombre.isEmpty) {
      throw ArgumentError('La categoría del producto es obligatoria.');
    }

    final categorias = await txn.query(
      'categorias',
      columns: ['id'],
      where: 'nombre = ? COLLATE NOCASE',
      whereArgs: [nombre],
      limit: 1,
    );
    if (categorias.isNotEmpty) return categorias.first['id'] as int;
    return txn.insert('categorias', {'nombre': nombre});
  }

  Future<int> cambiarEstadoProducto(int id, bool activo) async {
    final db = await databaseHelper.database;
    return await db.update(
      'productos',
      {'activo': activo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. Buscar un producto por su código único (clave para el escáner)
  Future<ProductoModel?> obtenerProductoPorCodigo(String codigoUnico) async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT productos.*, categorias.nombre AS categoriaNombre
      FROM productos
      LEFT JOIN categorias ON categorias.id = productos.categoriaId
      WHERE productos.codigoUnico = ? COLLATE NOCASE
      LIMIT 1
      ''',
      [codigoUnico],
    );

    if (maps.isNotEmpty) {
      return ProductoModel.fromMap(maps.first);
    }
    return null;
  }
}
