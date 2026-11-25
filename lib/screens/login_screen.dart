import 'package:flutter/material.dart';

import '../config/servidor.dart';
import '../config/tema.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'prestamos_screen.dart';
import 'registro_screen.dart';
import 'servidor_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Motivo por el que se volvió al login (sesión vencida, 401…).
  final String? mensaje;

  const LoginScreen({super.key, this.mensaje});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.mensaje;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sesion = await AuthService.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PrestamosScreen(sesion: sesion)),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirServidor() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServidorScreen()));
    setState(() {}); // refresca la etiqueta del servidor
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // El logo ya incluye el nombre PrestaL&J
                    Image.asset('assets/logo.png', height: 150, semanticLabel: 'PrestaL&J'),
                    const SizedBox(height: 12),
                    Text('Controla a quién le prestaste y cuándo cobrar',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyMedium?.copyWith(color: Paleta.suave)),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      _MensajeError(texto: _error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Ingresa tu email';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Email no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _ocultar,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _cargando ? null : _ingresar,
                      icon: _cargando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(_cargando ? 'Ingresando…' : 'Iniciar sesión'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const RegistroScreen())),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 4),
                    // Servidor de la API: discreto, se cambia pocas veces
                    InkWell(
                      onTap: _cargando ? null : _elegirServidor,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.dns_outlined, size: 20, color: Paleta.suave),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Servidor: ${ServidorConfig.nombre(ServidorConfig.modo)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Paleta.tinta)),
                                  Text(ServidorConfig.baseUrl,
                                      style: const TextStyle(fontSize: 12, color: Paleta.suave)),
                                ],
                              ),
                            ),
                            const Text('Cambiar', style: TextStyle(color: Paleta.azul, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  final String texto;

  const _MensajeError({required this.texto});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}
