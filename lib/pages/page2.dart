import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/models/estudiante.dart';
import 'package:carmen_goudie/services/carrera_service.dart';
import 'package:carmen_goudie/services/contacto_emergencia_service.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/services/liceo_service.dart';
import 'package:carmen_goudie/services/notification_service.dart';
import 'package:carmen_goudie/services/ramo_service.dart';
import 'package:carmen_goudie/services/promedio_final_service.dart';
import 'package:carmen_goudie/services/semestre_service.dart';
import 'package:carmen_goudie/services/universidad_service.dart';
import 'package:carmen_goudie/widgets/page2_widgets.dart';

/// Página del Perfil del Estudiante (Yo)
class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  late Future<_ProfileData> _profileDataFuture;
  final TextEditingController _nombreEmergenciaController =
      TextEditingController();
  final TextEditingController _relacionEmergenciaController =
      TextEditingController();
  final TextEditingController _telefonoEmergenciaController =
      TextEditingController();
  final TextEditingController _correoEmergenciaController =
      TextEditingController();
  bool _controllersReady = false;
  bool _guardandoContacto = false;
  String _nombreInicial = '';
  String _relacionInicial = '';
  String _telefonoInicial = '';
  String _correoInicial = '';
  bool _mostrarGuardar = false;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _cargarDatosCompletos();
    _nombreEmergenciaController.addListener(_onContactoChange);
    _relacionEmergenciaController.addListener(_onContactoChange);
    _telefonoEmergenciaController.addListener(_onContactoChange);
    _correoEmergenciaController.addListener(_onContactoChange);
  }

  @override
  void dispose() {
    _nombreEmergenciaController.dispose();
    _relacionEmergenciaController.dispose();
    _telefonoEmergenciaController.dispose();
    _correoEmergenciaController.dispose();
    super.dispose();
  }

  Future<_ProfileData> _cargarDatosCompletos() async {
    final estudiante = await EstudianteService.obtenerEstudianteActual();
    final liceo = await LiceoService.obtenerPorRbd(estudiante.rbdLiceo);
    final contacto = await ContactoEmergenciaService.obtenerPorRut(
      estudiante.rutEstudiante,
    );

    String comunaEstudio = 'No disponible';
    Carrera? carrera;
    String nombreUniversidad = 'No disponible';
    double? promedioSemestre;
    List<Ramo> ramosPuedoAyudar = [];

    try {
      carrera = await CarreraService.obtenerPorRut(estudiante.rutEstudiante);
      if (carrera != null) {
        final universidad = await UniversidadService.obtenerPorCodigo(
          carrera.codigoUniversidad,
        );
        if (universidad != null) {
          comunaEstudio = universidad.comuna;
          nombreUniversidad = universidad.nombre;
        }
      }

      final semestreActual = await SemestreService.obtenerSemestreActual();
      final ramos = await RamoService.leerRamosPorRut(estudiante.rutEstudiante);
      ramosPuedoAyudar = ramos
          .where((ramo) => ramo.puedoAyudar && ramo.semestreId != semestreActual.id)
          .toList();
      final promedios = await PromedioFinalService.leerPromedios();
      final promediosDelSemestre = promedios
          .where((promedio) => promedio.semestreId == semestreActual.id)
          .toList();

      if (promediosDelSemestre.isNotEmpty) {
        final suma = promediosDelSemestre.fold<double>(
          0,
          (acumulado, promedio) => acumulado + promedio.promedioFinal,
        );
        promedioSemestre = suma / promediosDelSemestre.length;
      }
    } catch (_) {
      // Mantiene valores por defecto si falla alguna consulta.
    }

    return _ProfileData(
      estudiante,
      liceo,
      contacto,
      comunaEstudio,
      carrera,
      nombreUniversidad,
      promedioSemestre,
      ramosPuedoAyudar,
    );
  }

  void _inicializarContactos(ContactoEmergencia? contacto) {
    if (_controllersReady) return;
    _nombreInicial = (contacto?.nombre ?? '').trim();
    _relacionInicial = (contacto?.relacion ?? '').trim();
    _telefonoInicial = _normalizarTelefono(contacto?.telefono ?? '');
    _correoInicial = (contacto?.correo ?? '').trim();

    _nombreEmergenciaController.text = _nombreInicial;
    _relacionEmergenciaController.text = _relacionInicial;
    _telefonoEmergenciaController.text = _formatearTelefono(_telefonoInicial);
    _correoEmergenciaController.text = _correoInicial;
    _controllersReady = true;
    _evaluarCambios();
  }

  void _onContactoChange() {
    if (!_controllersReady) return;
    _evaluarCambios();
  }

  void _evaluarCambios() {
    final nombreActual = _nombreEmergenciaController.text.trim();
    final relacionActual = _relacionEmergenciaController.text.trim();
    final telefonoActual = _normalizarTelefono(_telefonoEmergenciaController.text);
    final correoActual = _correoEmergenciaController.text.trim();
    final hayCambios =
        nombreActual != _nombreInicial ||
        relacionActual != _relacionInicial ||
        telefonoActual != _telefonoInicial ||
        correoActual != _correoInicial;

    if (hayCambios != _mostrarGuardar) {
      setState(() {
        _mostrarGuardar = hayCambios;
      });
    }
  }

  String _formatearTelefono(String telefono) {
    final limpio = telefono.replaceAll(RegExp(r'\s+'), '');
    if (limpio.isEmpty) return '';
    if (limpio.startsWith('+') && limpio.length > 4) {
      return '${limpio.substring(0, 4)} ${limpio.substring(4)}';
    }
    return limpio;
  }

  String _normalizarTelefono(String telefono) {
    return telefono.replaceAll(RegExp(r'\s+'), '');
  }

  Future<void> _guardarContacto(String rutEstudiante) async {
    if (_guardandoContacto) return;
    setState(() {
      _guardandoContacto = true;
    });

    try {
      final teniaTelefono = _telefonoInicial.isNotEmpty;
      final teniaCorreo = _correoInicial.isNotEmpty;

      final nombre = _nombreEmergenciaController.text.trim();
      final relacion = _relacionEmergenciaController.text.trim();
      final telefono = _formatearTelefono(
        _normalizarTelefono(_telefonoEmergenciaController.text),
      );
      final correo = _correoEmergenciaController.text.trim();

      final telefonoNormalizado = _normalizarTelefono(telefono);
      final correoNormalizado = correo.trim();
      final ahoraTieneTelefono = telefonoNormalizado.isNotEmpty;
      final ahoraTieneCorreo = correoNormalizado.isNotEmpty;

      _telefonoEmergenciaController.text = telefono;
      _correoEmergenciaController.text = correo;

      await ContactoEmergenciaService.guardar(
        rutEstudiante: rutEstudiante,
        nombre: nombre,
        relacion: relacion,
        telefono: telefono,
        correo: correo,
      );

      if (ahoraTieneTelefono || ahoraTieneCorreo) {
        await NotificationService.eliminarPorCodigo(
          'missing_emergency_contacts',
        );
      }

      if (!teniaTelefono && !teniaCorreo && ahoraTieneTelefono && ahoraTieneCorreo) {
        await NotificationService.agregarSiNoExiste(
          code: 'emergency_contacts_created',
          title: 'Contactos de emergencia',
          body: 'Has registrado tus contactos de emergencia',
          type: 'success',
          iconKey: 'emergency_contacts',
        );
      } else {
        final cambioTelefono = telefonoNormalizado != _telefonoInicial;
        final cambioCorreo = correoNormalizado != _correoInicial;
        if (cambioTelefono || cambioCorreo) {
          await NotificationService.agregar(
            title: 'Contactos de emergencia',
            body: 'Has actualizado tus contactos de emergencia',
            type: 'info',
            iconKey: 'emergency_contacts',
          );
        }
      }

      _nombreInicial = nombre;
      _relacionInicial = relacion;
      _telefonoInicial = telefonoNormalizado;
      _correoInicial = correoNormalizado;
      _mostrarGuardar = false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contactos de emergencia guardados')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardandoContacto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<_ProfileData>(
      future: _profileDataFuture,
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

        final data = snapshot.data!;
        final estudiante = data.estudiante;
        _inicializarContactos(data.contacto);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ProfileHeader(
                    nombre: estudiante.nombre,
                    apellido: estudiante.apellido,
                    estado: estudiante.estado,
                  ),
                ),
                const SizedBox(height: 32),
                _buildAcademicCards(
                  estudiante,
                  data.comunaEstudio,
                  data.promedioSemestre,
                ),
                const SizedBox(height: 8),
                SectionTitle(
                  title: 'Datos Personales',
                  color: AppColors.yo.withValues(alpha: 0.8),
                ),
                _buildPersonalDataSection(estudiante),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Contactos de emergencia',
                  color: AppColors.misNotas.withValues(alpha: 0.85),
                ),
                _buildEmergencyContactsSection(estudiante),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Datos Carrera',
                  color: const Color(0xFF27AE60).withValues(alpha: 0.8),
                ),
                _buildCarreraDataSection(data.carrera, data.nombreUniversidad),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Establecimiento de origen',
                  color: const Color(0xFFE67E22),
                ),
                _buildEstablecimientoSection(data.liceo),
                const SizedBox(height: 16),
                SectionTitle(
                  title: 'Puedo ayudar',
                  color: AppColors.misRamos.withValues(alpha: 0.85),
                ),
                _buildPuedoAyudarSection(data.ramosPuedoAyudar),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicCards(
    Estudiante estudiante,
    String comunaEstudio,
    double? promedioSemestre,
  ) {
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
            label: 'Prom. Semestre',
            value: promedioSemestre != null
                ? promedioSemestre.toStringAsFixed(1)
                : '-',
            backgroundColor: const Color(0xFF16A085),
            accentColor: const Color(0xFF16A085),
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
            value: estudiante.generacion.toString(),
            backgroundColor: const Color(0xFFF39C12),
            accentColor: const Color(0xFFF39C12),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildCarreraDataSection(Carrera? carrera, String nombreUniversidad) {
    final nombreCarrera = carrera?.nombre ?? 'No disponible';
    final semestres = carrera?.duracionSemestres.toString() ?? 'No disponible';
    final codigoCarrera = carrera?.codigoCarrera ?? 'No disponible';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27AE60).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
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
                      nombreCarrera,
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
          const SizedBox(height: 12),
          PersonalDataTile(
            icon: Icons.schedule,
            label: 'Semestres',
            value: semestres,
            iconColor: const Color(0xFF27AE60),
          ),
          Divider(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.school,
            label: 'Universidad',
            value: nombreUniversidad,
            iconColor: const Color(0xFF27AE60),
          ),
          Divider(color: const Color(0xFF27AE60).withValues(alpha: 0.2)),
          PersonalDataTile(
            icon: Icons.code,
            label: 'Código Carrera',
            value: codigoCarrera,
            iconColor: const Color(0xFF27AE60),
          ),
        ],
      ),
    );
  }

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
            value: _formatearTelefono(estudiante.telefono),
            iconColor: AppColors.yo,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection(Estudiante estudiante) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.misNotas.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.misNotas.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          EditableDataField(
            icon: Icons.person,
            label: 'Nombre del contacto',
            hintText: 'Ingresar',
            iconColor: AppColors.misNotas,
            controller: _nombreEmergenciaController,
            keyboardType: TextInputType.text,
          ),
          Divider(color: AppColors.misNotas.withValues(alpha: 0.2)),
          EditableDataField(
            icon: Icons.family_restroom,
            label: 'Relación',
            hintText: 'Ejemplo: Madre/Abuelo',
            iconColor: AppColors.misNotas,
            controller: _relacionEmergenciaController,
            keyboardType: TextInputType.text,
          ),
          Divider(color: AppColors.misNotas.withValues(alpha: 0.2)),
          EditableDataField(
            icon: Icons.phone_in_talk,
            label: 'Teléfono de emergencia',
            hintText: 'Ingresar',
            iconColor: AppColors.misNotas,
            controller: _telefonoEmergenciaController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
          ),
          Divider(color: AppColors.misNotas.withValues(alpha: 0.2)),
          EditableDataField(
            icon: Icons.alternate_email,
            label: 'Correo de emergencia',
            hintText: 'Ingresar',
            iconColor: AppColors.misNotas,
            controller: _correoEmergenciaController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _mostrarGuardar
                ? Align(
                    key: const ValueKey('guardar'),
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _guardandoContacto
                          ? null
                          : () => _guardarContacto(estudiante.rutEstudiante),
                      icon: _guardandoContacto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_guardandoContacto ? 'Guardando' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.misNotas,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('oculto')),
          ),
        ],
      ),
    );
  }

  Widget _buildEstablecimientoSection(Liceo? liceo) {
    final nombreLiceo = liceo?.nombre ?? 'No disponible';
    final comuna = liceo?.comuna ?? 'No disponible';
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
            icon: Icons.location_on,
            label: 'Comuna',
            value: comuna,
            iconColor: const Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }

  Widget _buildPuedoAyudarSection(List<Ramo> ramos) {
    if (ramos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.misRamos.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.misRamos.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          'Todavía no has activado ramos para ayudar',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: ramos.map((ramo) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.misRamos.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.misRamos.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.misRamos.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: Color(0xFF57B6A7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ramo.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Intento ${ramo.intento} · ${ramo.semestreId.replaceFirst('SEM-', '')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ProfileData {
  final Estudiante estudiante;
  final Liceo? liceo;
  final ContactoEmergencia? contacto;
  final String comunaEstudio;
  final Carrera? carrera;
  final String nombreUniversidad;
  final double? promedioSemestre;
  final List<Ramo> ramosPuedoAyudar;

  _ProfileData(
    this.estudiante,
    this.liceo,
    this.contacto,
    this.comunaEstudio,
    this.carrera,
    this.nombreUniversidad,
    this.promedioSemestre,
    this.ramosPuedoAyudar,
  );
}