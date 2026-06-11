# Cáritas — App de Brigadas Médicas

iOS/iPadOS app para **Cáritas** — organización católica que realiza brigadas médicas móviles en comunidades rurales de México. Gestiona registro de pacientes, consultas, recetas, personal médico, consentimientos informados y estadísticas por jornada. UI y variables en español.

Proyecto Xcode: `Reto/Reto.xcodeproj` · Código fuente: `Reto/Reto/` · Backend: `main.py` (raíz del repo)

## Build & Run

Abre `Reto/Reto.xcodeproj` en Xcode, selecciona un simulador de iPad y presiona ⌘R.

```bash
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

## Stack

| Elemento | Detalle |
|---|---|
| Lenguaje | Swift 5.9+ |
| UI | SwiftUI |
| Persistencia | SwiftData |
| Backend | FastAPI + MySQL (VM escolar, requiere VPN) |
| Dependencias | Ninguna (WKWebView para consentimientos) |
| Target | iPadOS 17+, Landscape |

## Funcionalidades

### Jornada
- Configuración diaria: municipio AMM, servicios disponibles, personal asignado
- Al iniciar con red: descarga automática de todos los pacientes del municipio → disponibles offline toda la brigada
- La app filtra pacientes, conteos y estadísticas según el municipio y jornada activos

### Registro de pacientes (wizard multi-paso)
1. **Identificación** — primera visita o ya tiene expediente; búsqueda por nombre y CURP con algoritmo de similitud
2. **Datos personales** — nombre, fecha de nacimiento, estado de nacimiento, sexo (obligatorio, "Prefiero no decir" es opción válida), municipio de residencia; CURP auto-generado (16 chars RENAPO) con campo separado para homoclave (2 chars); detección automática de posibles duplicados (score 0–100 ponderado, alerta si ≥ 70% del máximo alcanzable)
3. **Motivo de consulta** — servicios filtrados por los habilitados en la jornada; médico auto-seleccionado si solo hay uno disponible para el servicio
4. **Signos vitales** — solo Consulta general; frecuencia cardiaca se auto-llena desde el pulso
5. **Receta médica** — nombre + cantidad + unidad (mg/g/ml/tab./cáp./gotas/sobre/amp.) + duración
6. **Aviso de privacidad** — firma y tarjeta resumen de los datos capturados

**UX del wizard:** botón X con confirmación si hay datos; toast animado al guardar que auto-reinicia el formulario.

### Detección de duplicados
Algoritmo por intersección de frecuencias de caracteres (resiste typos como "Jckson" vs "Jackson"). Umbral dinámico según los campos disponibles. Banner naranja con campos similares detectados y botón "Ver expediente →".

### Expediente clínico (3 pestañas)

| Pestaña | Contenido |
|---|---|
| **Datos clínicos** (default) | IMC calculado, signos vitales, presión arterial, datos socioeconómicos |
| **Medicamentos** | Historial de recetas agrupado por consulta: nombre, dosis, duración |
| **Consultas** | Línea de tiempo expandible — motivo, diagnóstico, notas, recetas, signos vitales, procedimientos |

### Nueva consulta
- Accesible desde el expediente del paciente
- Todos los tipos incluyen sección de medicamentos recetados
- Diagnóstico con autocomplete filtrado por tipo de servicio (dentistas ven diagnósticos dentales, médicos generales ven los suyos)
- **Consulta dental:** botón "Ver consentimiento informado" que abre el formato oficial pre-llenado con los datos del paciente y médico; exportable como PDF

### Consentimientos informados
El formato de odontología (`consentimiento_odonto.html`) se muestra en un WebView con los siguientes campos auto-llenados: nombre del paciente, fecha de nacimiento, nombre del doctor, procedimiento, diagnóstico, municipio y fecha de firma. Los campos de riesgos, pronóstico y descripción del procedimiento se completan a mano.

### Historial
- Pacientes del municipio activo pre-cargados desde el servidor
- Agrupados por fecha de registro con divisores ("Hoy", "Ayer", fecha completa)

### Estadísticas (2 pestañas)
- **Jornada actual:** gráfica por hora dinámica (desde inicio de jornada hasta último paciente), distribución por servicio, sexo y diagnósticos — solo datos de la brigada del día
- **Historial de la zona:** totales acumulados (brigadas, pacientes únicos, recurrentes), tendencia por brigada y perfil epidemiológico del municipio

### Personal médico
- Alta/edición con CURP auto-generado (RENAPO) + campo de homoclave separado; enlace a `gob.mx/curp` para consulta
- Sexo con tres opciones: Femenino / Masculino / Prefiero no decir (genera CURP con X)
- Cédula profesional siempre visible en el perfil
- Estadísticas: consultas atendidas, jornadas participadas, tiempo activo desde el alta
- Áreas de servicio múltiples; el picker de médico filtra por jornada activa + servicio

### Sincronización (requiere VPN escolar)
Sube en orden: personal → jornadas → pacientes → consultas + recetas → medicamentos → consentimientos.
Solo registros con `sincronizado != true`. El servidor devuelve `id_registro` por consulta para subir recetas asociadas.

## Arquitectura

### Modelos SwiftData

| Modelo | Notas |
|---|---|
| `Paciente` | Raíz; posee `[Consulta]`, `[MedicamentoPaciente]`, `[ConsentimientoPrivacidad]` (cascade-delete); `lugarNacimiento` (estado); `caritasId` para pacientes sin CURP |
| `Consulta` | `recetasJSON: String` — `[RecetaLocal]` codificado como JSON |
| `MedicamentoPaciente` | `indicacion` = dosis + instrucciones combinadas; `duracion: String?` |
| `Personal` | `areasDeServicio: [String]`; `curpPersonal` es PK funcional; `matricula` opcional |
| `Jornada` | `serviciosDisponibles: [String]` controla qué servicios aparecen |
| `ConsentimientoPrivacidad` | `sincronizado: Bool?` |

### Backend — endpoints (`main.py`)

| Endpoint | Notas |
|---|---|
| `GET /pacientes?municipio=X` | Filtra por municipio cuando se provee |
| `POST /pacientes` | |
| `POST /registros-clinicos` | Devuelve `{"id_registro": "uuid"}` |
| `GET/POST /registros-clinicos/{id}/recetas` | |
| `POST /medicamentos-paciente` | |
| `GET/POST /personal` | POST hace upsert; asigna `numero_personal` automáticamente |
| `GET/POST /jornadas` | |
| `POST /consentimientos` | Inserta en `consentimiento_privacidad` |

**URL:** `http://10.14.255.97:8001` — requiere VPN o red escolar

### Normalización de datos

Todos los helpers en `StringNormalizacion.swift` eliminan acentos/diacríticos al guardar.

| Helper | Resultado |
|---|---|
| `.nombrePropio` | Title Case, preposiciones en minúscula, sin acentos |
| `.codigoNormalizado` | Mayúsculas + sin acentos (CURP, matrícula) |
| `.textoLibre` | Primera letra mayúscula + sin acentos (motivo, diagnóstico, notas) |
| `.limpio` | Trim + colapsa espacios internos |

### Design tokens (`Colores.swift`)

| Token | Color | Uso |
|---|---|---|
| `caritasPrimario` | `#009CA6` teal | Botones principales, tab activo |
| `caritasAcento` | `#FF7F32` naranja | CTA "Registrar", paso actual del wizard, banner de duplicados |
| `caritasAzul` | `#003B5C` azul marino | Encabezados, nombres |
| `caritasGris` | `#888B8D` gris | Texto secundario, inactivos |
| `caritasSuave` | `#D1E0D7` verde claro | Fondos seleccionados, franjas de encabezado |

## Alcance geográfico

16 municipios del **Área Metropolitana de Monterrey (AMM)**, Nuevo León.

## Proyecto académico

**TC2007B** — en colaboración con Cáritas Monterrey.
