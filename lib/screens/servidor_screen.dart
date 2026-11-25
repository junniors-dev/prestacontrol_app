import 'package:flutter/material.dart';

import '../config/servidor.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Elige dónde está la API: Render (publicada) o la PC (USB o Wi-Fi).
class ServidorScreen extends StatefulWidget {
  const ServidorScreen({super.key});

  @override
  State<ServidorScreen> createState() => _ServidorScreenState();
}

class _ServidorScreenState extends State<ServidorScreen> {
  late ModoServidor _modo = ServidorConfig.modo;
  late final _ip = TextEditingController(text: ServidorConfig.ipWifi);
  bool _probando = false;
  String? _resultado;
  bool _ok = false;

  @override
  void dispose() {
    _ip.dispose();
    super.dispose();
  }

  bool get _ipValida => RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(_ip.text.trim());

  Future<void> _guardar() async {
    await ServidorConfig.guardar(_modo, _ip.text);
  }

  Future<void> _probar() async {
    if (_modo == ModoServidor.wifi && !_ipValida) {
      setState(() {
        _ok = false;
        _resultado = 'Escribe una IP válida, por ejemplo 172.20.10.3';
      });
      return;
    }
    await _guardar();
    setState(() {
      _probando = true;
      _resultado = null;
    });
    try {
      await AuthService.probarServidor();
      setState(() {
        _ok = true;
        _resultado = 'Conectado a ${ServidorConfig.baseUrl}';
      });
    } on ApiException catch (e) {
      setState(() {
        _ok = false;
        _resultado = e.mensaje;
      });
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ayuda = switch (_modo) {
      ModoServidor.render => 'API publicada en Render (https). La primera petición puede tardar ~1 minuto '
          'mientras el servidor gratuito despierta.',
      ModoServidor.usb => 'API en tu PC. Conecta el celular por USB (depuración activada) y ejecuta en la PC:\n'
          'adb reverse tcp:8080 tcp:8080',
      ModoServidor.wifi => 'API en tu PC. El celular y la PC deben estar en la misma red Wi-Fi. '
          'Escribe la IP de la PC (ipconfig → Dirección IPv4).',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Servidor de la API')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<ModoServidor>(
            segments: const [
              ButtonSegment(value: ModoServidor.render, icon: Icon(Icons.cloud_outlined), label: Text('Render')),
              ButtonSegment(value: ModoServidor.usb, icon: Icon(Icons.usb), label: Text('USB')),
              ButtonSegment(value: ModoServidor.wifi, icon: Icon(Icons.wifi), label: Text('Wi-Fi')),
            ],
            selected: {_modo},
            onSelectionChanged: (s) => setState(() {
              _modo = s.first;
              _resultado = null;
            }),
          ),
          const SizedBox(height: 16),
          Text(ayuda, style: tema.textTheme.bodyMedium),
          if (_modo == ModoServidor.wifi) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _ip,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'IP de la PC',
                suffixText: ':${ServidorConfig.puerto}',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _resultado = null),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL que usará la app'),
              subtitle: Text(ServidorConfig.urlDe(_modo, _ip.text.trim())),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _probando ? null : _probar,
            icon: _probando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check),
            label: Text(_probando ? 'Probando…' : 'Probar conexión'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_ok ? Icons.check_circle : Icons.error, color: _ok ? Colors.green : tema.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_resultado!)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _probando
                ? null
                : () async {
                    if (_modo == ModoServidor.wifi && !_ipValida) {
                      setState(() {
                        _ok = false;
                        _resultado = 'Escribe una IP válida, por ejemplo 172.20.10.3';
                      });
                      return;
                    }
                    await _guardar();
                    if (context.mounted) Navigator.of(context).pop();
                  },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
