/// Resumen de la cartera pendiente (GET /prestamos/resumen).
class Resumen {
  final int prestamosPendientes;
  final int prestamosVencidos;
  final double capitalPrestado;
  final double totalPorCobrar;
  final double gananciaEsperada;

  const Resumen({
    required this.prestamosPendientes,
    required this.prestamosVencidos,
    required this.capitalPrestado,
    required this.totalPorCobrar,
    required this.gananciaEsperada,
  });

  factory Resumen.fromJson(Map<String, dynamic> json) => Resumen(
        prestamosPendientes: (json['prestamosPendientes'] as num).toInt(),
        prestamosVencidos: (json['prestamosVencidos'] as num).toInt(),
        capitalPrestado: (json['capitalPrestado'] as num).toDouble(),
        totalPorCobrar: (json['totalPorCobrar'] as num).toDouble(),
        gananciaEsperada: (json['gananciaEsperada'] as num).toDouble(),
      );
}
