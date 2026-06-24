import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/services/ramo_service.dart';
import 'package:carmen_goudie/services/semestre_service.dart';

class MisNotasPage extends StatefulWidget {
  const MisNotasPage({super.key});

  @override
  State<MisNotasPage> createState() => _MisNotasPageState();
}

class _MisNotasPageState extends State<MisNotasPage> {
  bool _cargando = true;
  String? _error;

  List<Ramo> _ramosActual = [];
  Semestre? _semestreActual;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ramos = await RamoService.obtenerMisRamos();
      final ids = ramos.map((r) => int.parse(r.semestreId)).toSet();
      final semestres = await SemestreService.obtenerPorIds(ids);
      final semestresConFlag = SemestreService.marcarActual(semestres, ramos);
      final semestreActual =
          semestresConFlag.where((s) => s.esActual).firstOrNull;
      final ramosActual = semestreActual == null
          ? <Ramo>[]
          : ramos.where((r) => r.semestreId == semestreActual.id).toList();
      setState(() {
        _semestreActual = semestreActual;
        _ramosActual = ramosActual;
        _cargando = false;
      });
    } catch (_) {
      setState(() {
        _cargando = false;
        _error = 'Error al cargar los datos. Intenta de nuevo.';
      });
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _editarNota(Ramo ramo) {
    final controller = TextEditingController(
      text: ramo.notaFinal != null
          ? ramo.notaFinal!.toStringAsFixed(1).replaceAll('.', ',')
          : '',
    );
    bool guardando = false;
    String? errorModal;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ramo.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            guardando ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (errorModal != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorModal!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Nota final (1,0 – 7,0)',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Ej: 5,5',
                      filled: true,
                      fillColor: AppColors.pageBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: guardando
                          ? null
                          : () async {
                              final texto = controller.text
                                  .trim()
                                  .replaceAll(',', '.');
                              final raw = double.tryParse(texto);
                              if (raw == null || raw < 1.0 || raw > 7.0) {
                                setModalState(() => errorModal =
                                    'Ingresa una nota entre 1,0 y 7,0');
                                return;
                              }
                              // El backend valida máximo 1 decimal.
                              final nota = double.parse(
                                  raw.toStringAsFixed(1));
                              setModalState(() => guardando = true);
                              try {
                                final actualizado =
                                    await RamoService.actualizarRamo(
                                  int.parse(ramo.id),
                                  UpdateRamoDto(notaFinal: nota),
                                );
                                setState(() {
                                  final idx = _ramosActual
                                      .indexWhere((r) => r.id == ramo.id);
                                  if (idx >= 0) {
                                    _ramosActual[idx] = actualizado;
                                  }
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (_) {
                                setModalState(() {
                                  guardando = false;
                                  errorModal =
                                      'No se pudo guardar la nota. Intenta de nuevo.';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.misNotas,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Guardar nota'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _subirCertificado(Ramo ramo) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final filename = result.files.single.name;

    try {
      final actualizado = await RamoService.subirCertificado(
        int.parse(ramo.id),
        bytes,
        filename,
      );
      setState(() {
        final idx = _ramosActual.indexWhere((r) => r.id == ramo.id);
        if (idx >= 0) _ramosActual[idx] = actualizado;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo subir el certificado. Intenta de nuevo.'),
        ),
      );
    }
  }

  Future<void> _verCertificado(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo abrir el certificado.')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.misNotas,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final notasRegistradas =
        _ramosActual.where((r) => r.notaFinal != null).length;

    return Scaffold(
      backgroundColor: isDark ? null : AppColors.pageBackground,
      body: Column(
        children: [
          _buildHeader(isDark, notasRegistradas),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, int notasRegistradas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.misNotas,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _semestreActual != null
                ? 'Semestre ${_semestreActual!.nombre}'
                : 'Sin semestre abierto',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mis Promedios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_semestreActual != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notas registradas',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$notasRegistradas de ${_ramosActual.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_semestreActual == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No tienes ramos abiertos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
        ),
      );
    }

    if (_ramosActual.isEmpty) {
      return const Center(
        child: Text(
          'No hay ramos registrados en el semestre abierto.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.misNotas,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _ramosActual.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildPromedioCard(_ramosActual[index], isDark),
      ),
    );
  }

  Widget _buildPromedioCard(Ramo ramo, bool isDark) {
    final cardBg =
        isDark ? const Color(0xFF121212) : AppColors.pageBackground;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText =
        isDark ? Colors.white70 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + Intento
          Row(
            children: [
              Expanded(
                child: Text(
                  ramo.nombre,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primaryText),
                ),
              ),
              Text(
                'Intento ${ramo.intento}',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Nota final
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0B0B0B)
                  : AppColors.pageBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ramo.notaFinal != null
                        ? 'Nota final: ${ramo.notaFinal!.toStringAsFixed(1)}'
                        : 'Nota final no registrada',
                    style: TextStyle(
                      color: ramo.notaFinal != null
                          ? primaryText
                          : secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editarNota(ramo),
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(
                      ramo.notaFinal != null ? 'Editar' : 'Agregar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.misNotas,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Certificado
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _subirCertificado(ramo),
                icon: const Icon(Icons.upload_file, size: 15),
                label: Text(ramo.urlCertificado != null
                    ? 'Reemplazar certificado'
                    : 'Subir certificado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.misNotas,
                  side: BorderSide(
                      color: AppColors.misNotas.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              if (ramo.urlCertificado != null)
                OutlinedButton.icon(
                  onPressed: () =>
                      _verCertificado(ramo.urlCertificado!),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text('Ver certificado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.misNotas,
                    side: BorderSide(
                        color:
                            AppColors.misNotas.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
