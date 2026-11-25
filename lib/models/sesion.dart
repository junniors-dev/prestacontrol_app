import '../utils/jwt.dart';

/// Datos del prestamista que inició sesión y su token JWT.
class Sesion {
  final String token;
  final String nombre;
  final String email;
  final DateTime? expira;

  Sesion({required this.token, required this.nombre, required this.email}) : expira = expiracionDeJwt(token);

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
        token: json['token'] as String,
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  bool get expirada => expira == null || !DateTime.now().isBefore(expira!);

  Duration get tiempoRestante => expira == null ? Duration.zero : expira!.difference(DateTime.now());
}
