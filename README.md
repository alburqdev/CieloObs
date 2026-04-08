# Cielo Obs 20240191 🌙⭐

**App de Observaciones del Cielo – República Dominicana**

---

## Información del Estudiante

| Campo | Valor |
|------|-------|
| **Nombre** | *Luis Alburquerque* |
| **Matrícula** | 20240191 |
| **Asignatura** | Aplicaciones Móviles |

---

## Descripción

Aplicación móvil Flutter para registrar fenómenos y eventos visibles en el cielo de manera **rápida y sin conexión a internet**. Diseñada para observadores en campo en República Dominicana.

---

## Funcionalidades

### 📝 Registro de Observaciones
- Título, fecha y hora (automática o manual)
- Categoría: Astronomía, Fenómeno atmosférico, Aves migratorias, Aeronave/Objeto artificial
- Condiciones del cielo (despejado, nublado, bruma, etc.)
- Descripción detallada (dirección, altura, etc.)
- Ubicación GPS (captura automática) o texto libre (sector/municipio/provincia)
- Duración estimada en segundos
- Foto (cámara o galería) — opcional
- Nota de voz grabada — opcional

### 🔍 Visualización
- Lista de todas las observaciones con filtros por:
  - Categoría
  - Lugar (texto)
  - Rango de fechas
- Detalle completo con mapa (si se capturó GPS via OpenStreetMap)
- Reproducción de nota de voz
- Compartir observación (JSON + texto)

### 👤 Sección "Acerca del Observador"
- Foto del observador
- Nombre, apellido y matrícula
- Frase motivadora sobre la curiosidad científica

### 🔐 Seguridad
- Botón **"Borrar Todo"** en la pantalla principal
- Elimina todas las observaciones y archivos asociados (fotos, audios)
- Confirmación doble antes de ejecutar

---

## Tecnología

| Ítem | Detalle |
|------|---------|
| **Framework** | Flutter 3.x / Dart 3 |
| **Base de datos** | SQLite (sqflite) |
| **Almacenamiento** | Local (sin red requerida) |
| **Mapa** | flutter_map + OpenStreetMap (requiere internet para ver tiles) |
| **GPS** | geolocator |
| **Imagen** | image_picker |
| **Audio** | record + just_audio |
| **Compartir** | share_plus |

---

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── db.dart                      # Helper SQLite (CRUD)
├── models/
│   ├── observacion.dart         # Modelo de observación
│   └── perfil.dart              # Modelo de perfil
└── screens/
    ├── home.dart                # Pantalla principal
    ├── nueva_observacion.dart   # Formulario de registro
    ├── lista_observaciones.dart # Lista con filtros
    ├── detalle_observacion.dart # Detalle + mapa + audio
    └── perfil_screen.dart       # Perfil del observador
```

---

## Estructura de Base de Datos

```sql
-- Tabla principal
CREATE TABLE observacion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo TEXT NOT NULL,
  fecha_hora TEXT NOT NULL,       -- ISO-8601
  lat REAL,                       -- nullable
  lng REAL,                       -- nullable
  ubicacion_texto TEXT,           -- nullable
  duracion_seg INTEGER,           -- nullable
  categoria TEXT NOT NULL,
  condiciones_cielo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  foto_path TEXT,                 -- ruta local, nullable
  audio_path TEXT,                -- ruta local, nullable
  creado_en TEXT NOT NULL
);

-- Perfil del observador (1 registro)
CREATE TABLE perfil (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  matricula TEXT NOT NULL,
  foto_path TEXT,
  frase TEXT NOT NULL
);
```

---

## Instalación

### Desde código fuente:
```bash
flutter pub get
flutter run
```

### Generar APK:
```bash
flutter build apk --release
# El APK se genera en: build/app/outputs/flutter-apk/app-release.apk
```

---

## Permisos Requeridos (Android)

- `CAMERA` — para tomar fotos
- `RECORD_AUDIO` — para notas de voz
- `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` — acceso a galería
- `ACCESS_FINE_LOCATION` — GPS
- `INTERNET` — solo para cargar tiles del mapa (funcionalidad opcional)

---

## Operatividad Offline

✅ El registro, visualización, edición y borrado de observaciones funciona **100% offline**.  
⚠️ Los tiles del mapa en el detalle de observación requieren internet para visualizarse.

---

## Versión SDK

- Flutter: `>=3.5.0`
- Dart: `>=3.5.0`
- Android minSdkVersion: 21 (Android 5.0+)
- targetSdkVersion: 34
