import 'dart:convert';

/// Lee el payload de un JWT (sin verificar la firma: eso lo hace la API).
Map<String, dynamic> payloadDeJwt(String token) {
  final partes = token.split('.');
  if (partes.length != 3) throw const FormatException('Token mal formado');
  final json = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
  return jsonDecode(json) as Map<String, dynamic>;
}

/// Fecha de expiración (claim "exp") o null si no se puede leer.
DateTime? expiracionDeJwt(String token) {
  try {
    final exp = payloadDeJwt(token)['exp'];
    if (exp is num) return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  } catch (_) {
    // token ilegible: se trata como vencido
  }
  return null;
}
