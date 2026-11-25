import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/sesion.dart';

/// Guarda el token en almacenamiento seguro (Keystore de Android), no en texto plano.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();
  static const _kToken = 'jwt_token';
  static const _kNombre = 'sesion_nombre';
  static const _kEmail = 'sesion_email';

  static Future<void> guardar(Sesion sesion) async {
    await _storage.write(key: _kToken, value: sesion.token);
    await _storage.write(key: _kNombre, value: sesion.nombre);
    await _storage.write(key: _kEmail, value: sesion.email);
  }

  static Future<String?> token() => _storage.read(key: _kToken);

  static Future<Sesion?> leer() async {
    final token = await _storage.read(key: _kToken);
    if (token == null || token.isEmpty) return null;
    return Sesion(
      token: token,
      nombre: await _storage.read(key: _kNombre) ?? '',
      email: await _storage.read(key: _kEmail) ?? '',
    );
  }

  static Future<void> borrar() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kNombre);
    await _storage.delete(key: _kEmail);
  }
}
