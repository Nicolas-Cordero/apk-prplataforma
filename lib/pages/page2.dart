import 'package:flutter/material.dart';
import 'package:test1/models/estudiante.dart';
import 'package:test1/services/estudiante_service.dart';
import 'package:test1/services/liceo_service.dart';
import 'package:test1/widgets/page2_widgets.dart';
import 'package:test1/constants/app_colors.dart';

/// Página del Perfil del Estudiante (Yo)
class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  late Future<_ProfileData> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _cargarDatosCompletos();
  }

  /// Carga datos del estudiante y el nombre del liceo
  Future<_ProfileData> _cargarDatosCompletos() async {
    final estudiante = await EstudianteService.obtenerEstudianteActual();
    final nombreLiceo = await LiceoService.obtenerNombre();
    return _ProfileData(estudiante, nombreLiceo);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<_ProfileData>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        // Estado de carga
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

        // Error
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

        final data = snapshot.data!;
        final estudiante = data.estudiante;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de perfil
                Center(
                  child: ProfileHeader(
                    nombre: estudiante.nombre,
                    apellido: estudiante.apellido,
                    estado: estudiante.estado,
                  ),
                ),
                const SizedBox(height: 32),

                // Tarjetas académicas principales
                _buildAcademicCards(estudiante),
                const SizedBox(height: 8),

                // Sección: Datos Personales
                SectionTitle(
                  title: 'Datos Personales',
                  color: AppColors.yo.withValues(alpha: 0.8),
                ),
                _buildPersonalDataSection(estudiante),

                // Sección: Datos Académicos
                SectionTitle(
                  title: 'Datos Académicos',
                  color: const Color(0xFFE67E22),
                ),
                _buildAcademicDataSection(estudiante, data.nombreLiceo),

                // Sección: Académico Detallado
                SectionTitle(
                  title: 'Desempeño Académico',
                  color: const Color(0xFF8E44AD),
                ),
                _buildPerformanceSection(estudiante),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye las tarjetas de información académica principal
  Widget _buildAcademicCards(Estudiante estudiante) {
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
          InfoCard(
            label: 'Prom. Media',
            value: estudiante.promedioGeneral.toStringAsFixed(1),
            backgroundColor: const Color(0xFF16A085),
            accentColor: const Color(0xFF16A085),
            icon: Icons.trending_up,
          ),
          InfoCard(
            label: 'PAES',
            value: estudiante.puntajePaes.toString(),
            backgroundColor: const Color(0xFFE74C3C),
            accentColor: const Color(0xFFE74C3C),
            icon: Icons.assessment,
          ),
          InfoCard(
            label: 'Generación',
            value: estudiante.generacion.toString(),
            backgroundColor: const Color(0xFFF39C12),
            accentColor: const Color(0xFFF39C12),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  /// Construye la sección de datos personales
  Widget _buildPersonalDataSection(Estudiante estudiante) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.yo.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          PersonalDataTile(
            icon: Icons.badge,
            label: 'RUT',
            value: estudiante.rutEstudiante,
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.email,
            label: 'Correo Electrónico',
            value: estudiante.email,
            iconColor: AppColors.yo,
          ),
          Divider(color: AppColors.yo.withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.phone,
            label: 'Teléfono',
            value: estudiante.telefono,
            iconColor: AppColors.yo,
          ),
        ],
      ),
    );
  }

  /// Construye la sección de datos académicos
  Widget _buildAcademicDataSection(
    Estudiante estudiante,
    String nombreLiceo,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE67E22).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          PersonalDataTile(
            icon: Icons.school,
            label: 'Liceo de Origen',
            value: nombreLiceo,
            iconColor: const Color(0xFFE67E22),
          ),
          Divider(color: const Color(0xFFE67E22).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.code,
            label: 'RBD Liceo',
            value: estudiante.rbdLiceo,
            iconColor: const Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de desempeño académico (promedios por materia)
  Widget _buildPerformanceSection(Estudiante estudiante) {
    final asignaturas = estudiante.promediosMedia.entries.toList();

    if (asignaturas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Text('No hay datos de desempeño disponibles'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8E44AD).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8E44AD).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(
          asignaturas.length,
          (index) {
            final entry = asignaturas[index];
            final nombreAsignatura =
                _capitalizarPrimera(entry.key); // "matemáticas" → "Matemáticas"
            final nota = entry.value;

            // Determinar color basado en la nota
            Color notaColor;
            if (nota >= 6.5) {
              notaColor = const Color(0xFF27AE60); // Verde
            } else if (nota >= 5.0) {
              notaColor = const Color(0xFFF39C12); // Naranja
            } else {
              notaColor = const Color(0xFFE74C3C); // Rojo
            }

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nombreAsignatura,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: notaColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        nota.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: notaColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < asignaturas.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: const Color(0xFF8E44AD).withValues(alpha: 0.2),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Capitaliza la primera letra de una cadena
  String _capitalizarPrimera(String texto) {
    return texto.substring(0, 1).toUpperCase() + texto.substring(1);
  }
}

/// Clase auxiliar para agrupar datos que se cargan de forma asíncrona
class _ProfileData {
  final Estudiante estudiante;
  final String nombreLiceo;

  _ProfileData(this.estudiante, this.nombreLiceo);
}
