class Producto {
  final int? id;
  final String codigoUnico;
  final String nombre;
  final String? descripcion;
  final int? categoriaId;
  final String? categoriaNombre;
  final double precioCompra;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final String? fotografia;
  final bool activo;

  Producto({
    this.id,
    required this.codigoUnico,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    this.categoriaNombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    this.fotografia,
    this.activo = true,
  });

  // Regla de negocio en el dominio: saber si el producto está en alerta de stock bajo
  bool get tieneStockBajo => stockActual <= stockMinimo;
}
