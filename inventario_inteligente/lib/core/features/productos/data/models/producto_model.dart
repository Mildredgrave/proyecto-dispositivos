import '../../domain/entities/producto.dart';

class ProductoModel extends Producto {
  ProductoModel({
    super.id,
    required super.codigoUnico,
    required super.nombre,
    super.descripcion,
    super.categoriaId,
    super.categoriaNombre,
    required super.precioCompra,
    required super.precioVenta,
    required super.stockActual,
    required super.stockMinimo,
    super.fotografia,
    super.activo,
  });

  // Convertir un objeto Producto (Entidad) a ProductoModel
  factory ProductoModel.fromEntity(Producto producto) {
    return ProductoModel(
      id: producto.id,
      codigoUnico: producto.codigoUnico,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      categoriaId: producto.categoriaId,
      categoriaNombre: producto.categoriaNombre,
      precioCompra: producto.precioCompra,
      precioVenta: producto.precioVenta,
      stockActual: producto.stockActual,
      stockMinimo: producto.stockMinimo,
      fotografia: producto.fotografia,
      activo: producto.activo,
    );
  }

  // Convertir un registro de SQLite (Map) a ProductoModel
  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'],
      codigoUnico: map['codigoUnico'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      categoriaId: map['categoriaId'],
      categoriaNombre: map['categoriaNombre'],
      precioCompra: map['precioCompra'],
      precioVenta: map['precioVenta'],
      stockActual: map['stockActual'],
      stockMinimo: map['stockMinimo'],
      fotografia: map['fotografia'],
      activo: map['activo'] == 1, // SQLite guarda booleanos como 1 o 0
    );
  }

  // Convertir ProductoModel a un Map para guardarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoUnico': codigoUnico,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoriaId': categoriaId,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'fotografia': fotografia,
      'activo': activo ? 1 : 0,
    };
  }
}
