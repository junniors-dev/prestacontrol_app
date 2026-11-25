import '../models/prestamo.dart';
import '../models/resumen.dart';
import 'api_client.dart';

/// Endpoints protegidos: ApiClient envía `Authorization: Bearer <token>` en cada llamada.
class PrestamoService {
  PrestamoService._();

  static Future<List<Prestamo>> listar() async {
    final r = await ApiClient.enviar('GET', '/prestamos');
    return (ApiClient.json(r) as List).map((e) => Prestamo.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Resumen> resumen() async {
    final r = await ApiClient.enviar('GET', '/prestamos/resumen');
    return Resumen.fromJson(ApiClient.json(r) as Map<String, dynamic>);
  }

  static Future<Prestamo> crear(PrestamoDatos datos) async {
    final r = await ApiClient.enviar('POST', '/prestamos', cuerpo: datos.toJson());
    return Prestamo.fromJson(ApiClient.json(r) as Map<String, dynamic>);
  }

  static Future<Prestamo> actualizar(int id, PrestamoDatos datos) async {
    final r = await ApiClient.enviar('PUT', '/prestamos/$id', cuerpo: datos.toJson());
    return Prestamo.fromJson(ApiClient.json(r) as Map<String, dynamic>);
  }

  static Future<void> eliminar(int id) => ApiClient.enviar('DELETE', '/prestamos/$id');
}
