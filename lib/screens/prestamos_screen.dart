import 'dart:async';

import 'package:flutter/material.dart';

import '../config/servidor.dart';
import '../config/tema.dart';
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
        title: const Text('¿Anular préstamo?'),
        content: Text('Se eliminará el préstamo de ${p.cliente} por ${soles(p.monto)}. '
            'Úsalo solo si se registró por error.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Paleta.vencido, minimumSize: const Size(0, 44)),
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
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
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
    final nombre = widget.sesion.nombre.split(' ').first;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PrestaL&J'),
              Text(
                'Hola, $nombre · ${ServidorConfig.nombre(ServidorConfig.modo)}',
                style: const TextStyle(fontSize: 13, color: Paleta.suave, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            IconButton(tooltip: 'Actualizar', onPressed: _cargando ? null : _cargar, icon: const Icon(Icons.refresh)),
            IconButton(tooltip: 'Cerrar sesión', onPressed: _salir, icon: const Icon(Icons.logout)),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo préstamo'),
        ),
        body: Column(
          children: [
            _AvisoExpiracion(sesion: widget.sesion, avisarAntesDe: _avisarAntesDe),
            if (_resumen != null) _TarjetaResumen(resumen: _resumen!, morosos: morosos),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _buscador,
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o DNI',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _busqueda.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _buscador.clear();
                            _busqueda = '';
                          }),
                        ),
                ),
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: 'Por cobrar · ${porCobrar.length}'),
                Tab(text: 'Cobrados · ${cobrados.length}'),
              ],
            ),
            if (_cargando) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
            Expanded(
              child: TabBarView(
                children: [
                  _lista(porCobrar, vacio: 'No tienes préstamos por cobrar.\nRegistra uno con "Nuevo préstamo".'),
                  _lista(cobrados, vacio: 'Aún no hay préstamos cobrados.'),
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                const SizedBox(height: 64),
                const Icon(Icons.receipt_long_outlined, size: 44, color: Paleta.borde),
                const SizedBox(height: 12),
                Text(
                  _cargando
                      ? 'Cargando…'
                      : _errorCarga != null
                          ? 'No se pudo cargar la cartera.\nDesliza hacia abajo para reintentar.'
                          : _busqueda.isNotEmpty
                              ? 'Nadie coincide con "$_busqueda".'
                              : vacio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Paleta.suave, height: 1.4),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Paleta.naranja.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Paleta.naranjaTexto, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              minutos >= 1 ? 'Tu sesión vence en $minutos min.' : 'Tu sesión vence en menos de un minuto.',
              style: const TextStyle(color: Paleta.tinta),
            ),
          ),
          TextButton(
            onPressed: () => cerrarSesion(motivo: 'Inicia sesión de nuevo para renovar tu token'),
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
  }
}

/// Reto complementario: lo que falta cobrar, el capital prestado y la ganancia esperada.
class _TarjetaResumen extends StatelessWidget {
  final Resumen resumen;
  final int morosos;

  const _TarjetaResumen({required this.resumen, required this.morosos});

  @override
  Widget build(BuildContext context) {
    const etiqueta = TextStyle(color: Color(0xFFB8C3DC), fontSize: 12.5);
    Widget dato(String titulo, String valor, {Color color = Colors.white}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: etiqueta),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor,
                    style: TextStyle(
                        color: color, fontSize: 16, fontWeight: FontWeight.w600, fontFeatures: cifras)),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: Paleta.tinta, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Por cobrar', style: etiqueta),
              const Spacer(),
              if (morosos > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Paleta.vencido, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    morosos == 1 ? '1 vencido' : '$morosos vencidos',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              soles(resumen.totalPorCobrar),
              style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, fontFeatures: cifras),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              dato('Capital prestado', soles(resumen.capitalPrestado)),
              dato('Ganancia esperada', soles(resumen.gananciaEsperada), color: Paleta.naranja),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estado de un préstamo según su fecha de vencimiento.
class _Estado {
  final Color color;
  final Color fondo;
  final String texto;

  const _Estado(this.color, this.fondo, this.texto);

  factory _Estado.de(Prestamo p) {
    if (p.pagado) return const _Estado(Paleta.cobrado, Color(0xFFE6F2EC), 'Cobrado');
    final dias = soloFecha(p.fechaVencimiento).difference(soloFecha(DateTime.now())).inDays;
    if (dias < 0) {
      return _Estado(Paleta.vencido, const Color(0xFFFCE8E8),
          dias == -1 ? 'Venció ayer' : 'Venció hace ${-dias} días');
    }
    final texto = switch (dias) { 0 => 'Vence hoy', 1 => 'Vence mañana', _ => 'Vence en $dias días' };
    if (dias <= 3) return _Estado(Paleta.naranjaTexto, const Color(0xFFFFF4E0), texto);
    return _Estado(Paleta.azul, const Color(0xFFE8EFF8), texto);
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
    final estado = _Estado.de(p);

    return Card(
      // Morosos resaltados en rojo
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.vencido ? Paleta.vencido : Paleta.borde, width: p.vencido ? 1.4 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Talón con la fecha de vencimiento
              Container(
                width: 64,
                color: estado.fondo,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${p.fechaVencimiento.day}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700, color: estado.color, fontFeatures: cifras)),
                    Text(mesCorto(p.fechaVencimiento),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: estado.color, letterSpacing: 1)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(p.cliente,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: Paleta.tinta)),
                          ),
                          const SizedBox(width: 8),
                          Text(soles(p.totalACobrar),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Paleta.tinta,
                                  fontFeatures: cifras)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'DNI ${p.dni} · ${soles(p.monto)} al ${porcentaje(p.interes)}',
                        style: const TextStyle(fontSize: 13, color: Paleta.suave, fontFeatures: cifras),
                      ),
                      const SizedBox(height: 6),
                      Text(estado.texto,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: estado.color)),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                icon: const Icon(Icons.more_vert, color: Paleta.suave),
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
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Paleta.vencido),
                      title: Text('Anular', style: TextStyle(color: Paleta.vencido)),
                    ),
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
