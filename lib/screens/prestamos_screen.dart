import 'dart:async';

import 'package:flutter/material.dart';

import '../config/servidor.dart';
import '../models/prestamo.dart';
import '../models/resumen.dart';
import '../models/sesion.dart';
import '../services/prestamo_service.dart';
import '../services/sesion_global.dart';
import '../utils/formato.dart';
import 'prestamo_form_screen.dart';

/// Cartera del prestamista: resumen, pestañas Por cobrar / Cobrados, búsqueda y aviso de expiración del token.
class PrestamosScreen extends StatefulWidget {
  final Sesion sesion;

  const PrestamosScreen({super.key, required this.sesion});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  static const _avisarAntesDe = Duration(minutes: 10);

  List<Prestamo> _prestamos = [];
  Resumen? _resumen;
  bool _cargando = true;
  String? _errorCarga;
  String _busqueda = '';
  final _buscador = TextEditingController();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Revisa cada 30 s cuánto le queda al token
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) => _revisarExpiracion());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  void _revisarExpiracion() {
    if (!mounted) return;
    if (widget.sesion.expirada) {
      _reloj?.cancel();
      cerrarSesion(motivo: 'Tu sesión expiró, vuelve a iniciar sesión');
    } else {
      setState(() {}); // actualiza el aviso
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final resultados = await Future.wait([PrestamoService.listar(), PrestamoService.resumen()]);
      if (!mounted) return;
      setState(() {
        _prestamos = resultados[0] as List<Prestamo>;
        _resumen = resultados[1] as Resumen;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorCarga = e.toString());
      await manejarError(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Prestamo> _filtrar(bool pagados) {
    final q = _busqueda.trim().toLowerCase();
    return _prestamos
        .where((p) => p.pagado == pagados)
        .where((p) => q.isEmpty || p.cliente.toLowerCase().contains(q) || p.dni.contains(q))
        .toList();
  }

  Future<void> _abrirFormulario([Prestamo? prestamo]) async {
    final guardado = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => PrestamoFormScreen(prestamo: prestamo)));
    if (guardado == true) await _cargar();
  }

  Future<void> _cambiarPago(Prestamo p) async {
    try {
      await PrestamoService.actualizar(p.id, p.datos(pagado: !p.pagado));
      mostrarMensaje(p.pagado ? '${p.cliente}: vuelve a Por cobrar' : '${p.cliente}: marcado como cobrado');
      await _cargar();
    } catch (e) {
      await manejarError(e);
    }
  }

  Future<void> _anular(Prestamo p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever),
        title: const Text('¿Anular préstamo?'),
        content: Text('Se eliminará el préstamo de ${p.cliente} por ${soles(p.monto)}. '
            'Úsalo solo si se registró por error.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await PrestamoService.eliminar(p.id);
      mostrarMensaje('Préstamo de ${p.cliente} anulado');
      await _cargar();
    } catch (e) {
      await manejarError(e);
    }
  }

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Se borrará el token guardado en este celular.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) await cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final porCobrar = _filtrar(false);
    final cobrados = _filtrar(true);
    final morosos = porCobrar.where((p) => p.vencido).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PrestaL&J', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${widget.sesion.nombre} · ${ServidorConfig.nombre(ServidorConfig.modo)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(tooltip: 'Actualizar', onPressed: _cargando ? null : _cargar, icon: const Icon(Icons.refresh)),
            IconButton(tooltip: 'Cerrar sesión', onPressed: _salir, icon: const Icon(Icons.logout)),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Por cobrar (${porCobrar.length})'),
              Tab(text: 'Cobrados (${cobrados.length})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo préstamo'),
        ),
        body: Column(
          children: [
            _AvisoExpiracion(sesion: widget.sesion, avisarAntesDe: _avisarAntesDe),
            if (_resumen != null) _TarjetaResumen(resumen: _resumen!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _buscador,
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o DNI',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: _busqueda.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _buscador.clear();
                            _busqueda = '';
                          }),
                        ),
                ),
              ),
            ),
            if (morosos > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text('$morosos préstamo(s) vencido(s) sin cobrar',
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (_cargando) const LinearProgressIndicator(),
            Expanded(
              child: TabBarView(
                children: [
                  _lista(porCobrar, vacio: 'No tienes préstamos por cobrar'),
                  _lista(cobrados, vacio: 'Aún no hay préstamos cobrados'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(List<Prestamo> items, {required String vacio}) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Icon(Icons.inbox_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _cargando
                        ? 'Cargando…'
                        : _errorCarga != null
                            ? 'No se pudo cargar. Desliza hacia abajo para reintentar.'
                            : _busqueda.isNotEmpty
                                ? 'Sin resultados para "$_busqueda"'
                                : vacio,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: items.length,
              itemBuilder: (_, i) => _TarjetaPrestamo(
                prestamo: items[i],
                onEditar: () => _abrirFormulario(items[i]),
                onCambiarPago: () => _cambiarPago(items[i]),
                onAnular: () => _anular(items[i]),
              ),
            ),
    );
  }
}

/// Reto complementario: avisa antes de que el token expire.
class _AvisoExpiracion extends StatelessWidget {
  final Sesion sesion;
  final Duration avisarAntesDe;

  const _AvisoExpiracion({required this.sesion, required this.avisarAntesDe});

  @override
  Widget build(BuildContext context) {
    final queda = sesion.tiempoRestante;
    if (sesion.expira == null || queda > avisarAntesDe) return const SizedBox.shrink();
    final minutos = queda.inMinutes;
    return MaterialBanner(
      backgroundColor: Colors.amber.shade100,
      leading: const Icon(Icons.timer_outlined, color: Colors.black87),
      content: Text(
        minutos >= 1
            ? 'Tu sesión vence en $minutos min. Guarda tus cambios y vuelve a iniciar sesión.'
            : 'Tu sesión vence en menos de un minuto.',
        style: const TextStyle(color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => cerrarSesion(motivo: 'Inicia sesión de nuevo para renovar tu token'),
          child: const Text('Renovar'),
        ),
      ],
    );
  }
}

/// Reto complementario: capital prestado, total por cobrar y ganancia esperada.
class _TarjetaResumen extends StatelessWidget {
  final Resumen resumen;

  const _TarjetaResumen({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget dato(String titulo, String valor, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(titulo, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(valor,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? cs.onPrimaryContainer)),
              ),
            ],
          ),
        );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            dato('Capital prestado', soles(resumen.capitalPrestado)),
            dato('Por cobrar', soles(resumen.totalPorCobrar)),
            dato('Ganancia', soles(resumen.gananciaEsperada), color: Colors.green.shade800),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPrestamo extends StatelessWidget {
  final Prestamo prestamo;
  final VoidCallback onEditar;
  final VoidCallback onCambiarPago;
  final VoidCallback onAnular;

  const _TarjetaPrestamo({
    required this.prestamo,
    required this.onEditar,
    required this.onCambiarPago,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final p = prestamo;
    final tema = Theme.of(context);
    final rojo = Colors.red.shade700;

    return Card(
      // Morosos resaltados en rojo
      color: p.vencido ? Colors.red.shade50 : null,
      shape: p.vencido
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: rojo, width: 1.5))
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(p.cliente,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold, color: p.vencido ? rojo : Colors.black87)),
                        ),
                        if (p.vencido) ...[
                          const SizedBox(width: 6),
                          _Etiqueta(texto: 'VENCIDO', color: rojo),
                        ],
                        if (p.pagado) ...[
                          const SizedBox(width: 6),
                          _Etiqueta(texto: 'COBRADO', color: Colors.green.shade700),
                        ],
                      ],
                    ),
                    Text('DNI ${p.dni}', style: tema.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('Monto ${soles(p.monto)} · Interés ${porcentaje(p.interes)}',
                        style: const TextStyle(color: Colors.black87)),
                    Text('Total a cobrar: ${soles(p.totalACobrar)}',
                        style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: p.vencido ? rojo : tema.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text('Vence ${fecha(p.fechaVencimiento)}',
                            style: TextStyle(
                                color: p.vencido ? rojo : Colors.black54,
                                fontWeight: p.vencido ? FontWeight.w600 : FontWeight.normal)),
                        Text('  ·  Prestado ${fecha(p.fechaPrestamo)}',
                            style: const TextStyle(color: Colors.black45, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                onSelected: (v) => switch (v) {
                  'pago' => onCambiarPago(),
                  'editar' => onEditar(),
                  _ => onAnular(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pago',
                    child: ListTile(
                      leading: Icon(p.pagado ? Icons.undo : Icons.check_circle_outline),
                      title: Text(p.pagado ? 'Marcar como pendiente' : 'Marcar como cobrado'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'editar',
                    child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar')),
                  ),
                  const PopupMenuItem(
                    value: 'anular',
                    child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Anular')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const _Etiqueta({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}
