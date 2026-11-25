import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Navegación y mensajes que no dependen de una pantalla concreta.
final navigatorKey = GlobalKey<NavigatorState>();
final mensajeroKey = GlobalKey<ScaffoldMessengerState>();

void mostrarMensaje(String texto, {bool error = false}) {
  final messenger = mensajeroKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Borra el token y vuelve al login (cierre de sesión o 401 de la API).
Future<void> cerrarSesion({String? motivo}) async {
  await AuthService.cerrarSesion();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen(mensaje: motivo)),
    (_) => false,
  );
}

/// Muestra el error; si es un 401, cierra la sesión.
Future<void> manejarError(Object e) async {
  if (e is SesionExpiradaException) {
    await cerrarSesion(motivo: e.mensaje);
  } else {
    mostrarMensaje(e is ApiException ? e.mensaje : 'Error inesperado: $e', error: true);
  }
}
