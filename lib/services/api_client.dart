import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/servidor.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String mensaje;
  final int? status;

  const ApiException(this.mensaje, [this.status]);

  @override
  String toString() => mensaje;
}

/// La API respondió 401 en un endpoint protegido: token ausente, alterado o vencido.
class SesionExpiradaException extends ApiException {
  const SesionExpiradaException(String mensaje) : super(mensaje, 401);
}

/// Cliente HTTP común: arma la URL según el servidor elegido, envía el token y traduce los errores.
class ApiClient {
  ApiClient._();

  // Render (plan gratuito) puede tardar cerca de un minuto en despertar
  static const _timeout = Duration(seconds: 75);

  static Future<http.Response> enviar(String metodo, String ruta,
      {Object? cuerpo, bool conToken = true, Map<String, String>? query}) async {
    final uri = Uri.parse('${ServidorConfig.baseUrl}$ruta').replace(queryParameters: query);
    final peticion = http.Request(metodo, uri)..headers['Accept'] = 'application/json';

    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json; charset=utf-8';
      peticion.body = jsonEncode(cuerpo);
    }
    if (conToken) {
      final token = await TokenStorage.token();
      if (token == null) throw const SesionExpiradaException('Inicia sesión para continuar');
      peticion.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(await peticion.send().timeout(_timeout));
    } on TimeoutException {
      throw ApiException('El servidor (${ServidorConfig.nombre(ServidorConfig.modo)}) no respondió a tiempo');
    } catch (_) {
      throw ApiException('No se pudo conectar con ${ServidorConfig.baseUrl}. '
          'Revisa el servidor elegido y tu conexión.');
    }

    if (respuesta.statusCode == 401 && conToken) {
      throw SesionExpiradaException(_detalle(respuesta) ?? 'Tu sesión expiró, vuelve a iniciar sesión');
    }
    if (respuesta.statusCode >= 400) {
      throw ApiException(_detalle(respuesta) ?? 'Error ${respuesta.statusCode} del servidor', respuesta.statusCode);
    }
    return respuesta;
  }

  static dynamic json(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  /// Mensaje "detail" del ProblemDetail que devuelve la API.
  static String? _detalle(http.Response r) {
    try {
      final j = json(r);
      if (j is Map && j['detail'] is String) return j['detail'] as String;
    } catch (_) {
      // cuerpo vacío o no JSON
    }
    return null;
  }
}
