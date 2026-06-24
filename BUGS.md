# Reporte de errores — apk-prplataforma

> Revisión previa al primer build del APK. Fecha: 2026-06-23.

---

## Resumen por prioridad

| # | Archivo | Severidad | Descripción |
|---|---------|-----------|-------------|
| 1 | `notification_service.dart:75` | ✅ RESUELTO | `Directory.systemTemp` inaccesible en Android/Web → migrado a `shared_preferences` |
| 2 | `api_service.dart:9` | 🔴 CRÍTICO | IP local hardcodeada como URL por defecto |
| 3 | `notification_service.dart:58` | 🔴 CRÍTICO | Sin request de permiso en Android 13+ |
| 4 | `page2_widgets.dart:38` | 🟠 ALTO | Crash por `RangeError` en iniciales con string vacío |
| 5 | `acuerdo_service.dart:34` | 🟠 ALTO | Cast sin null check en `fromJson` |
| 6 | `pubspec.yaml:69` | 🟡 MEDIO | SVGs no incluidos en el bundle del APK |
| 7 | `notification_service.dart:75` | ✅ RESUELTO | Path de prueba `/test1` — eliminado junto con el bug #1 |
| 8 | `mis_notas_page.dart:480` | 🟡 MEDIO | Nota mostrada con 2 decimales vs 1 decimal almacenado |
| 9 | `app.dart:17` | 🟡 MEDIO | Preferencia de dark mode no persiste entre reinicios |
| 10 | `notification_service.dart:106` | 🟡 MEDIO | Badge de notificaciones nunca se resetea a 0 |
| 11 | `AndroidManifest.xml:8` | 🟢 BAJO | `usesCleartextTraffic="true"` en build de producción |
| 12 | `app_background.dart:39` | 🟢 BAJO | Future creado dentro de `build()` (antipatrón FutureBuilder) |
| 13 | `assets/data/*.json` | 🟢 BAJO | Archivos JSON sin usar que inflan el APK |

---

## CRÍTICOS

### 1. `lib/services/notification_service.dart:75` — `Directory.systemTemp` no existe en Android ni en Web ✅ RESUELTO

`Directory.systemTemp` resuelve a `/tmp`, un path inaccesible en Android. En Web, `dart:io` directamente no existe como API y lanzaría `UnsupportedError`. Esto afecta a los tres clientes objetivo (Android, iOS, Web).

**Efecto en cadena:** en `mis_ramos_page.dart`, el ramo se guarda correctamente en el backend pero `NotificationService.agregar()` lanza excepción y el `catch` muestra "No se pudo guardar el ramo" — mensaje incorrecto que confunde al usuario.

**Solución aplicada:** reemplazar el almacenamiento basado en `dart:io` (`File`/`Directory`) por `shared_preferences`, que ya estaba en las dependencias y es compatible con **Android, iOS, Web, Linux, macOS y Windows** sin imports condicionales ni guards `kIsWeb`.

```dart
// ❌ ANTES — dart:io, no funciona en Android ni Web
import 'dart:io';
static const String _fileName = 'notifications.json';

static Future<File> _localFile() async {
  final dir = Directory('${Directory.systemTemp.path}/test1');
  if (!await dir.exists()) await dir.create(recursive: true);
  return File('${dir.path}/$_fileName');
}

// ✅ DESPUÉS — shared_preferences, compatible con todos los platforms
import 'package:shared_preferences/shared_preferences.dart';
static const String _prefsKey = 'app_notifications';

static Future<List<AppNotification>> _leerLista() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null || raw.trim().isEmpty) return [];
  final data = jsonDecode(raw) as List<dynamic>;
  return data.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
}

static Future<void> _guardarLista(List<AppNotification> items) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  _actualizarContadorConLista(items);
}
```

> **Nota:** `flutter_local_notifications` no soporta Web, por lo que `inicializar()`, `solicitarPermisos()` y `_mostrarNotificacionLocal()` conservan sus guards `if (kIsWeb) return`. Solo el almacenamiento cambia de backend.

---

### 2. `lib/services/api_service.dart:9` — IP local hardcodeada como URL por defecto

```dart
// ❌ ACTUAL
static const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.100.13:3001',
);
```

El APK de release usará la IP de la red local del desarrollador. Cualquier dispositivo fuera de esa red no puede conectarse. Adicionalmente, `android:usesCleartextTraffic="true"` en el manifest existe solo para soportar esta URL HTTP — en producción debería ser HTTPS y esta flag eliminarse.

**Fix:** definir la URL de producción correcta como `defaultValue`, o forzar su paso en el build:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.cl
```

---

### 3. `lib/services/notification_service.dart:58-72` — Android 13+ no solicita permiso en runtime

```dart
// ❌ ACTUAL — comentario incorrecto
static Future<void> solicitarPermisos() async {
  if (kIsWeb) return;
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  await ios?.requestPermissions(alert: true, badge: true, sound: true);
  // "Android 13+ maneja permisos automáticamente" ← INCORRECTO
}
```

Android 13+ (API 33+) requiere solicitar `POST_NOTIFICATIONS` explícitamente en runtime. El manifest lo declara, pero eso no es suficiente. Las notificaciones locales nunca aparecerán en Android 13+ sin este request.

```dart
// ✅ FIX
static Future<void> solicitarPermisos() async {
  if (kIsWeb) return;

  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  await ios?.requestPermissions(alert: true, badge: true, sound: true);

  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
}
```

---

## ALTOS

### 4. `lib/widgets/page2_widgets.dart:38` — `RangeError` si nombre o apellido está vacío

```dart
// ❌ ACTUAL — crash si cualquier string es ""
Widget _initiales() => Center(
  child: Text('${widget.nombre[0]}${widget.apellido[0]}'),
);
```

Si el backend devuelve un estudiante con `nombre: ""` o `apellido: ""` (posible con datos incompletos), el índice `[0]` lanza `RangeError: index out of bounds`. El `CustomAppBar` ya maneja este caso correctamente con un fallback `'CG'`, pero `ProfileHeader` no lo hace.

```dart
// ✅ FIX
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
```

---

### 5. `lib/services/acuerdo_service.dart:34-40` — Cast sin null check en `fromJson`

```dart
// ❌ ACTUAL — lanza TypeError si el backend devuelve algún campo null
factory DocumentoCompromiso.fromJson(Map<String, dynamic> json) =>
    DocumentoCompromiso(
      titulo:    json['titulo']    as String,       // throw si null
      subtitulo: json['subtitulo'] as String,       // throw si null
      abstract:  json['abstract']  as String,       // throw si null
      topicos: (json['topicos'] as List<dynamic>)   // throw si null
          .map((t) => Topico.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
```

Lo mismo ocurre en `Topico.fromJson:13` con `json['puntos']`. Si el backend devuelve cualquiera de estos campos como `null`, la página de Compromiso crashea con `TypeError` al intentar parsear la respuesta.

```dart
// ✅ FIX
factory DocumentoCompromiso.fromJson(Map<String, dynamic> json) =>
    DocumentoCompromiso(
      titulo:    json['titulo']    as String? ?? '',
      subtitulo: json['subtitulo'] as String? ?? '',
      abstract:  json['abstract']  as String? ?? '',
      topicos: (json['topicos'] as List<dynamic>? ?? [])
          .map((t) => Topico.fromJson(t as Map<String, dynamic>))
          .toList(),
    );

// Y en Topico.fromJson:
puntos: (json['puntos'] as List<dynamic>? ?? [])
    .map((p) => p as String)
    .toList(),
```

---

## MEDIOS

### 6. `pubspec.yaml:69` — Subdirectorio de SVGs no incluido en el bundle

```yaml
# ❌ ACTUAL — solo incluye archivos directamente en assets/data/
# NO incluye assets/data/graphics/
assets:
  - assets/data/
```

Los archivos `marco-izquierda.svg` y `marco-derecha.svg` no se empaquetan en el APK. El `AppBackground` los maneja silenciosamente (retorna `SizedBox.shrink()`) pero los marcos decorativos nunca se mostrarán.

```yaml
# ✅ FIX
assets:
  - assets/data/
  - assets/data/graphics/
```

---

### 7. `lib/services/notification_service.dart:75` — Path de prueba `/test1` en producción

```dart
// ❌ ACTUAL — nombre de directorio de testing
final dir = Directory('${Directory.systemTemp.path}/test1');
```

El nombre `test1` indica claramente que es un remanente de una sesión de desarrollo. Aunque el bug crítico #1 ya corrige este path, se documenta por separado.

---

### 8. `lib/pages/mis_notas_page.dart:480` — Inconsistencia de decimales en nota final

```dart
// En el card (mostrado al usuario):
'Nota final: ${ramo.notaFinal!.toStringAsFixed(2)}'  // 2 decimales → "5.75"

// En _editarNota al guardar:
final nota = double.parse(raw.toStringAsFixed(1));   // 1 decimal → backend guarda "5.8"
```

Una nota ingresada como `5.75` se muestra como `5.75` antes de guardar, pero el backend almacena `5.8`. Tras refrescar, el valor mostrado cambia a `5.80`. Confuso para el usuario.

**Fix:** usar `toStringAsFixed(1)` también en la visualización del card, o cambiar el backend para aceptar 2 decimales (y actualizar el comentario en `_editarNota`).

---

### 9. `lib/app.dart:17` — Dark mode no persiste entre reinicios

```dart
// ❌ ACTUAL — siempre arranca en light mode
bool _isDarkMode = false;
```

El toggle de tema solo vive en el estado del widget. Al cerrar y reabrir la app, siempre será light mode independientemente de la preferencia guardada.

**Fix:** leer y escribir la preferencia en `SharedPreferences` dentro de `_MyAppState`.

---

### 10. `lib/services/notification_service.dart:106` — Badge nunca se resetea al leer notificaciones

```dart
static void _actualizarContadorConLista(List<AppNotification> items) {
  contador.value = items.length;  // total de notificaciones, no "no leídas"
}
```

El badge de la campana muestra el total de notificaciones persistidas. El usuario ve siempre el mismo número aunque haya revisado todas. Solo disminuye si elimina notificaciones explícitamente.

**Opciones de fix:**
- Agregar un campo `leida` al modelo `AppNotification` y contar solo las no leídas.
- Resetear el contador a `0` cuando el usuario abre la página de notificaciones.

---

## BAJOS

### 11. `android/app/src/main/AndroidManifest.xml:8` — `usesCleartextTraffic` en producción

```xml
<application android:usesCleartextTraffic="true">
```

Permite tráfico HTTP en texto plano. Google Play advierte sobre esto y puede rechazar apps que lo usen sin justificación. Este flag existe únicamente por la URL HTTP hardcodeada (bug #2). Al migrar a HTTPS, debe eliminarse.

---

### 12. `lib/widgets/app_background.dart:39` — Future creado dentro de `build()` (antipatrón)

```dart
// ❌ ACTUAL — el future se re-crea en cada rebuild
future: _tryLoadAsset('assets/data/graphics/marco-izquierda.svg'),
```

Cada vez que el widget se reconstruye (scroll, cambio de tema, etc.), se dispara una nueva carga del asset. Debería moverse a `initState` de un `StatefulWidget`.

---

### 13. `assets/data/*.json` — Archivos sin usar que inflan el APK

Los siguientes archivos están en el bundle pero ningún archivo Dart los lee — son remanentes de una versión anterior que usaba datos locales:

- `assets/data/carreras.json`
- `assets/data/liceos.json`
- `assets/data/ramos.json`
- `assets/data/semestres.json`
- `assets/data/students.json`
- `assets/data/students_becarios.json`
- `assets/data/universidades.json`
- `assets/data/usuarios.json`

**Fix:** eliminar los archivos y remover `- assets/data/` del `pubspec.yaml` si solo se necesita `assets/data/graphics/`.

---

## Orden de corrección recomendado

1. **Bug #1** — Reemplazar `Directory.systemTemp` con `path_provider` (`getApplicationSupportDirectory`).
2. **Bug #2** — Definir la URL de producción correcta (HTTPS).
3. **Bug #3** — Agregar request de permiso para Android 13+.
4. **Bug #4** — Proteger `_initiales()` contra strings vacíos.
5. **Bug #5** — Agregar null-safety en `fromJson` de `acuerdo_service.dart`.
6. **Bug #6** — Agregar `assets/data/graphics/` al `pubspec.yaml`.
7. Resto de bugs medios y bajos según disponibilidad.
