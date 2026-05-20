import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test1/constants/app_colors.dart';
import 'package:test1/services/notification_service.dart';
import 'package:test1/services/ramo_service.dart';

/// Página 1: Mis Notas
class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  int _ramosTotales = 0;
  final List<_NotaItem> _notas = [];
  List<Ramo> _ramosPersistidos = [];

  @override
  void initState() {
    super.initState();
    _loadPersistedRamos();
  }

  Future<void> _loadPersistedRamos() async {
    try {
      final loaded = await RamoService.leerRamos();
      setState(() {
        _ramosPersistidos = loaded;
        // inicializar notas con ramos existentes si aún no hay notas
        if (_notas.isEmpty && _ramosPersistidos.isNotEmpty) {
          for (final r in _ramosPersistidos) {
            _notas.add(_NotaItem(ramo: r.nombre, intento: r.intento));
          }
          _ramosTotales = _ramosPersistidos.length;
        }
      });
    } catch (_) {}
  }

  Future<void> _subirCertificado() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = File(result.files.single.path!);

    // Guardar copia en carpeta local assets/data/uploads (temporal)
    final dir = Directory('${Directory.systemTemp.path}/test1/uploads');
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File('${dir.path}/${result.files.single.name}');
    await dest.writeAsBytes(await file.readAsBytes());

    await NotificationService.agregar(
      title: 'Certificado subido',
      body: 'Subiste ${result.files.single.name}',
      type: 'info',
      iconKey: 'mis_notas',
    );
  }

  void _agregarNota(_NotaItem item) async {
    setState(() {
      _notas.add(item);
      _ramosTotales = _ramosTotales < _notas.length ? _notas.length : _ramosTotales;
    });
    await NotificationService.agregar(
      title: 'Nota registrada',
      body: 'Ingresaste nota para ${item.ramo} (intento ${item.intento})',
      type: 'info',
      iconKey: 'mis_notas',
    );
  }

  void _modificarNota(int index, double nuevaNota) async {
    setState(() {
      _notas[index] = _NotaItem(
        ramo: _notas[index].ramo,
        intento: _notas[index].intento,
        nota: nuevaNota,
      );
    });
    await NotificationService.agregar(
      title: 'Nota modificada',
      body: 'Has actualizado la nota de ${_notas[index].ramo}',
      type: 'info',
      iconKey: 'mis_notas',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploadBtnBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.misNotas,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semestre 2025-2',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mis Notas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notas ingresadas',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_notas.length} de $_ramosTotales',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: uploadBtnBg,
                    foregroundColor: AppColors.misNotas,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                    elevation: isDark ? 0 : 0,
                  ),
                  onPressed: _subirCertificado,
                  icon: Icon(Icons.upload_file, color: AppColors.misNotas),
                  label: const Text('Subir certificado de notas', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 16),
                if (_ramosPersistidos.isNotEmpty) ...[
                  const Text('Notas por ramo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._notas.map((n) => _buildNotaCard(n)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCard(_NotaItem item) {
    final controller = TextEditingController(text: item.nota?.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.ramo, style: TextStyle(fontWeight: FontWeight.bold, color: primaryText)),
              ),
              Text('Intento ${item.intento}', style: TextStyle(color: secondaryText)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu nota final',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final n = double.tryParse(controller.text.trim()) ?? 0.0;
                  final index = _notas.indexOf(item);
                  if (index >= 0) _modificarNota(index, n);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.misNotas,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotaItem {
  final String ramo;
  final int intento;
  final double? nota;

  const _NotaItem({required this.ramo, required this.intento, this.nota});
}
