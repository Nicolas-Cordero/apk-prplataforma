import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/services/notification_service.dart';
import 'package:carmen_goudie/services/ramo_service.dart';
import 'package:carmen_goudie/services/promedio_final_service.dart';
import 'package:carmen_goudie/services/semestre_service.dart';

/// Página de Mis Notas
class MisNotasPage extends StatefulWidget {
  const MisNotasPage({super.key});

  @override
  State<MisNotasPage> createState() => _MisNotasPageState();
}

class _MisNotasPageState extends State<MisNotasPage> {
  List<Semestre> _semestres = [];
  Semestre _semestreSeleccionado = Semestre(
    id: 'SEM-2025-2',
    nombre: '2025-2',
    anio: 2025,
    numeroSemestre: 2,
    esActual: true,
  );
  List<Ramo> _ramosPersistidos = [];
  List<PromedioFinalRegistro> _promediosGuardados = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final semestres = await SemestreService.obtenerTodosSemestres();
      final semestreActual = await SemestreService.obtenerSemestreActual();
      final loaded = await RamoService.leerRamos();
      final promedios = await PromedioFinalService.leerPromedios();
      setState(() {
        _semestres = semestres;
        _semestreSeleccionado = semestreActual;
        _ramosPersistidos = loaded;
        _promediosGuardados = promedios;
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

  PromedioFinalRegistro? _buscarPromedio(String ramoId) {
    try {
      return _promediosGuardados.firstWhere(
        (promedio) =>
            promedio.ramoId == ramoId &&
            promedio.semestreId == _semestreSeleccionado.id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _guardarPromedioFinal(Ramo ramo, double promedioFinal) async {
    final nuevoRegistro = PromedioFinalRegistro(
      ramoId: ramo.id,
      semestreId: ramo.semestreId,
      ramoNombre: ramo.nombre,
      intento: ramo.intento,
      promedioFinal: promedioFinal,
    );

    setState(() {
      _promediosGuardados.removeWhere(
        (promedio) =>
            promedio.ramoId == ramo.id &&
            promedio.semestreId == _semestreSeleccionado.id,
      );
      _promediosGuardados.add(nuevoRegistro);
    });

    await PromedioFinalService.guardarPromedios(_promediosGuardados);

    await NotificationService.agregar(
      title: 'Promedio final registrado',
      body: 'Guardaste ${ramo.nombre} con promedio ${promedioFinal.toStringAsFixed(2)}',
      type: 'info',
      iconKey: 'mis_notas',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploadBtnBg = isDark ? const Color(0xFF1F1F1F) : AppColors.pageBackground;
    final ramosDelSemestre = _ramosPersistidos
        .where((ramo) => ramo.semestreId == _semestreSeleccionado.id)
        .toList();
    final promediosRegistrados = ramosDelSemestre
        .where((ramo) => _buscarPromedio(ramo.id) != null)
        .length;
    final puedeEditar = _semestreSeleccionado.esActual;
    return Scaffold(
      backgroundColor: isDark ? null : AppColors.pageBackground,
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
                Text(
                  _semestreSeleccionado.esActual
                      ? 'Semestre actual'
                      : 'Semestre histórico',
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
                              'Promedios registrados',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$promediosRegistrados de ${ramosDelSemestre.length}',
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
                  label: const Text('Subir certificado de promedios', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 16),
                Center(child: _buildSemesterSelector()),
                const SizedBox(height: 16),
                if (ramosDelSemestre.isNotEmpty) ...[
                  Text(
                    puedeEditar ? 'Promedios por ramo' : 'Promedios históricos por ramo',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...ramosDelSemestre.map((ramo) => _buildPromedioCard(ramo, _buscarPromedio(ramo.id), puedeEditar)),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No hay ramos registrados para este semestre',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
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

  Widget _buildSemesterSelector() {
    if (_semestres.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _semestreSeleccionado.id,
            isExpanded: true,
            alignment: Alignment.center,
            icon: const Icon(Icons.keyboard_arrow_down),
            selectedItemBuilder: (context) {
              return _semestres.map((semestre) {
                return Center(
                  child: Text(
                    'Semestre: ${semestre.nombre}',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: _semestres.map((semestre) {
              return DropdownMenuItem(
                value: semestre.id,
                child: Text(
                  'Semestre: ${semestre.nombre}',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _semestreSeleccionado = _semestres.firstWhere(
                  (semestre) => semestre.id == value,
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPromedioCard(
    Ramo ramo,
    PromedioFinalRegistro? promedio,
    bool puedeEditar,
  ) {
    final controller = TextEditingController(text: promedio?.promedioFinal.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : AppColors.pageBackground;
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
                child: Text(ramo.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: primaryText)),
              ),
              Text('Intento ${ramo.intento}', style: TextStyle(color: secondaryText)),
            ],
          ),
          const SizedBox(height: 8),
          if (puedeEditar)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      hintText: 'Ingresa tu promedio final',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0B0B0B) : AppColors.pageBackground,
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
                    // Evita persistir un 0.0 falso (y una notificación "Guardaste … 0.00")
                    // cuando el campo está vacío o contiene texto no numérico.
                    final promedioFinal = double.tryParse(controller.text.trim());
                    if (promedioFinal == null) return;
                    _guardarPromedioFinal(ramo, promedioFinal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.misNotas,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0B0B) : AppColors.pageBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                promedio != null
                    ? 'Promedio final registrado: ${promedio.promedioFinal.toStringAsFixed(2)}'
                    : 'Promedio final no registrado',
                style: TextStyle(color: promedio != null ? primaryText : secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}
