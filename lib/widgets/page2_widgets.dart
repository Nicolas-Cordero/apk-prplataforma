import 'package:flutter/material.dart';

/// Widget para mostrar el encabezado de perfil (nombre, avatar y estado).
///
/// Si [fotoUrl] es no-nulo y no vacío intenta cargar la imagen de red.
/// Si la URL falla o el campo es nulo se muestra el avatar de iniciales.
class ProfileHeader extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String estado;
  final String? fotoUrl;

  const ProfileHeader({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.estado,
    this.fotoUrl,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _fotoError = false;

  @override
  void didUpdateWidget(ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoUrl != widget.fotoUrl) {
      setState(() => _fotoError = false);
    }
  }

  Widget _initiales() {
    final n = widget.nombre.isNotEmpty ? widget.nombre[0] : '';
    final a = widget.apellido.isNotEmpty ? widget.apellido[0] : '';
    final iniciales = (n + a).toUpperCase();
    return Center(
      child: Text(
        iniciales.isEmpty ? 'CG' : iniciales,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.nombre;
    final apellido = widget.apellido;
    final estado = widget.estado;

    final statusColor = estado.toLowerCase() == 'activo'
        ? const Color(0xFF16A085)
        : Colors.orange;
    final statusText =
        estado.toLowerCase() == 'activo' ? 'Beca Activa' : estado;

    final tieneFoto =
        widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty && !_fotoError;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF16A085).withValues(alpha: 0.8),
                const Color(0xFF16A085).withValues(alpha: 0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A085).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: tieneFoto
              ? ClipOval(
                  child: Image.network(
                    widget.fotoUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => setState(() => _fotoError = true));
                      return _initiales();
                    },
                  ),
                )
              : _initiales(),
        ),
        const SizedBox(height: 20),

        Text(
          '$nombre $apellido',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar títulos de secciones
class SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const SectionTitle({
    super.key,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color ?? const Color(0xFFE74C3C),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para tarjetas de información académica
class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color accentColor;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: backgroundColor,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: backgroundColor,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para datos personales con icono
class PersonalDataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const PersonalDataTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
