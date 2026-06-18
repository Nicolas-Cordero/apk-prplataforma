import 'package:flutter/material.dart';
import 'package:carmen_goudie/models/app_notification.dart';
import 'package:carmen_goudie/services/notification_service.dart';
import 'package:carmen_goudie/widgets/app_background.dart';

/// Página de notificaciones
class Page5 extends StatefulWidget {
  const Page5({super.key});

  @override
  State<Page5> createState() => _Page5State();
}

class _Page5State extends State<Page5> {
  late Future<List<AppNotification>> _notificacionesFuture;

  @override
  void initState() {
    super.initState();
    _notificacionesFuture = NotificationService.obtenerTodas();
  }

  Future<void> _recargar() async {
    setState(() {
      _notificacionesFuture = NotificationService.obtenerTodas();
    });
  }

  Future<void> _eliminar(String id) async {
    await NotificationService.eliminar(id);
    await _recargar();
  }

  IconData _iconoPorTipo(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  IconData _iconoPorNotificacion(AppNotification item) {
    switch (item.iconKey) {
      case 'emergency_contacts':
        return Icons.phone_in_talk;
      case 'mis_ramos':
        return Icons.book;
      case 'mis_notas':
        return Icons.assignment;
      case 'yo':
        return Icons.person;
      case 'becarios':
        return Icons.group;
      case 'compromiso':
        return Icons.description;
      default:
        return _iconoPorTipo(item.type);
    }
  }

  Color _colorPorTipo(String type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFE67E22);
      case 'success':
        return const Color(0xFF16A085);
      default:
        return const Color(0xFF2C3E50);
    }
  }

  Color _colorPorNotificacion(AppNotification item) {
    final accent = item.accentColor;
    if (accent != null) return Color(accent);
    return _colorPorTipo(item.type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar notificaciones',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No tienes notificaciones',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = _colorPorNotificacion(item);
              final icon = _iconoPorNotificacion(item);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                      onPressed: () => _eliminar(item.id),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Wrapper para mostrar Page5 dentro de `AppBackground` cuando se navega desde la barra superior
class Page5Wrapper extends StatelessWidget {
  const Page5Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: const Page5());
  }
}
