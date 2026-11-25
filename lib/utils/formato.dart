/// S/ 1,055.00
String soles(num valor) {
  final partes = valor.toDouble().abs().toStringAsFixed(2).split('.');
  final enteros = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${valor < 0 ? '-' : ''}S/ $enteros.${partes[1]}';
}

/// 10 % / 5.5 %
String porcentaje(num valor) {
  final d = valor.toDouble();
  final texto = d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return '$texto %';
}

/// 25/11/2026
String fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// 2026-11-25 (formato de la API)
String fechaIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
