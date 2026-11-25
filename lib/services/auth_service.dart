import '../models/sesion.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService._();

  static Future<Sesion> registrar(String nombre, String email, String password) =>
      _autenticar('/auth/register', {'nombre': nombre, 'email': email, 'password': password});

  static Future<Sesion> login(String email, String password) =>
      _autenticar('/auth/login', {'email': email, 'password': password});

  static Future<void> cerrarSesion() => TokenStorage.borrar();

  static Future<Sesion> _autenticar(String ruta, Map<String, String> cuerpo) async {
    final respuesta = await ApiClient.enviar('POST', ruta, cuerpo: cuerpo, conToken: false);
    final sesion = Sesion.fromJson(ApiClient.json(respuesta) as Map<String, dynamic>);
    await TokenStorage.guardar(sesion); // sesión persistente
    return sesion;
  }

  /// true si el servidor elegido responde (sin token la API contesta 401: eso significa que está viva).
  static Future<bool> probarServidor() async {
    try {
      await ApiClient.enviar('GET', '/prestamos', conToken: false);
      return true;
    } on ApiException catch (e) {
      if (e.status == 401) return true;
      rethrow;
    }
  }
}
