import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/models/becario_item.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/widgets/becario_detail_sheet.dart';

/// Página de Becarios — muestra la red de becarios activos obtenida del backend.
class BecariosPage extends StatefulWidget {
  const BecariosPage({super.key});

  @override
  State<BecariosPage> createState() => _BecariosPageState();
}

class _BecariosPageState extends State<BecariosPage> {
  late Future<_BecariosData> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filtroUniversidad = false;
  bool _filtroGeneracion = false;
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
    setState(() => _query = value);
  }

  Future<_BecariosData> _cargarBecarios() async {
    final (becarios, propio) = await (
      EstudianteService.obtenerBecariosActivos(),
      EstudianteService.obtenerPerfilPropio(),
    ).wait;

    final items = becarios.map((est) {
      final univNombre =
          est.carreras.firstOrNull?.universidad?.nombre ?? 'No disponible';
      final carreraNombre =
          est.carreras.firstOrNull?.nombre ?? 'No disponible';
      final liceoNombre = est.liceo?.nombre ?? 'No disponible';
      final generacionAnio = est.generacionRel?.anio ?? est.generacionId;
      final telefono =
          est.telefono.isNotEmpty ? est.telefono : 'No disponible';

      return BecarioItem(
        rut: est.rutEstudiante,
        nombre: est.nombre,
        apellido: est.apellido,
        fotoUrl: est.fotoUrl,
        universidad: univNombre,
        carrera: carreraNombre,
        liceo: liceoNombre,
        generacion: generacionAnio,
        telefono: telefono,
        esUsuarioActual: est.rutEstudiante == propio.rutEstudiante,
      );
    }).toList();

    return _BecariosData(
      items: items,
      rutPropio: propio.rutEstudiante,
      propioGeneracion: propio.generacionRel?.anio ?? propio.generacionId,
      propioUniversidad:
          propio.carreras.firstOrNull?.universidad?.nombre,
      propioLiceoNombre: propio.liceo?.nombre,
    );
  }

  List<BecarioItem> _filtrar(List<BecarioItem> items, _BecariosData data) {
    final query = _query.toLowerCase();
    return items.where((item) {
      // Búsqueda reactiva por nombre, universidad y liceo.
      if (query.isNotEmpty) {
        final matchNombre = item.nombreCompleto.toLowerCase().contains(query);
        final matchUniv = item.universidad.toLowerCase().contains(query);
        final matchLiceo = item.liceo.toLowerCase().contains(query);
        if (!matchNombre && !matchUniv && !matchLiceo) return false;
      }

      // Filtro "Mi U" — solo cuando hay universidad propia registrada.
      if (_filtroUniversidad && data.propioUniversidad != null) {
        if (item.universidad != data.propioUniversidad) return false;
      }

      // Filtro "Mi Generación".
      if (_filtroGeneracion) {
        if (item.generacion != data.propioGeneracion) return false;
      }

      // Filtro "Mi Liceo" — solo cuando hay liceo propio registrado.
      if (_filtroLiceo && data.propioLiceoNombre != null) {
        if (item.liceo != data.propioLiceoNombre) return false;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.becarios.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando becarios...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar becarios',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? _BecariosData.empty();
        final filtrados = _filtrar(data.items, data);
        final tieneFiltros = _filtroUniversidad ||
            _filtroGeneracion ||
            _filtroLiceo ||
            _query.isNotEmpty;

        return Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 14),
            _buildSearchBar(isDark),
            const SizedBox(height: 12),
            _buildFiltersRow(data, !tieneFiltros, isDark),
            const SizedBox(height: 8),
            _buildCountRow(filtrados.length),
            const SizedBox(height: 8),
            Expanded(
              child: filtrados.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _buildCard(filtrados[index], isDark),
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
          hintText: 'Buscar por nombre, universidad o liceo...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow(_BecariosData data, bool todosActivos, bool isDark) {
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
            enabled: data.puedeUniversidad,
            isDark: isDark,
            onTap: () {
              if (!data.puedeUniversidad) return;
              setState(() => _filtroUniversidad = !_filtroUniversidad);
            },
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'Mi Generación',
            icon: Icons.calendar_today,
            selected: _filtroGeneracion,
            enabled: true,
            isDark: isDark,
            onTap: () => setState(() => _filtroGeneracion = !_filtroGeneracion),
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'Mi Liceo',
            icon: Icons.account_balance,
            selected: _filtroLiceo,
            enabled: data.puedeLiceo,
            isDark: isDark,
            onTap: () {
              if (!data.puedeLiceo) return;
              setState(() => _filtroLiceo = !_filtroLiceo);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodosChip(bool activo, bool isDark) {
    final color = AppColors.misNotas;
    final inactiveBorder = isDark ? Colors.white24 : Colors.grey.shade300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activo ? color.withValues(alpha: 0.6) : inactiveBorder,
        ),
      ),
      child: Text(
        'Todos',
        style: TextStyle(
          color: activo
              ? Colors.white
              : (isDark ? Colors.white60 : Colors.grey.shade600),
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
    required bool enabled,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.becarios;
    final chipColor = selected
        ? activeColor
        : (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final textColor = !enabled
        ? (isDark ? Colors.white30 : Colors.grey.shade400)
        : selected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87);
    final borderColor = !enabled
        ? (isDark ? Colors.white12 : Colors.grey.shade200)
        : selected
            ? activeColor
            : (isDark ? Colors.white24 : Colors.grey.shade300);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
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
      child: Text(
        '$count becarios encontrados',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
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
    return InkWell(
      onTap: () => _mostrarDetalle(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1D1D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
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
                  if (item.esUsuarioActual) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tu perfil',
                      style: TextStyle(
                        color: AppColors.misRamos,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
      builder: (_) => BecarioDetailSheet(item: item),
    );
  }
}

class _BecariosData {
  final List<BecarioItem> items;
  final String rutPropio;
  final int propioGeneracion;
  final String? propioUniversidad;
  final String? propioLiceoNombre;

  _BecariosData({
    required this.items,
    required this.rutPropio,
    required this.propioGeneracion,
    this.propioUniversidad,
    this.propioLiceoNombre,
  });

  factory _BecariosData.empty() => _BecariosData(
        items: [],
        rutPropio: '',
        propioGeneracion: 0,
      );

  bool get puedeUniversidad => propioUniversidad != null;
  bool get puedeLiceo => propioLiceoNombre != null;
}
