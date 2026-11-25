import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/servidor.dart';
import 'screens/login_screen.dart';
import 'screens/prestamos_screen.dart';
import 'services/sesion_global.dart';
import 'services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServidorConfig.cargar();

  // Sesión persistente: si hay un token guardado y vigente, entra directo a la lista
  final sesion = await TokenStorage.leer();
  Widget inicio;
  if (sesion != null && !sesion.expirada) {
    inicio = PrestamosScreen(sesion: sesion);
  } else {
    if (sesion != null) await TokenStorage.borrar();
    inicio = LoginScreen(mensaje: sesion != null ? 'Tu sesión expiró, vuelve a iniciar sesión' : null);
  }
  runApp(PrestaControlApp(inicio: inicio));
}

class PrestaControlApp extends StatelessWidget {
  final Widget inicio;

  const PrestaControlApp({super.key, required this.inicio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrestaL&J',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: mensajeroKey,
      theme: ThemeData(
        // Azul del logo PrestaL&J
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A7FC1)),
        useMaterial3: true,
      ),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: inicio,
    );
  }
}
