import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test1/constants/app_colors.dart';
import 'package:test1/models/becario_item.dart';
import 'package:test1/widgets/becario_detail_sheet.dart';

/// Página 3: Becarios
class Page3 extends StatefulWidget {
  const Page3({super.key});

  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  late Future<_BecariosData> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filtroUniversidad = false;
  bool _filtroCarrera = false;
  bool _filtroLiceo = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _cargarBecarios();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim();
    if (value == _query) return;
    setState(() {
      _query = value;
    });
  }

  Future<List<Map<String, dynamic>>> _cargarLista(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final data = jsonDecode(jsonString);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      return [data];
    }
    return [];
  }

  Future<Map<String, dynamic>?> _cargarMapa(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final data = jsonDecode(jsonString);
    if (data is Map<String, dynamic>) return data;
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) return item;
      }
    }
    return null;
  }

  Future<_BecariosData> _cargarBecarios() async {
    final estudiantes = await _cargarLista('assets/data/students.json');
    final carreras = await _cargarLista('assets/data/carreras.json');
    final universidades = await _cargarLista('assets/data/universidades.json');
    final liceoData = await _cargarMapa('assets/data/liceos.json');

    final carrerasPorRut = <String, Map<String, dynamic>>{};
    for (final carrera in carreras) {
      final rut = carrera['rut_estudiante'] as String?;
      if (rut != null && rut.isNotEmpty) {
        carrerasPorRut[rut] = carrera;
      }
    }

    final universidadesPorCodigo = <String, String>{};
    for (final universidad in universidades) {
      final codigo = universidad['codigo'] as String?;
      final nombre = universidad['nombre'] as String?;
      if (codigo != null && codigo.isNotEmpty && nombre != null && nombre.isNotEmpty) {
        universidadesPorCodigo[codigo] = nombre;
      }
    }

    final liceoRbd = liceoData?['rbd_liceo'] as String? ?? '';
    final liceoNombre = liceoData?['nombre'] as String? ?? 'No disponible';

    final items = <BecarioItem>[];
    for (final estudiante in estudiantes) {
      final rut = estudiante['rut_estudiante'] as String? ?? '';
      final carrera = carrerasPorRut[rut];
      final codigoUniversidad =
          carrera?['codigo_universidad'] as String? ?? 'No disponible';
        final nombreUniversidad = universidadesPorCodigo[codigoUniversidad] ?? codigoUniversidad;
      final nombreCarrera =
          carrera?['nombre'] as String? ?? 'No disponible';
      final rbd = estudiante['rbd_liceo'] as String? ?? '';
      final liceo = rbd.isNotEmpty && rbd == liceoRbd
          ? liceoNombre
          : 'No disponible';

      items.add(
        BecarioItem(
          rut: rut,
          nombre: estudiante['nombre'] as String? ?? 'Sin nombre',
          apellido: estudiante['apellido'] as String? ?? '',
          universidad: nombreUniversidad,
          carrera: nombreCarrera,
          liceo: liceo,
          generacion: estudiante['generacion'] as int? ?? 0,
          telefono: estudiante['telefono'] as String? ?? 'No disponible',
        ),
      );
    }

    final actual = items.isNotEmpty ? items.first : null;
    final otros = actual == null
        ? items
        : items.where((item) => item.rut != actual.rut).toList();

    return _BecariosData(actual: actual, items: otros);
  }

  List<BecarioItem> _filtrar(
    List<BecarioItem> items,
    BecarioItem? actual,
  ) {
    final query = _query.toLowerCase();
    return items.where((item) {
      if (query.isNotEmpty) {
        final nombreCompleto = item.nombreCompleto.toLowerCase();
        if (!nombreCompleto.contains(query)) return false;
      }

      if (actual == null) return true;
      if (_filtroUniversidad && item.universidad != actual.universidad) {
        return false;
      }
      if (_filtroCarrera && item.carrera != actual.carrera) {
        return false;
      }
      if (_filtroLiceo && item.liceo != actual.liceo) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<_BecariosData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar becarios',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }

        final data = snapshot.data ?? _BecariosData(items: [], actual: null);
        final filtrados = _filtrar(data.items, data.actual);
        final tieneFiltros =
            _filtroUniversidad || _filtroCarrera || _filtroLiceo || _query.isNotEmpty;
        final todosActivos = !tieneFiltros;

        return Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 14),
            _buildSearchBar(isDark),
            const SizedBox(height: 12),
            _buildFiltersRow(todosActivos, isDark),
            const SizedBox(height: 8),
            _buildCountRow(filtrados.length),
            const SizedBox(height: 8),
            Expanded(
              child: filtrados.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildCard(filtrados[index], isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.becarios,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Red de apoyo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Becarios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final iconColor = isDark ? Colors.white54 : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: iconColor),
          hintText: 'Buscar becario...',
          hintStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow(bool todosActivos, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTodosChip(todosActivos, isDark),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'Mi U',
            icon: Icons.apartment,
            selected: _filtroUniversidad,
            isDark: isDark,
            onTap: () {
              setState(() {
                _filtroUniversidad = !_filtroUniversidad;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'Mi Carrera',
            icon: Icons.school,
            selected: _filtroCarrera,
            isDark: isDark,
            onTap: () {
              setState(() {
                _filtroCarrera = !_filtroCarrera;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'Mi Liceo',
            icon: Icons.account_balance,
            selected: _filtroLiceo,
            isDark: isDark,
            onTap: () {
              setState(() {
                _filtroLiceo = !_filtroLiceo;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodosChip(bool activo, bool isDark) {
    final color = AppColors.misNotas;
    final inactiveBorder = isDark ? Colors.white24 : Colors.grey.shade300;
    final textColor = activo ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activo ? color.withValues(alpha: 0.6) : inactiveBorder),
      ),
      child: Text(
        'Todos',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final color = selected
        ? AppColors.becarios
        : (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final textColor = selected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    final borderColor = selected
        ? AppColors.becarios
        : (isDark ? Colors.white24 : Colors.grey.shade300);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$count becarios encontrados',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Text(
        'No se encontraron becarios',
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }

  Widget _buildCard(BecarioItem item, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1D1D1D) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return InkWell(
      onTap: () => _mostrarDetalle(item),
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
              backgroundColor: AppColors.becarios.withValues(alpha: 0.18),
              child: Text(
                item.iniciales,
                style: TextStyle(
                  color: AppColors.becarios,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.carrera,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.universidad,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(BecarioItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BecarioDetailSheet(item: item);
      },
    );
  }
}

class _BecariosData {
  final List<BecarioItem> items;
  final BecarioItem? actual;

  _BecariosData({required this.items, required this.actual});
}
