class Movimiento {
  final int? id;
  final int productoId;
  final String tipo; // 'ENTRADA', 'SALIDA', 'AJUSTE'
  final int cantidad;
  final int stockAnterior;
  final int stockResultante;
  final String motivo;
  final String responsable;
  final String fechaHora;

  Movimiento({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockResultante,
    required this.motivo,
    required this.responsable,
    required this.fechaHora,
  });
}
