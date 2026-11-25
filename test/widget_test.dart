import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prestacontrol_app/models/prestamo.dart';
import 'package:prestacontrol_app/models/sesion.dart';
import 'package:prestacontrol_app/utils/formato.dart';

String _jwtCon(Map<String, dynamic> payload) {
  String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64(payload)}.firma';
}

void main() {
  test('Prestamo.fromJson lee la respuesta de la API y detecta morosos', () {
    final p = Prestamo.fromJson({
      'id': 1,
      'cliente': 'Carlos Ruiz',
      'dni': '12345678',
      'monto': 500.00,
      'interes': 10.00,
      'totalACobrar': 550.00,
      'fechaPrestamo': '2026-01-01',
      'fechaVencimiento': '2026-01-15',
      'pagado': false,
    });
    expect(p.totalACobrar, 550);
    expect(p.ganancia, 50);
    expect(p.vencido, isTrue);
    expect(p.datos(pagado: true).toJson()['pagado'], isTrue);
    expect(p.datos().toJson()['fechaVencimiento'], '2026-01-15');
  });

  test('Formato de soles y porcentaje', () {
    expect(soles(1055), 'S/ 1,055.00');
    expect(soles(336.5), 'S/ 336.50');
    expect(porcentaje(10), '10 %');
    expect(porcentaje(5.5), '5.5 %');
  });

  test('Sesion lee la expiración del token', () {
    final futuro = DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000;
    final pasado = DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000;
    expect(Sesion(token: _jwtCon({'sub': 'a@b.pe', 'exp': futuro}), nombre: 'A', email: 'a@b.pe').expirada, isFalse);
    expect(Sesion(token: _jwtCon({'sub': 'a@b.pe', 'exp': pasado}), nombre: 'A', email: 'a@b.pe').expirada, isTrue);
    expect(Sesion(token: 'no-es-jwt', nombre: 'A', email: 'a@b.pe').expirada, isTrue);
  });
}
