# Cáritas — App de Brigadas Médicas

iOS/iPadOS app para **Cáritas** — organización católica que realiza brigadas médicas móviles en comunidades rurales de México. Gestiona registro de pacientes, consultas, recetas, personal médico y estadísticas por jornada. UI y variables en español.

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
| Dependencias | Ninguna |
| Target | iPadOS 17+, Landscape |

## Funcionalidades

### Jornada
- Configuración diaria: municipio AMM, servicios disponibles, personal asignado
- Al iniciar con red: descarga automática de todos los pacientes del municipio → disponibles offline toda la brigada
- La app filtra pacientes, conteos y estadísticas según el municipio y jornada activos

### Registro de pacientes (wizard multi-paso)
1. **Identificación** — primera visita o ya tiene expediente; búsqueda por nombre y CURP con algoritmo de similitud
2. **Datos personales** — nombre, fecha de nacimiento, sexo (obligatorio, "Prefiero no decir" es opción válida), municipio de residencia; detección automática de posibles duplicados (score 0–100 ponderado por nombre, apellido, fecha de nacimiento y municipio; alerta si ≥ 70)
3. **Motivo de consulta** — servicios filtrados por los habilitados en la jornada; médico auto-seleccionado si solo hay uno disponible para el servicio
4. **Signos vitales** — solo Consulta general; frecuencia cardiaca se auto-llena desde el pulso
5. **Receta médica** — nombre + cantidad + unidad (mg/g/ml/tab./cáp./gotas/sobre/amp.) + duración; filas dinámicas con "+"
6. **Aviso de privacidad** — PDF, checkbox, firma, y tarjeta resumen de los datos capturados

**UX del wizard:** botón X con confirmación si hay datos ingresados; toast animado ("✓ Juan García registrado") al guardar que auto-reinicia el formulario.

### Expediente clínico (3 pestañas)
Selector de pestañas: botones cuadrados de ancho completo con línea indicadora.

| Pestaña | Contenido |
|---|---|
| **Datos clínicos** (default) | IMC calculado, signos vitales, presión arterial, datos socioeconómicos |
| **Medicamentos** | Historial de recetas agrupado por consulta: nombre, dosis, duración, observaciones |
| **Consultas** | Línea de tiempo expandible — toca una entrada para ver motivo, diagnóstico, notas, recetas, signos vitales y procedimientos |

### Nueva consulta
- Accesible desde el expediente del paciente
- Todos los tipos (general, dental, optometría, entrega) incluyen sección de medicamentos recetados con selector de unidad
- Médico auto-seleccionado si solo hay uno disponible; frecuencia cardiaca se auto-llena desde el pulso

### Filtrado por jornada
- **Dashboard:** cuenta solo pacientes con consulta en la jornada activa del día
- **Historial:** muestra pacientes del municipio activo (pre-cargados del servidor) **más** cualquier paciente atendido en la jornada aunque viva en otro municipio
- Sin jornada activa: muestra todo sin filtro

### Personal médico
- Alta/edición con CURP auto-generado (algoritmo RENAPO, primeros 16 chars exactos)
- Áreas de servicio múltiples; el picker de médico filtra por jornada activa + servicio seleccionado

### Sincronización (requiere VPN escolar)
Sube en orden: personal → jornadas → pacientes → consultas + recetas → medicamentos → consentimientos.
Solo sube registros con `sincronizado != true`. Al crear una consulta, el servidor devuelve `id_registro` para luego subir las recetas.

## Arquitectura

### Modelos SwiftData

| Modelo | Notas |
|---|---|
| `Paciente` | Raíz; posee `[Consulta]`, `[MedicamentoPaciente]`, `[ConsentimientoPrivacidad]` (cascade-delete) |
| `Consulta` | `recetasJSON: String` — `[RecetaLocal]` codificado como JSON (nombre + dosis + duracion) |
| `MedicamentoPaciente` | `indicacion` = dosis + instrucciones combinadas; `duracion: String?` |
| `Personal` | `areasDeServicio: [String]`; `curpPersonal` es PK funcional |
| `Jornada` | `serviciosDisponibles: [String]` controla qué servicios aparecen en el wizard |
| `ConsentimientoPrivacidad` | `sincronizado: Bool?` |

### Backend — endpoints (`main.py`)

| Endpoint | Notas |
|---|---|
| `GET /pacientes?municipio=X` | Filtra por municipio cuando se provee el parámetro |
| `POST /pacientes` | |
| `POST /registros-clinicos` | Devuelve `{"id_registro": "uuid", "mensaje": "..."}` |
| `GET/POST /registros-clinicos/{id}/recetas` | |
| `POST /medicamentos-paciente` | |
| `GET/POST /personal` | POST hace upsert; asigna `numero_personal` automáticamente |
| `GET/POST /jornadas` | |
| `POST /consentimientos` | Inserta en `consentimiento_privacidad` |

**URL:** `http://10.14.255.97:8001` — requiere VPN o red escolar

### Normalización de datos (`StringNormalizacion.swift`)

Aplicada al guardar en todos los formularios. Pre-computar con `let` antes de pasar a inicializadores de SwiftData.

| Helper | Aplica a | Resultado |
|---|---|---|
| `.nombrePropio` | Nombres, municipio | `"JUAN DE LA ROSA"` → `"Juan de la Rosa"` |
| `.codigoNormalizado` | CURP, matrícula | `"vagr930"` → `"VAGR930"` |
| `.textoLibre` | Motivo, diagnóstico, notas | `"DOLOR cabeza"` → `"Dolor cabeza"` |
| `.limpio` | Todos | Trim + colapsa espacios |

### Design tokens (`Colores.swift`)

| Token | Color | Uso |
|---|---|---|
| `caritasPrimario` | `#009CA6` teal | Botones principales, tab activo |
| `caritasAcento` | `#FF7F32` naranja | CTA "Registrar", paso actual del wizard |
| `caritasAzul` | `#003B5C` azul marino | Encabezados, nombres |
| `caritasGris` | `#888B8D` gris | Texto secundario, inactivos |
| `caritasSuave` | `#D1E0D7` verde claro | Fondos seleccionados, franjas de encabezado |

Nunca usar hex crudos en vistas.

## Alcance geográfico

16 municipios del **Área Metropolitana de Monterrey (AMM)**, Nuevo León.

## Proyecto académico

**TC2007B** — en colaboración con Cáritas Monterrey.
