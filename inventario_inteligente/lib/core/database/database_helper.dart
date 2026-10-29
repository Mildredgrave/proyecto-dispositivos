import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Patrón Singleton para tener una única instancia de la base de datos
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventario_inteligente.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TRIGGER IF EXISTS movimientos_no_actualizar');
          await db.execute(
            "UPDATE movimientos SET cantidad = stockResultante "
            "WHERE tipo = 'AJUSTE'",
          );
          await _crearTriggersReglasNegocio(db);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Categorías (opcional pero recomendada para ordenar)
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    // 2. Tabla de Productos (según el modelo sugerido en el documento)
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigoUnico TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        categoriaId INTEGER,
        precioCompra REAL NOT NULL,
        precioVenta REAL NOT NULL,
        stockActual INTEGER NOT NULL,
        stockMinimo INTEGER NOT NULL,
        fotografia TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (categoriaId) REFERENCES categorias (id)
      )
    ''');

    // 3. Tabla de Movimientos (Entradas, Salidas y Ajustes)
    await db.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        tipo TEXT NOT NULL, -- 'ENTRADA', 'SALIDA', 'AJUSTE'
        cantidad INTEGER NOT NULL,
        stockAnterior INTEGER NOT NULL,
        stockResultante INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        responsable TEXT NOT NULL,
        fechaHora TEXT NOT NULL,
        FOREIGN KEY (productoId) REFERENCES productos (id)
      )
    ''');

    await _crearTriggersReglasNegocio(db);
  }

  Future<void> _crearTriggersReglasNegocio(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS movimientos_no_actualizar
      BEFORE UPDATE ON movimientos
      BEGIN
        SELECT RAISE(ABORT, 'Los movimientos confirmados no se pueden editar.');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS movimientos_no_eliminar
      BEFORE DELETE ON movimientos
      BEGIN
        SELECT RAISE(ABORT, 'Los movimientos confirmados no se pueden eliminar.');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS productos_con_movimientos_no_eliminar
      BEFORE DELETE ON productos
      WHEN EXISTS (
        SELECT 1 FROM movimientos WHERE productoId = OLD.id
      )
      BEGIN
        SELECT RAISE(ABORT, 'Un producto con movimientos no se puede eliminar; desactívelo.');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS productos_codigo_unico_insensible_insertar
      BEFORE INSERT ON productos
      WHEN EXISTS (
        SELECT 1 FROM productos
        WHERE codigoUnico = NEW.codigoUnico COLLATE NOCASE
      )
      BEGIN
        SELECT RAISE(ABORT, 'El código único del producto ya está registrado.');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS productos_codigo_unico_insensible_actualizar
      BEFORE UPDATE OF codigoUnico ON productos
      WHEN EXISTS (
        SELECT 1 FROM productos
        WHERE codigoUnico = NEW.codigoUnico COLLATE NOCASE
          AND id != OLD.id
      )
      BEGIN
        SELECT RAISE(ABORT, 'El código único del producto ya está registrado.');
      END
    ''');
  }

  // cerrar la base de datos si es necesario
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
