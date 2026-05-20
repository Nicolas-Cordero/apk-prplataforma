import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test1/models/estudiante.dart';
import 'package:test1/services/contacto_emergencia_service.dart';
import 'package:test1/services/estudiante_service.dart';
import 'package:test1/services/liceo_service.dart';
import 'package:test1/services/notification_service.dart';
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
  final TextEditingController _telefonoEmergenciaController =
      TextEditingController();
  final TextEditingController _correoEmergenciaController =
      TextEditingController();
  bool _controllersReady = false;
  bool _guardandoContacto = false;
    String _telefonoInicial = '';
    String _correoInicial = '';
    bool _mostrarGuardar = false;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _cargarDatosCompletos();
    _telefonoEmergenciaController.addListener(_onContactoChange);
    _correoEmergenciaController.addListener(_onContactoChange);
  }

  @override
  void dispose() {
    _telefonoEmergenciaController.dispose();
    _correoEmergenciaController.dispose();
    super.dispose();
  }

  /// Carga datos del estudiante y el nombre del liceo
  Future<_ProfileData> _cargarDatosCompletos() async {
    final estudiante = await EstudianteService.obtenerEstudianteActual();
    final liceo = await LiceoService.obtenerPorRbd(estudiante.rbdLiceo);
    final contacto = await ContactoEmergenciaService.obtenerPorRut(
      estudiante.rutEstudiante,
    );
    return _ProfileData(estudiante, liceo, contacto);
  }

  void _inicializarContactos(ContactoEmergencia? contacto) {
    if (_controllersReady) return;
    _telefonoInicial = _normalizarTelefono(contacto?.telefono ?? '');
    _correoInicial = (contacto?.correo ?? '').trim();

    _telefonoEmergenciaController.text =
        _formatearTelefono(_telefonoInicial);
    _correoEmergenciaController.text = _correoInicial;
    _controllersReady = true;
    _evaluarCambios();
  }

  void _onContactoChange() {
    if (!_controllersReady) return;
    _evaluarCambios();
  }

  void _evaluarCambios() {
    final telefonoActual =
        _normalizarTelefono(_telefonoEmergenciaController.text);
    final correoActual = _correoEmergenciaController.text.trim();
    final hayCambios =
        telefonoActual != _telefonoInicial || correoActual != _correoInicial;

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
        _inicializarContactos(data.contacto);

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

                // Sección: Contactos de emergencia
                SectionTitle(
                  title: 'Contactos de emergencia',
                  color: AppColors.misNotas.withValues(alpha: 0.85),
                ),
                _buildEmergencyContactsSection(estudiante),

                // Sección: Establecimiento de origen
                SectionTitle(
                  title: 'Establecimiento de origen',
                  color: const Color(0xFFE67E22),
                ),
                _buildEstablecimientoSection(data.liceo),

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
            value: _formatearTelefono(estudiante.telefono),
            iconColor: AppColors.yo,
          ),
        ],
      ),
    );
  }

  /// Construye la sección de contactos de emergencia
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

  /// Construye la sección de establecimiento de origen
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
}

/// Clase auxiliar para agrupar datos que se cargan de forma asíncrona
class _ProfileData {
  final Estudiante estudiante;
  final Liceo? liceo;
  final ContactoEmergencia? contacto;

  _ProfileData(this.estudiante, this.liceo, this.contacto);
}
