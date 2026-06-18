# Roadmap — Integración frontend con backend

> **Principio rector:** la app se adapta al backend, no al revés.
> Los modelos, campos, tipos y lógica de negocio se rigen por lo que expone la API.
> Solo se modificará el backend cuando falte un endpoint que el estudiante necesita
> para visualizar información propia (casos marcados con 🔧 Backend).

---

## Fase 1 — Infraestructura base
*Prereq de todo lo demás. Sin esto no hay llamadas HTTP ni sesión persistente.*

### 1.1 Agregar dependencias al `pubspec.yaml`
**Archivos:** `pubspec.yaml`

Agregar:
- `dio` — cliente HTTP con interceptores (manejo de token automático)
- `shared_preferences` — almacenar `accessToken` y `refreshToken`
- `path_provider` — rutas de almacenamiento persistente en el dispositivo

### 1.2 Corregir rutas de almacenamiento local
**Archivos:** `lib/services/notification_service.dart`, `ramo_service.dart`, `promedio_final_service.dart`, `contacto_emergencia_service.dart`

Reemplazar `Directory.systemTemp` por `getApplicationDocumentsDirectory()` de `path_provider`.
`systemTemp` puede ser borrado por el SO en cualquier momento; los documentos de la app no.

### 1.3 Crear `ApiService` — cliente HTTP base
**Archivos:** `lib/services/api_service.dart` (nuevo)

Clase con:
- URL base configurable (`const String baseUrl = 'http://...'`)
- Instancia de `Dio` con interceptor que adjunta `Authorization: Bearer <accessToken>` en cada request
- Lógica de refresh: si el servidor devuelve 401, intentar `POST /auth/refresh` con el `refreshToken` guardado, actualizar tokens y reintentar la request original
- Si el refresh también falla → redirigir al login

---

## Fase 2 — Autenticación
*La app actualmente no tiene pantalla de login. Arranca directamente en `HomePage`.*

### 2.1 Actualizar modelo `Usuario`
**Archivos:** `lib/models/usuario.dart`

El backend devuelve desde `POST /auth/login`:
```
rut_usuario, nombre, apellido, email, telefono, rol, activo, must_change_password,
accessToken, refreshToken
```

Cambios en el modelo:
- `rut` → `rut_usuario`
- Eliminar campo `contrasena` (nunca viene del backend)
- Agregar `activo` (bool)
- Agregar `must_change_password` (bool)

### 2.2 Crear pantalla de Login
**Archivos:** `lib/pages/login_page.dart` (nuevo), `lib/main.dart`

- Campos: **email** + **contraseña** (no RUT — el backend usa email)
- Al hacer login exitoso: guardar `accessToken` y `refreshToken` con `shared_preferences`
- Si `must_change_password == true`: mostrar pantalla/modal para cambiar contraseña antes de continuar
- `main.dart`: al iniciar la app, verificar si hay token guardado → ir a `HomePage` o `LoginPage`

### 2.3 Migrar `UsuarioService` a la API
**Archivos:** `lib/services/usuario_service.dart`

- `autenticar(email, password)` → `POST /auth/login` con `{ email, password }`
- `obtenerActual()` → `GET /auth/me`
- `cerrarSesion()` → `POST /auth/logout` + limpiar tokens de `shared_preferences`
- Eliminar toda la lógica de carga desde JSON local

---

## Fase 3 — Perfil del estudiante
*Depende de Fase 2 (necesita token para las requests).*

### 3.1 Actualizar modelo `Estudiante`
**Archivos:** `lib/models/estudiante.dart`

El backend devuelve desde `GET /estudiante/me`:
```
rut_estudiante, nombre, apellido, email, telefono, generacion_id, fecha_nacimiento,
direccion, genero, rbd_liceo, puntaje_paes, foto_url, promedios_media (double), estado
```

Cambios críticos:
- `promediosMedia` (Map<String, double>) → `promedios_media` (double — es un único número, el promedio de enseñanza media)
- `generacion` (int) → `generacion_id` (int, foreign key a la tabla de generaciones)
- `puntajePaes` → `puntaje_paes` (snake_case consistente con el backend)
- Agregar `fecha_nacimiento`, `direccion`, `genero`, `foto_url`
- `estado` → corresponde al enum `EstadoEstudiante` del backend
- Eliminar `promedioGeneral` (ya no es un Map — la propiedad no tiene sentido)

Impacto en la UI: `Page2` muestra el promedio de enseñanza media como número directo, no calculado desde un mapa.

### 3.2 Migrar `EstudianteService` a la API
**Archivos:** `lib/services/estudiante_service.dart`

- `obtenerEstudianteActual()` → `GET /estudiante/me`
- Eliminar carga desde JSON local

### 3.3 Actualizar modelo `Semestre`
**Archivos:** `lib/services/semestre_service.dart` (el modelo vive ahí)

El backend devuelve desde `GET /semestre`:
```json
[{ "semestre_id": 1, "year": 2025, "semestre": "SEGUNDO_SEMESTRE", "tipo": "REGULAR" }]
```

Cambios en el modelo:
- `id` (String 'SEM-XXXX') → `semestre_id` (int)
- `anio` → `year` (int)
- `nombreSemestre` → `semestre` (String: `'PRIMER_SEMESTRE'`, `'SEGUNDO_SEMESTRE'`, `'INVIERNO'`, `'VERANO'`)
- Agregar `tipo` (String)
- Eliminar `esActual` y `nombre` — el semestre "actual" se determina seleccionando el de mayor `year` + `semestre`
- Agregar getter `label` para mostrar en la UI (ej: `'2025 - Segundo Semestre'`)

Eliminar los semestres hardcodeados; reemplazar por `GET /semestre`.

### 3.4 Actualizar modelo `Carrera`
**Archivos:** `lib/services/carrera_service.dart`

El backend devuelve desde `GET /carrera/estudiante/:rut`:
```json
[{ "codigo_carrera": 1, "nombre": "...", "rut_estudiante": "...", "duracion_sem": 10,
   "codigo_universidad": 1, "via_acceso": "PAES" }]
```

Cambios en el modelo:
- `codigoCarrera` (String) → `codigo_carrera` (int)
- `codigoUniversidad` (String) → `codigo_universidad` (int)
- `duracionSemestres` → `duracion_sem`
- `viaAcceso` → `via_acceso` (string del enum `ViaAcceso`)

Migrar `obtenerPorRut(rut)` → `GET /carrera/estudiante/:rut`.

---

## Fase 4 — Ramos y Notas
*Es la fase más extensa. Los modelos cambian significativamente.*

### 4.1 Actualizar modelo `Ramo`
**Archivos:** `lib/services/ramo_service.dart`

El backend devuelve desde `GET /ramo/me`:
```json
[{ "id": 1, "rut_estudiante": "...", "semestre_id": 1, "codigo_carrera": 1,
   "nombre": "Cálculo II", "estado": "EN_CURSO", "comentario": "",
   "intento": 1, "nota_final": null }]
```

Cambios en el modelo:
- `id` (String) → `id` (int)
- `semestreId` (String) → `semestre_id` (int)
- `rutEstudiante` → `rut_estudiante`
- Agregar `codigo_carrera` (int)
- Agregar `estado` (String — enum `EstadoRamo` del backend: `EN_CURSO`, `APROBADO`, `REPROBADO`, etc.)
- Agregar `comentario` (String)
- Agregar `nota_final` (double?, nullable) — **reemplaza completamente `PromedioFinalService`**
- Eliminar `puedoAyudar` del modelo por ahora (ver Fase 6)

### 4.2 Migrar `RamoService` a la API
**Archivos:** `lib/services/ramo_service.dart`

- `leerRamos()` → `GET /ramo/me`
- `guardarRamos()` → eliminar (no hay equivalente; cada operación es individual)
- `crearRamo(dto)` → `POST /ramo/me` con `{ semestre_id, codigo_carrera, nombre, estado, intento, comentario }`
- `actualizarRamo(id, dto)` → `PATCH /ramo/me/:id_ramo`
- Eliminar toda la lógica de archivos locales y seed desde JSON

**Nota importante para crear un ramo:** el endpoint `POST /ramo/me` requiere `semestre_id` (int) y `codigo_carrera` (int). La app debe tener cargados previamente el semestre seleccionado y la carrera del estudiante para poder enviarlos al crear un ramo.

### 4.3 Eliminar `PromedioFinalService`
**Archivos:** `lib/services/promedio_final_service.dart` (eliminar), `lib/pages/page1.dart`

Las notas se guardan como `nota_final` en el propio ramo vía `PATCH /ramo/me/:id_ramo { nota_final: X }`.
`Page1` debe actualizar su lógica: en lugar de leer/escribir en `PromedioFinalService`, lee `ramo.nota_final` y guarda con `PATCH`.

### 4.4 Actualizar UI de `Page0` (Mis Ramos)
**Archivos:** `lib/pages/page0.dart`

- El selector de semestre ahora usa `semestre_id` (int) y muestra el label generado (ej: `'2025 - Segundo Semestre'`)
- El formulario de crear/editar ramo debe incluir el campo `estado` (dropdown con valores del enum `EstadoRamo`)
- Al crear un ramo, `semestre_id` y `codigo_carrera` se toman del semestre seleccionado y la carrera del estudiante (cargados al inicio)
- Eliminar `semestreSeleccionado.esActual` — la lógica de "puedo agregar ramos" se redefine (solo en el semestre más reciente, o según `estado`)

### 4.5 Actualizar UI de `Page1` (Mis Notas)
**Archivos:** `lib/pages/page1.dart`

- Reemplazar `PromedioFinalRegistro` por el campo `nota_final` del modelo `Ramo`
- El botón "Guardar" hace `PATCH /ramo/me/:id_ramo { nota_final: X }`
- El cálculo del promedio del semestre en `Page2` se basa en los `nota_final` de los ramos del semestre actual
- El botón "Subir certificado de promedios" necesita un endpoint real en el backend (`POST /estudiante/me/foto` existe para foto de perfil; hablar con el compañero sobre si agregar un endpoint para certificados)

---

## Fase 5 — Compromiso (Acuerdo)
*El backend tiene todo implementado. Solo falta la UI en `Page4`.*

### 5.1 Implementar `Page4` (Compromiso)
**Archivos:** `lib/pages/page4.dart`, `lib/services/acuerdo_service.dart` (nuevo)

Endpoints disponibles:
- `GET /acuerdo/vigente` — devuelve el documento del acuerdo actual (contenido, fecha vigencia)
- `GET /acuerdo/me/estado` — devuelve si el estudiante ya firmó la versión vigente
- `POST /acuerdo/firmar` — firma el acuerdo vigente

Flujo de la UI:
1. Al entrar a la pestaña, llamar a `GET /acuerdo/me/estado`
2. Si no firmó: mostrar el contenido del acuerdo y botón "Firmar"
3. Si ya firmó: mostrar confirmación con fecha de firma
4. El botón "Firmar" llama a `POST /acuerdo/firmar`

---

## Fase 6 — Modificaciones al backend (casos puntuales)
*Solo los endpoints que faltan para que el estudiante pueda operar. La lógica de negocio ya existe.*

### 6.1 🔧 Backend + Frontend: Campo `puedo_ayudar` en `Ramo`
**Backend:** `src/ramo/` — agregar campo `puedo_ayudar` (boolean, default false) al modelo Prisma y al `UpdateRamoDto`

El estudiante debe poder marcar ramos aprobados de semestres anteriores como "puedo ayudar a otros estudiantes". El campo `puedoAyudar` ya existe en la UI de `Page0` (el toggle en ramos de semestres pasados) pero no tiene respaldo en el backend.

**Endpoints afectados:**
- `PATCH /ramo/me/:id_ramo` — ya existe, solo agregar `puedo_ayudar` al `UpdateRamoDto`
- `GET /ramo/me` — ya devuelve todos los ramos; la app filtra los que tienen `puedo_ayudar = true`

**Frontend:** `lib/services/ramo_service.dart`, `lib/pages/page0.dart`, `lib/pages/page2.dart`
- `actualizarPuedoAyudar(id, value)` → `PATCH /ramo/me/:id { puedo_ayudar: value }`
- La sección "Puedo ayudar" en `Page2` filtra `ramos.where((r) => r.puedo_ayudar && r.semestre_id != semestreActual.semestre_id)`

### 6.2 🔧 Backend + Frontend: Endpoint de Becarios para estudiantes
**Backend:** agregar en `EstudianteController` un endpoint `GET /estudiante/becarios` con rol `ESTUDIANTE`

Actualmente `GET /estudiante` requiere rol `ADMIN/TUTOR/VISITA`. El estudiante no puede listar a sus pares.
El nuevo endpoint debe devolver solo campos públicos de los compañeros:
```
rut_estudiante, nombre, apellido, generacion_id, rbd_liceo + carrera + universidad
```
(sin `telefono`, `email`, `fecha_nacimiento`, `direccion` — datos sensibles)

**Frontend:** `lib/pages/page3.dart`, `lib/services/estudiante_service.dart`
- Reemplazar carga desde `assets/data/students_becarios.json` por llamada al nuevo endpoint
- La lógica de filtros (Mi U, Mi Carrera, Mi Liceo) se mantiene igual
- Los ramos "puedo ayudar" de cada becario vienen de `GET /ramo/me` del propio estudiante (Fase 4); los de otros becarios requieren que el endpoint de becarios los incluya en la respuesta, o un endpoint separado `GET /ramo/becario/:rut`

### 6.3 🔧 Backend + Frontend: Familiar / Contacto de emergencia para el estudiante
**Situación:** el endpoint `POST /familiar` y `GET /familiar/estudiante/:rut` están restringidos a `ADMIN/TUTOR`. El estudiante no puede gestionar sus propios familiares.

**Diferencias de modelo a resolver antes de implementar:**

| Frontend (ContactoEmergencia) | Backend (Familiar) |
|---|---|
| `relacion` (texto libre) | `parentesco` (enum Parentesco) |
| `correo` (string) | no existe |
| — | `rut_familiar` (requerido) |
| — | `es_contacto_emergencia` (bool) |

**Decisiones a tomar con el compañero:**
- ¿Se cambia `relacion` en el frontend a un dropdown del enum `Parentesco`?
- ¿Se agrega `correo` al modelo `Familiar` en el backend?
- ¿`rut_familiar` es obligatorio (el familiar también tiene RUT) o es opcional para este caso?

**Backend:** agregar endpoints con rol `ESTUDIANTE`:
- `GET /familiar/me` — obtener propio familiar/contacto de emergencia
- `POST /familiar/me` o `PATCH /familiar/me/:id` — crear/actualizar

**Frontend:** `lib/services/contacto_emergencia_service.dart`, `lib/pages/page2.dart`
- Adaptar modelo `ContactoEmergencia` a los campos que queden definidos
- `obtenerPorRut()` → `GET /familiar/me`
- `guardar()` → `POST/PATCH /familiar/me`

---

## Resumen de fases

| Fase | Tarea | Toca backend | Estimado |
|---|---|---|---|
| 1 | Infraestructura (deps, ApiService, storage) | No | 1-2 h |
| 2 | Autenticación (login screen, JWT, UsuarioService) | No | 2-4 h |
| 3 | Perfil (Estudiante, Semestre, Carrera) | No | 3-5 h |
| 4 | Ramos y Notas (modelo, service, UI page0/page1) | No | 5-7 h |
| 5 | Compromiso (Page4 completa) | No | 3-4 h |
| 6.1 | Campo `puedo_ayudar` en Ramo | Sí (menor) | 2-3 h |
| 6.2 | Endpoint becarios para estudiante | Sí (nuevo endpoint) | 3-5 h |
| 6.3 | Familiar/contacto emergencia para estudiante | Sí (nuevos endpoints) | 3-5 h |

**Las Fases 1 a 5 son completamente independientes del backend** y pueden desarrollarse en paralelo con cualquier trabajo que haga el compañero en el backend.

**La Fase 6 requiere coordinación** con el compañero para definir los contratos de los nuevos endpoints antes de implementar el frontend correspondiente.
