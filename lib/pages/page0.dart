import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';
import 'package:test1/services/notification_service.dart';
import 'package:test1/services/ramo_service.dart';
import 'package:test1/services/semestre_service.dart';

/// Página 0: Mis Ramos
class Page0 extends StatefulWidget {
  const Page0({super.key});

  @override
  State<Page0> createState() => _Page0State();
}

class _Page0State extends State<Page0> {
  final List<Ramo> _ramos = [];
  List<Semestre> _semestres = [];
  Semestre _semestreActual = Semestre(
    id: 'SEM-2025-2',
    nombre: '2025-2',
    anio: 2025,
    numeroSemestre: 2,
    esActual: true,
  );
  Semestre _semestreSeleccionado = Semestre(
    id: 'SEM-2025-2',
    nombre: '2025-2',
    anio: 2025,
    numeroSemestre: 2,
    esActual: true,
  );

  final TextEditingController _nombreController = TextEditingController();
  int _intentoSeleccionado = 1;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarSemestres();
  }

  Future<void> _cargarSemestres() async {
    final semestreActual = await SemestreService.obtenerSemestreActual();
    final semestres = await SemestreService.obtenerTodosSemestres();
    setState(() {
      _semestreActual = semestreActual;
      _semestres = semestres;
      _semestreSeleccionado = semestreActual;
    });
    await _loadRamos();
  }

  Future<void> _loadRamos() async {
    final loaded = await RamoService.leerRamos();
    setState(() {
      _ramos.clear();
      _ramos.addAll(loaded);
    });
  }

  void _abrirFormularioRamo({int? index}) {
    if (index != null) {
      final item = _ramos[index];
      _nombreController.text = item.nombre;
      _intentoSeleccionado = item.intento;
    } else {
      _nombreController.clear();
      _intentoSeleccionado = 1;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                      index == null ? 'Agregar Ramo' : 'Editar Ramo',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputLabel('Nombre del ramo *'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nombreController,
                hintText: 'Ej: Calculo II',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 14),
              _buildInputLabel('Intento'),
              const SizedBox(height: 6),
              _buildDropdownField(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _guardarRamo(index: index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.misRamos,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(index == null ? 'Guardar Ramo' : 'Guardar Cambios'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _guardarRamo({int? index}) async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;

    setState(() {
      final nuevo = Ramo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: nombre,
        intento: _intentoSeleccionado,
        semestreId: _semestreSeleccionado.id,
      );
      if (index == null) {
        _ramos.add(nuevo);
      } else {
        _ramos[index] = nuevo;
      }
    });

    // disparar notificación (no await para evitar usar context tras espera)
    if (index == null) {
      NotificationService.agregar(
        title: 'Ramo agregado',
        body: 'Agregaste $nombre (intento $_intentoSeleccionado).',
        type: 'info',
        iconKey: 'mis_ramos',
      );
    } else {
      NotificationService.agregar(
        title: 'Ramo modificado',
        body: 'Modificaste $nombre (intento $_intentoSeleccionado).',
        type: 'info',
        iconKey: 'mis_ramos',
      );
    }

    Navigator.pop(context);
    // persistir en background
    await RamoService.guardarRamos(_ramos);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrar ramos del semestre seleccionado
    final ramosSemestre = _ramos
        .where((ramo) => ramo.semestreId == _semestreSeleccionado.id)
        .toList();
    
    final puedeAgregar = _semestreSeleccionado.esActual;

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
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No hay ramos registrados para este semestre',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == ramosSemestre.length) {
                      return Column(
                        children: [
                          if (ramosSemestre.isNotEmpty) _buildListDivider(isDark),
                          const SizedBox(height: 12),
                          _buildAgregarRamoCard(isDark),
                        ],
                      );
                    }
                    return _buildRamoCard(ramosSemestre[index], isDark, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.misRamos,
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
                  'Semestre actual',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _semestreActual.nombre,
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
                  '${_ramos.where((r) => r.semestreId == _semestreActual.id).length}',
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
    if (_semestres.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    (s) => s.id == value,
                  );
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRamoCard(Ramo item, bool isDark, int index) {
    final cardColor = isDark ? const Color(0xFF1D1D1D) : AppColors.pageBackground;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.misRamos.withValues(alpha: 0.12),
              child: Icon(
                Icons.menu_book,
                color: AppColors.misRamos,
              ),
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
                  Text(
                    'Intento ${item.intento}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _abrirFormularioRamo(index: index),
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
              child: Icon(
                Icons.add,
                color: AppColors.misRamos,
              ),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.pageBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildDropdownField() {
    return DropdownButtonFormField<int>(
      initialValue: _intentoSeleccionado,
      items: const [
        DropdownMenuItem(value: 1, child: Text('1°')),
        DropdownMenuItem(value: 2, child: Text('2°')),
        DropdownMenuItem(value: 3, child: Text('3°')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _intentoSeleccionado = value;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

// _RamoItem replaced by Ramo model in ramo_service.dart
