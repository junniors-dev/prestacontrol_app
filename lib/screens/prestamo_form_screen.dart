import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/tema.dart';
import '../models/prestamo.dart';
import '../services/prestamo_service.dart';
import '../services/sesion_global.dart';
import '../utils/formato.dart';

/// Registrar o editar un préstamo. Devuelve true al guardar.
class PrestamoFormScreen extends StatefulWidget {
  final Prestamo? prestamo;

  const PrestamoFormScreen({super.key, this.prestamo});

  @override
  State<PrestamoFormScreen> createState() => _PrestamoFormScreenState();
}

class _PrestamoFormScreenState extends State<PrestamoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _cliente = TextEditingController(text: widget.prestamo?.cliente);
  late final _dni = TextEditingController(text: widget.prestamo?.dni);
  late final _monto = TextEditingController(text: widget.prestamo?.monto.toStringAsFixed(2));
  late final _interes = TextEditingController(text: widget.prestamo == null ? '10' : _sinCeros(widget.prestamo!.interes));
  late DateTime? _vencimiento = widget.prestamo?.fechaVencimiento;
  late bool _pagado = widget.prestamo?.pagado ?? false;
  bool _guardando = false;
  bool _intentoGuardar = false;

  bool get _editando => widget.prestamo != null;

  static String _sinCeros(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// La fecha de vencimiento no puede ser anterior a la del préstamo (hoy, si es nuevo).
  DateTime get _minimaFecha => soloFecha(widget.prestamo?.fechaPrestamo ?? DateTime.now());

  @override
  void dispose() {
    _cliente.dispose();
    _dni.dispose();
    _monto.dispose();
    _interes.dispose();
    super.dispose();
  }

  double? _num(String t) => double.tryParse(t.trim().replaceAll(',', '.'));

  double get _totalVistaPrevia {
    final m = _num(_monto.text) ?? 0;
    final i = _num(_interes.text) ?? 0;
    return m + m * i / 100;
  }

  Future<void> _elegirFecha() async {
    final inicial = _vencimiento ?? _minimaFecha.add(const Duration(days: 30));
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(_minimaFecha) ? _minimaFecha : inicial,
      firstDate: _minimaFecha,
      lastDate: DateTime(_minimaFecha.year + 10),
      helpText: 'Fecha de vencimiento',
    );
    if (elegida != null) setState(() => _vencimiento = elegida);
  }

  Future<void> _guardar() async {
    final valido = _form.currentState!.validate();
    if (_vencimiento == null) {
      setState(() => _intentoGuardar = true); // muestra el error de la fecha
      return;
    }
    if (!valido) return;

    setState(() => _guardando = true);
    final datos = PrestamoDatos(
      cliente: _cliente.text.trim(),
      dni: _dni.text.trim(),
      monto: _num(_monto.text)!,
      interes: _num(_interes.text)!,
      fechaVencimiento: _vencimiento!,
      pagado: _pagado,
    );
    try {
      if (_editando) {
        await PrestamoService.actualizar(widget.prestamo!.id, datos);
        mostrarMensaje('Préstamo actualizado');
      } else {
        await PrestamoService.crear(datos);
        mostrarMensaje('Préstamo registrado');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      await manejarError(e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sinFecha = _vencimiento == null;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar préstamo' : 'Nuevo préstamo')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _cliente,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                hintText: 'Persona que recibe el dinero',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El cliente es obligatorio' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dni,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '') ? null : 'El DNI debe tener 8 dígitos',
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _monto,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: 'S/ ',
                    ),
                    validator: (v) {
                      final n = _num(v ?? '');
                      if (n == null) return 'Monto no válido';
                      if (n <= 0) return 'Debe ser mayor a 0';
                      if (n >= 100000000) return 'Monto demasiado alto';
                      if (RegExp(r'[.,]\d{3,}$').hasMatch(v!.trim())) return 'Máximo 2 decimales';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _interes,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Interés',
                      suffixText: '%',
                    ),
                    validator: (v) {
                      final n = _num(v ?? '');
                      if (n == null) return 'Interés no válido';
                      if (n < 0) return 'No puede ser negativo';
                      if (n > 999.99) return 'Máximo 999.99 %';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _elegirFecha,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de vencimiento',
                  prefixIcon: const Icon(Icons.event),
                  errorText: sinFecha && _intentoGuardar ? 'Elige la fecha de vencimiento' : null,
                ),
                child: Text(sinFecha ? 'Toca para elegir' : fecha(_vencimiento!)),
              ),
            ),
            const SizedBox(height: 10),
            // Atajos: plazos habituales contados desde la fecha del préstamo
            Wrap(
              spacing: 8,
              children: [
                for (final (texto, dias) in const [('En 1 semana', 7), ('En 15 días', 15), ('En 1 mes', 30)])
                  ChoiceChip(
                    label: Text(texto),
                    selected: _vencimiento != null &&
                        soloFecha(_vencimiento!) == _minimaFecha.add(Duration(days: dias)),
                    onSelected: (_) => setState(() => _vencimiento = _minimaFecha.add(Duration(days: dias))),
                  ),
              ],
            ),
            if (_editando) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                value: _pagado,
                onChanged: (v) => setState(() => _pagado = v),
                title: const Text('Préstamo cobrado'),
                subtitle: Text('Prestado el ${fecha(widget.prestamo!.fechaPrestamo)}'),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: Paleta.tinta, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total a cobrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('Monto + interés', style: TextStyle(color: Color(0xFFB8C3DC), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text(soles(_totalVistaPrevia),
                      style: tema.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: cifras)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_editando ? 'Guardar cambios' : 'Registrar préstamo'),
            ),
          ],
        ),
      ),
    );
  }
}
