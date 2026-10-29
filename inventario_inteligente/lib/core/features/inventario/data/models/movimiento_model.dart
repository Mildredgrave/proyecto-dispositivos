import '../../../inventario/domain/entities/movimiento.dart';

class MovimientoModel extends Movimiento {
  MovimientoModel({
    super.id,
    required super.productoId,
    required super.tipo,
    required super.cantidad,
    required super.stockAnterior,
    required super.stockResultante,
    required super.motivo,
    required super.responsable,
    required super.fechaHora,
  });

  factory MovimientoModel.fromEntity(Movimiento movimiento) {
    return MovimientoModel(
      id: movimiento.id,
      productoId: movimiento.productoId,
      tipo: movimiento.tipo,
      cantidad: movimiento.cantidad,
      stockAnterior: movimiento.stockAnterior,
      stockResultante: movimiento.stockResultante,
      motivo: movimiento.motivo,
      responsable: movimiento.responsable,
      fechaHora: movimiento.fechaHora,
    );
  }

  factory MovimientoModel.fromMap(Map<String, dynamic> map) {
    return MovimientoModel(
      id: map['id'],
      productoId: map['productoId'],
      tipo: map['tipo'],
      cantidad: map['cantidad'],
      stockAnterior: map['stockAnterior'],
      stockResultante: map['stockResultante'],
      motivo: map['motivo'],
      responsable: map['responsable'],
      fechaHora: map['fechaHora'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'tipo': tipo,
      'cantidad': cantidad,
      'stockAnterior': stockAnterior,
      'stockResultante': stockResultante,
      'motivo': motivo,
      'responsable': responsable,
      'fechaHora': fechaHora,
    };
  }
}
