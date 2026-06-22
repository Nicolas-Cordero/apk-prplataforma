import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/services/acuerdo_service.dart';

/// Página de Compromiso
/// Muestra el acuerdo de compromiso vigente y permite al estudiante firmarlo.
/// Flujo:
///   1. Consulta GET /acuerdo/me/estado para saber si ya firmó.
///   2. Si hay acuerdo vigente, consulta GET /acuerdo/vigente para el contenido.
///   3. Renderiza el acuerdo + botón de firma (si no firmó) o sello de firmado.
class CompromisoPage extends StatefulWidget {
  const CompromisoPage({super.key});

  @override
  State<CompromisoPage> createState() => _CompromisoPageState();
}

class _CompromisoPageState extends State<CompromisoPage> {
  bool _loading = true;
  String? _error;
  EstadoFirmaAcuerdo? _estado;
  AcuerdoVigente? _acuerdo;

  bool _firmando = false;
  String? _errorFirma;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Carga de datos ────────────────────────────────────────────────────────

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorFirma = null;
    });
    try {
      final estado = await AcuerdoService.obtenerEstadoAcuerdo();
      AcuerdoVigente? acuerdo;
      if (estado.hayAcuerdoVigente) {
        acuerdo = await AcuerdoService.obtenerAcuerdoVigente();
      }
      if (!mounted) return;
      setState(() {
        _estado = estado;
        _acuerdo = acuerdo;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _parseDioError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el acuerdo. Inténtalo de nuevo.';
      });
    }
  }

  // ── Firma ─────────────────────────────────────────────────────────────────

  Future<void> _procesarFirma() async {
    final confirmed = await _mostrarDialogoConfirmacion();
    if (confirmed != true || !mounted) return;

    setState(() {
      _firmando = true;
      _errorFirma = null;
    });

    try {
      final nuevoEstado = await AcuerdoService.firmarAcuerdo();
      if (!mounted) return;
      setState(() {
        _estado = nuevoEstado;
        _firmando = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _firmando = false;
        _errorFirma = _parseDioError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _firmando = false;
        _errorFirma = 'No se pudo registrar la firma. Inténtalo de nuevo.';
      });
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.compromiso.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.draw_outlined,
                color: AppColors.compromiso,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Firmar compromiso',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Leíste y estás de acuerdo con el acuerdo de compromiso?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.compromiso,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _parseDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 404) return 'No hay un acuerdo de compromiso vigente aún.';
    if (status == 403) return 'No tienes permiso para realizar esta acción.';
    if (status != null) return 'Error del servidor ($status). Inténtalo de nuevo.';
    return 'No se pudo conectar con el servidor. Verifica tu conexión.';
  }

  String _formatearFecha(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError(_error!);
    if (_estado?.hayAcuerdoVigente == false) return _buildSinAcuerdo();
    if (_acuerdo == null) return _buildError('No se pudo cargar el contenido del acuerdo.');
    return _buildContenido(_acuerdo!);
  }

  Widget _buildLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.compromiso.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando acuerdo...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el acuerdo',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.compromiso,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinAcuerdo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.compromiso.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin acuerdo vigente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay un acuerdo de compromiso publicado aún.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(AcuerdoVigente acuerdo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firmado = _estado?.firmado ?? false;

    return Column(
      children: [
        _buildHeader(acuerdo),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildDocumento(acuerdo.documento, isDark),
              const SizedBox(height: 24),
              if (_errorFirma != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorFirma!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (firmado)
                _buildFirmado(_estado!.firmadoAt)
              else
                _buildBotonFirma(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AcuerdoVigente acuerdo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.compromiso,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acuerdo de Compromiso',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fundación Carmen Goudie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Versión',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearFecha(acuerdo.createdAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumento(DocumentoCompromiso doc, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1D1D1D) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          if (doc.subtitulo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              doc.subtitulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.compromiso,
              ),
            ),
          ],
          if (doc.abstract.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              doc.abstract,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
          if (doc.topicos.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...doc.topicos.map((topico) => _buildTopico(topico, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildTopico(Topico topico, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topico.nombre != null && topico.nombre!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.compromiso,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    topico.nombre!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ...topico.puntos.map(
            (punto) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.compromiso.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      punto,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFirma() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _firmando ? null : _procesarFirma,
        icon: _firmando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.draw_outlined, size: 20),
        label: Text(
          _firmando ? 'Firmando...' : 'Firmar acuerdo',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.compromiso,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.compromiso.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildFirmado(DateTime? firmadoAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acuerdo firmado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
                if (firmadoAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Firmado el ${_formatearFecha(firmadoAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
