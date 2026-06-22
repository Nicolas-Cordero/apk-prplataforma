import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/services/notification_service.dart';
import 'package:carmen_goudie/services/ramo_service.dart';
import 'package:carmen_goudie/services/semestre_service.dart';

/// Página de Mis Ramos — conectada al backend.
class MisRamosPage extends StatefulWidget {
  const MisRamosPage({super.key});

  @override
  State<MisRamosPage> createState() => _MisRamosPageState();
}

class _MisRamosPageState extends State<MisRamosPage> {
  // ── Estado de carga ───────────────────────────────────────────────────────
  bool _cargando = true;
  String? _errorCarga;

  // ── Datos ─────────────────────────────────────────────────────────────────
  List<Ramo> _ramos = [];
  List<Semestre> _semestres = [];

  /// null cuando no hay ningún semestre con ramos en estado CURSANDO.
  Semestre? _semestreActual;

  /// Semestre actualmente visible en la lista (cambia con el selector).
  Semestre? _semestreSeleccionado;

  /// codigo_carrera del estudiante, necesario para crear nuevos ramos.
  int? _codigoCarrera;

  // ── Formulario ────────────────────────────────────────────────────────────
  final TextEditingController _nombreController = TextEditingController();
  EstadoRamo _estadoSeleccionado = EstadoRamo.CURSANDO;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // ── Carga ─────────────────────────────────────────────────────────────────

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      // 1. Obtener ramos primero para saber qué semestres necesitamos.
      final ramos = await RamoService.obtenerMisRamos();

      // 2. Con los IDs de semestre conocidos, pedir solo esos (no todos).
      final semestreIds = ramos.map((r) => int.parse(r.semestreId)).toSet();
      final (semestres, perfil) = await (
        SemestreService.obtenerPorIds(semestreIds),
        EstudianteService.obtenerPerfilPropio(),
      ).wait;

      final semestresConFlag = SemestreService.marcarActual(semestres, ramos);
      final actual = semestresConFlag.where((s) => s.esActual).firstOrNull;
      final codigoCarrera = perfil.carreras.firstOrNull?.codigoCarrera
          ?? ramos.firstOrNull?.codigoCarrera;

      setState(() {
        _ramos = ramos;
        _semestres = semestresConFlag;
        _semestreActual = actual;
        _semestreSeleccionado = actual ?? semestresConFlag.lastOrNull;
        _codigoCarrera = codigoCarrera;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _errorCarga = 'No se pudieron cargar los ramos. Verifica tu conexión.';
        _cargando = false;
      });
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _abrirFormularioRamo({Ramo? ramoEditar}) {
    final esEdicion = ramoEditar != null;
    _nombreController.text = esEdicion ? ramoEditar.nombre : '';
    _estadoSeleccionado =
        esEdicion ? ramoEditar.estado : EstadoRamo.CURSANDO;

    // Estado del modal declarado ANTES del StatefulBuilder para que persista
    // entre rebuilds (si estuviera dentro del builder se reiniciaría cada vez).
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
            final currentError = errorModal;
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
                          esEdicion ? 'Editar Ramo' : 'Agregar Ramo',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: guardando
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (currentError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInputLabel('Nombre del ramo *'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nombreController,
                    hintText: 'Ej: Cálculo II',
                  ),
                  if (esEdicion) ...[
                    const SizedBox(height: 14),
                    _buildInputLabel('Estado'),
                    const SizedBox(height: 6),
                    _buildEstadoDropdown(
                      value: _estadoSeleccionado,
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => _estadoSeleccionado = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: guardando
                          ? null
                          : () async {
                              setModalState(() => guardando = true);
                              final ok = await _guardarRamo(
                                ramoEditar: ramoEditar,
                                errorCallback: (msg) {
                                  setModalState(() => errorModal = msg);
                                },
                              );
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                              } else {
                                setModalState(() => guardando = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.misRamos,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(esEdicion ? 'Guardar Cambios' : 'Guardar Ramo'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Llama al backend para crear o actualizar un ramo.
  /// Retorna true si tuvo éxito, false si hubo error.
  Future<bool> _guardarRamo({
    Ramo? ramoEditar,
    required void Function(String) errorCallback,
  }) async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      errorCallback('El nombre del ramo es obligatorio.');
      return false;
    }

    try {
      if (ramoEditar == null) {
        // Crear
        final semestreId = int.parse(_semestreActual!.id);
        final codigoCarrera = _codigoCarrera!;
        final nuevo = await RamoService.crearRamo(
          CreateRamoDto(
            semestreId: semestreId,
            codigoCarrera: codigoCarrera,
            nombre: nombre,
          ),
        );
        setState(() => _ramos.add(nuevo));
        await NotificationService.agregar(
          title: 'Ramo agregado',
          body: 'Agregaste $nombre.',
          type: 'info',
          iconKey: 'mis_ramos',
        );
      } else {
        // Editar
        final actualizado = await RamoService.actualizarRamo(
          int.parse(ramoEditar.id),
          UpdateRamoDto(nombre: nombre, estado: _estadoSeleccionado),
        );
        setState(() {
          final idx = _ramos.indexWhere((r) => r.id == ramoEditar.id);
          if (idx >= 0) _ramos[idx] = actualizado;
        });
        await NotificationService.agregar(
          title: 'Ramo actualizado',
          body: 'Actualizaste $nombre.',
          type: 'info',
          iconKey: 'mis_ramos',
        );
      }
      return true;
    } catch (e) {
      errorCallback('No se pudo guardar el ramo. Intenta de nuevo.');
      return false;
    }
  }

  /// Toggle "Puedo ayudar" — local únicamente, no persiste en el backend.
  void _togglePuedoAyudar(Ramo item, bool value) {
    setState(() {
      final idx = _ramos.indexWhere((r) => r.id == item.id);
      if (idx >= 0) _ramos[idx] = _ramos[idx].copyWith(puedoAyudar: value);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_cargando) {
      return Column(
        children: [
          _buildHeader(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorCarga != null) {
      return Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(
                    _errorCarga!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cargarDatos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.misRamos,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final semestreVisible = _semestreSeleccionado;
    final actual = _semestreActual;
    final carrera = _codigoCarrera;
    final ramosSemestre = semestreVisible == null
        ? <Ramo>[]
        : _ramos.where((r) => r.semestreId == semestreVisible.id).toList();

    // Solo el semestre actual permite agregar/editar ramos.
    final puedeAgregar = semestreVisible?.esActual == true &&
        actual != null &&
        carrera != null;

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildSemesterSelector(),
        const SizedBox(height: 12),
        Expanded(
          child: ramosSemestre.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          _semestreActual == null && _semestres.isEmpty
                              ? 'No tienes semestres registrados'
                              : _semestreActual == null
                                  ? 'No tienes semestre activo.\nContacta a tu tutor.'
                                  : 'No hay ramos registrados para este semestre',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (puedeAgregar) ...[
                      const SizedBox(height: 16),
                      _buildAgregarRamoCard(isDark),
                    ],
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: ramosSemestre.length + (puedeAgregar ? 1 : 0),
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == ramosSemestre.length) {
                      return Column(
                        children: [
                          _buildListDivider(isDark),
                          const SizedBox(height: 12),
                          _buildAgregarRamoCard(isDark),
                        ],
                      );
                    }
                    return _buildRamoCard(
                      ramosSemestre[index],
                      isDark,
                      esActual: semestreVisible?.esActual == true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final actual = _semestreActual;
    final ramosSemActual = actual == null
        ? <Ramo>[]
        : _ramos.where((r) => r.semestreId == actual.id).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.misRamos,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _semestreActual != null ? 'Semestre actual' : 'Sin semestre activo',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _semestreActual?.nombre ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ramos inscritos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${ramosSemActual.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  Widget _buildSemesterSelector() {
    if (_semestres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _semestreSeleccionado?.id,
              isExpanded: true,
              alignment: Alignment.center,
              icon: const Icon(Icons.keyboard_arrow_down),
              selectedItemBuilder: (context) {
                return _semestres.map((s) {
                  return Center(
                    child: Text(
                      'Semestre: ${s.nombre}',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: _semestres.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    'Semestre: ${s.nombre}',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _semestreSeleccionado =
                      _semestres.firstWhere((s) => s.id == value);
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRamoCard(Ramo item, bool isDark, {required bool esActual}) {
    final cardColor =
        isDark ? const Color(0xFF1D1D1D) : AppColors.pageBackground;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.misRamos.withValues(alpha: 0.12),
                child: Icon(Icons.menu_book, color: AppColors.misRamos),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Intento ${item.intento}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildEstadoBadge(item.estado),
                      ],
                    ),
                  ],
                ),
              ),
              if (esActual)
                InkWell(
                  onTap: () => _abrirFormularioRamo(ramoEditar: item),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.misRamos.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.misRamos,
                    ),
                  ),
                ),
            ],
          ),
          if (!esActual) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                selected: item.puedoAyudar,
                onSelected: (value) => _togglePuedoAyudar(item, value),
                label: const Text('Puedo ayudar'),
                avatar: Icon(
                  item.puedoAyudar
                      ? Icons.check_circle
                      : Icons.volunteer_activism,
                  size: 18,
                  color: item.puedoAyudar ? Colors.white : AppColors.misRamos,
                ),
                backgroundColor: AppColors.pageBackground,
                selectedColor: AppColors.misRamos,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: item.puedoAyudar ? Colors.white : AppColors.misRamos,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: AppColors.misRamos.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoRamo estado) {
    Color color;
    switch (estado) {
      case EstadoRamo.APROBADO:
        color = Colors.green.shade600;
        break;
      case EstadoRamo.REPROBADO:
        color = Colors.red.shade400;
        break;
      case EstadoRamo.ELIMINADO:
        color = Colors.grey.shade500;
        break;
      case EstadoRamo.CURSANDO:
        color = AppColors.misRamos;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAgregarRamoCard(bool isDark) {
    final borderColor = isDark
        ? AppColors.misRamos.withValues(alpha: 0.5)
        : AppColors.misRamos.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => _abrirFormularioRamo(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1D1D) : AppColors.pageBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.misRamos.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppColors.misRamos),
            ),
            const SizedBox(width: 12),
            Text(
              'Agregar ramo',
              style: TextStyle(
                color: AppColors.misRamos,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListDivider(bool isDark) {
    return Container(
      width: double.infinity,
      height: 1,
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.pageBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown({
    required EstadoRamo value,
    required ValueChanged<EstadoRamo?> onChanged,
  }) {
    return DropdownButtonFormField<EstadoRamo>(
      value: value,
      items: EstadoRamo.values
          .map(
            (e) => DropdownMenuItem(value: e, child: Text(e.etiqueta)),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.pageBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }
}
