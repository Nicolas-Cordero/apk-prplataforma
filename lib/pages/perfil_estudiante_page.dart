import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/models/estudiante.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/widgets/page2_widgets.dart';

/// Página de perfil del estudiante — solo lectura.
/// Todos los datos provienen de GET /estudiante/me (relaciones incluidas).
class PerfilEstudiantePage extends StatefulWidget {
  const PerfilEstudiantePage({super.key});

  @override
  State<PerfilEstudiantePage> createState() => _PerfilEstudiantePageState();
}

class _PerfilEstudiantePageState extends State<PerfilEstudiantePage> {
  late Future<Estudiante> _estudianteFuture;

  /// Índice de la carrera seleccionada cuando el estudiante tiene más de una.
  int _carreraIndex = 0;

  @override
  void initState() {
    super.initState();
    _estudianteFuture = EstudianteService.obtenerPerfilPropio();
  }

  String _formatearTelefono(String telefono) {
    final limpio = telefono.replaceAll(RegExp(r'\s+'), '');
    if (limpio.isEmpty) return 'No disponible';
    if (limpio.startsWith('+') && limpio.length > 4) {
      return '${limpio.substring(0, 4)} ${limpio.substring(4)}';
    }
    return limpio;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Estudiante>(
      future: _estudianteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.yo.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando perfil...',
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
                  size: 64,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el perfil',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        final est = snapshot.data!;
        final idxCarrera = est.carreras.isEmpty
            ? 0
            : _carreraIndex.clamp(0, est.carreras.length - 1);
        final carreraActual =
            est.carreras.isNotEmpty ? est.carreras[idxCarrera] : null;
        final comunaEstudio =
            carreraActual?.universidad?.comuna ?? 'No disponible';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ProfileHeader(
                    nombre: est.nombre,
                    apellido: est.apellido,
                    estado: est.estado,
                    fotoUrl: est.fotoUrl,
                  ),
                ),
                const SizedBox(height: 32),
                _buildAcademicCards(est, comunaEstudio),
                const SizedBox(height: 8),
                SectionTitle(
                  title: 'Datos Personales',
                  color: AppColors.yo.withValues(alpha: 0.8),
                ),
                _buildPersonalDataSection(est),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Contacto de emergencia',
                  color: AppColors.misNotas.withValues(alpha: 0.85),
                ),
                _buildEmergencyContactsSection(est),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Datos Carrera',
                  color: const Color(0xFF27AE60).withValues(alpha: 0.8),
                ),
                _buildCarreraDataSection(est),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Establecimiento de origen',
                  color: const Color(0xFFE67E22),
                ),
                _buildEstablecimientoSection(est),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicCards(Estudiante est, String comunaEstudio) {
    final generacion = est.generacionRel?.anio.toString() ??
        est.generacionId.toString();

    return SizedBox(
      height: 110,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          const InfoCard(
            label: 'Prom. Semestre',
            value: '-',
            backgroundColor: Color(0xFF16A085),
            accentColor: Color(0xFF16A085),
            icon: Icons.trending_up,
          ),
          InfoCard(
            label: 'Comuna Estudio',
            value: comunaEstudio,
            backgroundColor: const Color(0xFFE74C3C),
            accentColor: const Color(0xFFE74C3C),
            icon: Icons.location_city,
          ),
          InfoCard(
            label: 'Generación',
            value: generacion,
            backgroundColor: const Color(0xFFF39C12),
            accentColor: const Color(0xFFF39C12),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection(Estudiante est) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.yo.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          PersonalDataTile(
            icon: Icons.badge,
            label: 'RUT',
            value: est.rutEstudiante,
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.email,
            label: 'Correo Electrónico',
            value: est.email,
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.phone,
            label: 'Teléfono',
            value: _formatearTelefono(est.telefono),
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.home,
            label: 'Dirección',
            value: est.direccion.isNotEmpty ? est.direccion : 'No disponible',
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.person_outline,
            label: 'Género',
            value: est.genero.isNotEmpty ? est.genero : 'No disponible',
            iconColor: AppColors.yo,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection(Estudiante est) {
    final contacto = est.contactoEmergencia;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.misNotas.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.misNotas.withValues(alpha: 0.2)),
      ),
      child: contacto == null
          ? Text(
              'Sin contacto de emergencia registrado',
              style: TextStyle(color: Colors.grey[600]),
            )
          : Column(
              children: [
                PersonalDataTile(
                  icon: Icons.person,
                  label: 'Nombre',
                  value: contacto.nombre,
                  iconColor: AppColors.misNotas,
                ),
                Divider(color: AppColors.misNotas.withValues(alpha: 0.2)),
                PersonalDataTile(
                  icon: Icons.family_restroom,
                  label: 'Parentesco',
                  value: contacto.parentesco,
                  iconColor: AppColors.misNotas,
                ),
                Divider(color: AppColors.misNotas.withValues(alpha: 0.2)),
                PersonalDataTile(
                  icon: Icons.phone_in_talk,
                  label: 'Teléfono de emergencia',
                  value: _formatearTelefono(contacto.telefono),
                  iconColor: AppColors.misNotas,
                ),
              ],
            ),
    );
  }

  Widget _buildCarreraDataSection(Estudiante est) {
    if (est.carreras.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF27AE60).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
        ),
        child: Text(
          'Sin carrera registrada',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final idx = _carreraIndex.clamp(0, est.carreras.length - 1);
    final carrera = est.carreras[idx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Si hay más de una carrera se muestra un dropdown selector.
          if (est.carreras.length > 1)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Color(0xFF27AE60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: idx,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      items: List.generate(
                        est.carreras.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            est.carreras[i].nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      onChanged: (i) {
                        if (i != null) setState(() => _carreraIndex = i);
                      },
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Color(0xFF27AE60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carrera',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        carrera.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
          const SizedBox(height: 4),
          PersonalDataTile(
            icon: Icons.schedule,
            label: 'Semestres',
            value: carrera.duracionSem > 0
                ? carrera.duracionSem.toString()
                : 'No disponible',
            iconColor: const Color(0xFF27AE60),
          ),
          Divider(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.school,
            label: 'Universidad',
            value: carrera.universidad?.nombre ?? 'No disponible',
            iconColor: const Color(0xFF27AE60),
          ),
          Divider(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.location_city,
            label: 'Comuna de estudio',
            value: carrera.universidad?.comuna ?? 'No disponible',
            iconColor: const Color(0xFF27AE60),
          ),
        ],
      ),
    );
  }

  Widget _buildEstablecimientoSection(Estudiante est) {
    final liceo = est.liceo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFE67E22).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          PersonalDataTile(
            icon: Icons.school,
            label: 'Liceo de Origen',
            value: liceo?.nombre ?? 'No disponible',
            iconColor: const Color(0xFFE67E22),
          ),
          Divider(color: const Color(0xFFE67E22).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.location_on,
            label: 'Comuna',
            value: liceo?.comuna ?? 'No disponible',
            iconColor: const Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }
}
