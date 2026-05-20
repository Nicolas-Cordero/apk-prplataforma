import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test1/constants/app_colors.dart';
import 'package:test1/models/app_notification.dart';

/// Servicio para gestionar notificaciones locales
class NotificationService {
  static const String _fileName = 'notifications.json';
  static const String _channelId = 'general_notifications';
  static const String _channelName = 'Notificaciones';
  static const String _channelDescription = 'Notificaciones de la aplicacion';

  static const int _colorInfo = 0xFF2C3E50;
  static const int _colorWarning = 0xFFE67E22;
  static const int _colorSuccess = 0xFF16A085;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final ValueNotifier<int> contador = ValueNotifier<int>(0);

  static Future<void> inicializar() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Callback para notificaciones en foreground en iOS
    // Las notificaciones se mostrarán según DarwinNotificationDetails
  }

  static Future<void> solicitarPermisos() async {
    if (kIsWeb) return;

    // Solicitar permisos en iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+ maneja permisos automáticamente
  }

  static Future<File> _localFile() async {
    final dir = Directory('${Directory.systemTemp.path}/test1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  static Future<List<AppNotification>> _leerLista() async {
    final file = await _localFile();
    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    final data = jsonDecode(content) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  static Future<void> _guardarLista(List<AppNotification> items) async {
    final file = await _localFile();
    final data = items.map((item) => item.toJson()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    _actualizarContadorConLista(items);
  }

  static void _actualizarContadorConLista(List<AppNotification> items) {
    contador.value = items.length;
  }

  static Future<void> refrescarContador() async {
    final items = await _leerLista();
    _actualizarContadorConLista(items);
  }

  static int _colorPorIconKey(String? iconKey) {
    // Retorna el color de la navbar de la página origen
    switch (iconKey) {
      case 'emergency_contacts':
        return AppColors.yo.value;
      case 'mis_ramos':
        return AppColors.misRamos.value;
      case 'mis_notas':
        return AppColors.misNotas.value;
      case 'becarios':
        return AppColors.becarios.value;
      case 'compromiso':
        return AppColors.compromiso.value;
      default:
        return _colorInfo;
    }
  }

  static int _resolverColor(String type, int? accentColor, String? iconKey) {
    if (accentColor != null) return accentColor;
    if (iconKey != null) return _colorPorIconKey(iconKey);
    switch (type) {
      case 'warning':
        return _colorWarning;
      case 'success':
        return _colorSuccess;
      default:
        return _colorInfo;
    }
  }

  static Future<void> _mostrarNotificacionLocal(AppNotification item) async {
    if (!_initialized || kIsWeb) return;

    try {
      final colorValue = _resolverColor(item.type, item.accentColor, item.iconKey);
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(colorValue),
        icon: '@mipmap/ic_launcher',
      );
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = item.id.hashCode & 0x7fffffff;
      await _plugin.show(id, item.title, item.body, details);
    } catch (_) {
      // Evitar que fallos de plugin afecten el flujo principal
    }
  }

  /// Obtiene todas las notificaciones (más recientes primero)
  static Future<List<AppNotification>> obtenerTodas() async {
    final items = await _leerLista();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _actualizarContadorConLista(items);
    return items;
  }

  /// Agrega una notificación con color automático basado en iconKey si no se especifica accentColor
  static Future<void> agregar({
    required String title,
    required String body,
    String type = 'info',
    String? code,
    String? iconKey,
    int? accentColor,
  }) async {
    // Si no hay accentColor pero hay iconKey, calcular automáticamente
    final finalAccentColor = accentColor ?? (iconKey != null ? _colorPorIconKey(iconKey) : null);
    final items = await _leerLista();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final notification = AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now().toIso8601String(),
      code: code,
      iconKey: iconKey,
      accentColor: finalAccentColor,
    );
    items.add(notification);
    await _guardarLista(items);
    await _mostrarNotificacionLocal(notification);
  }

  /// Agrega una notificación si no existe por codigo (color automático basado en iconKey)
  static Future<void> agregarSiNoExiste({
    required String code,
    required String title,
    required String body,
    String type = 'info',
    String? iconKey,
    int? accentColor,
  }) async {
    // Si no hay accentColor pero hay iconKey, calcular automáticamente
    final finalAccentColor = accentColor ?? (iconKey != null ? _colorPorIconKey(iconKey) : null);
    final items = await _leerLista();
    final existe = items.any((item) => item.code == code);
    if (existe) return;
    final notification = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now().toIso8601String(),
      code: code,
      iconKey: iconKey,
      accentColor: finalAccentColor,
    );
    items.add(notification);
    await _guardarLista(items);
    await _mostrarNotificacionLocal(notification);
  }

  /// Elimina una notificación por id
  static Future<void> eliminar(String id) async {
    final items = await _leerLista();
    items.removeWhere((item) => item.id == id);
    await _guardarLista(items);
  }

  /// Elimina una notificación por codigo
  static Future<void> eliminarPorCodigo(String code) async {
    final items = await _leerLista();
    items.removeWhere((item) => item.code == code);
    await _guardarLista(items);
  }
}
