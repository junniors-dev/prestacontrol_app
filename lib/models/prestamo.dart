import '../utils/formato.dart';

class Prestamo {
  final int id;
  final String cliente;
  final String dni;
  final double monto;
  final double interes;
  final double totalACobrar;
  final DateTime fechaPrestamo;
  final DateTime fechaVencimiento;
  final bool pagado;

  const Prestamo({
    required this.id,
    required this.cliente,
    required this.dni,
    required this.monto,
    required this.interes,
    required this.totalACobrar,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    required this.pagado,
  });

  factory Prestamo.fromJson(Map<String, dynamic> json) => Prestamo(
        id: (json['id'] as num).toInt(),
        cliente: json['cliente'] as String,
        dni: json['dni'] as String,
        monto: (json['monto'] as num).toDouble(),
        interes: (json['interes'] as num).toDouble(),
        totalACobrar: (json['totalACobrar'] as num).toDouble(),
        fechaPrestamo: DateTime.parse(json['fechaPrestamo'] as String),
        fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
        pagado: json['pagado'] as bool? ?? false,
      );

  double get ganancia => totalACobrar - monto;

  /// Vencido y sin cobrar (moroso).
  bool get vencido => !pagado && fechaVencimiento.isBefore(soloFecha(DateTime.now()));

  /// Cuerpo para el PUT (mismo préstamo con otro estado de pago).
  PrestamoDatos datos({bool? pagado}) => PrestamoDatos(
        cliente: cliente,
        dni: dni,
        monto: monto,
        interes: interes,
        fechaVencimiento: fechaVencimiento,
        pagado: pagado ?? this.pagado,
      );
}

/// Lo que se envía en POST/PUT. La fecha del préstamo y el prestamista los pone la API.
class PrestamoDatos {
  final String cliente;
  final String dni;
  final double monto;
  final double interes;
  final DateTime fechaVencimiento;
  final bool pagado;

  const PrestamoDatos({
    required this.cliente,
    required this.dni,
    required this.monto,
    required this.interes,
    required this.fechaVencimiento,
    this.pagado = false,
  });

  Map<String, dynamic> toJson() => {
        'cliente': cliente,
        'dni': dni,
        'monto': monto,
        'interes': interes,
        'fechaVencimiento': fechaIso(fechaVencimiento),
        'pagado': pagado,
      };
}
