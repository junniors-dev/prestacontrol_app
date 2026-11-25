import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde corre la API.
enum ModoServidor { render, usb, wifi }

/// URL base de la API según el servidor elegido en la pantalla "Servidor".
class ServidorConfig {
  ServidorConfig._();

  static const String renderUrl = 'https://prestamoservice-diaz.onrender.com';
  static const String ipWifiPorDefecto = '172.20.10.3';
  static const int puerto = 8080;

  static const _storage = FlutterSecureStorage();
  static const _kModo = 'servidor_modo';
  static const _kIp = 'servidor_ip';

  static ModoServidor modo = ModoServidor.render;
  static String ipWifi = ipWifiPorDefecto;

  static String get baseUrl => urlDe(modo, ipWifi);

  static String urlDe(ModoServidor m, String ip) => switch (m) {
        ModoServidor.render => renderUrl,
        // Con el celular por USB: adb reverse tcp:8080 tcp:8080
        ModoServidor.usb => 'http://localhost:$puerto',
        // Celular y PC en la misma red Wi-Fi
        ModoServidor.wifi => 'http://$ip:$puerto',
      };

  static String nombre(ModoServidor m) => switch (m) {
        ModoServidor.render => 'Render',
        ModoServidor.usb => 'USB',
        ModoServidor.wifi => 'Wi-Fi',
      };

  static Future<void> cargar() async {
    final m = await _storage.read(key: _kModo);
    final ip = await _storage.read(key: _kIp);
    modo = ModoServidor.values.firstWhere((e) => e.name == m, orElse: () => ModoServidor.render);
    ipWifi = (ip == null || ip.isEmpty) ? ipWifiPorDefecto : ip;
  }

  static Future<void> guardar(ModoServidor nuevoModo, String nuevaIp) async {
    modo = nuevoModo;
    ipWifi = nuevaIp.trim();
    await _storage.write(key: _kModo, value: modo.name);
    await _storage.write(key: _kIp, value: ipWifi);
  }
}
