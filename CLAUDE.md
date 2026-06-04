# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS/iPadOS app for **Cáritas** — a Catholic charity that runs mobile medical brigades in rural Mexican communities. The app manages patient registration, medical consultations, medications, medical staff, and per-jornada (brigade day) statistics. The UI and variable names are primarily in Spanish.

The Xcode project is at `Reto/Reto.xcodeproj`. All source lives under `Reto/Reto/`. The backend is `main.py` at the repo root.

## Build & Run

Open `Reto/Reto.xcodeproj` in Xcode, select an iPad simulator (the layout uses `NavigationSplitView` and assumes a wide screen), and press ⌘R.

```bash
# Build
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build

# Run unit tests
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

## Architecture

**SwiftUI + SwiftData**, no external dependencies. Backend sync via `CaritasSyncVM` (FastAPI + MySQL, requires school VPN).

### Data models (`@Model` classes backed by SwiftData)

| File | Class | Key relationships |
|---|---|---|
| `Paciente.swift` | `Paciente` | owns `[Consulta]` and `[MedicamentoPaciente]` (cascade-delete); owns `[ConsentimientoPrivacidad]` |
| `Consulta.swift` | `Consulta` | belongs to one `Paciente`; `medicamentos: [String]` stores names; `recetasJSON: String` stores `[RecetaLocal]` encoded as JSON (includes dosis+unidad+duracion); `notasMedico: String` per-visit notes |
| `MedicamentoPaciente.swift` | `MedicamentoPaciente` | belongs to one `Paciente`; `indicacion` holds dose+instructions combined; `duracion: String?`; `estaActivo` is `fechaFin == nil` |
| `Personal.swift` | `Personal` | `curpPersonal` is the functional PK; `especialidad` is their professional title; `areasDeServicio: [String]` lists which brigade services they cover; `matricula: String?` is nil for students/interns |
| `Jornada.swift` | `Jornada` | owns `locacion: Locacion?`; has `[Personal]` relationship and `personalNombres: [String]` denormalized copy; `serviciosDisponibles: [String]` controls which services are active that day |
| `Locacion.swift` | `Locacion` | location data for a jornada; always estado = "Nuevo León" |
| `ConsentimientoPrivacidad.swift` | `ConsentimientoPrivacidad` | belongs to one `Paciente`; has `sincronizado: Bool?` |
| `Item.swift` | `Item` | Xcode template leftover — registered in `ModelContainer` but unused |

`RetoApp.swift` creates the single `ModelContainer` with the full schema.

Domain enums: `Sexo` (masculino / femenino / noDefinido) and `TipoConsulta` (consultaGeneral / entregaMedicamentos / optometrista / dental).

### Views

| File | Purpose |
|---|---|
| `ContentView.swift` | Root `NavigationSplitView`; sidebar links to all main screens; auto-opens `ConfigurarJornadaView` when no active jornada |
| `DashboardView.swift` | Today's jornada banner, services grid, patient count, last 5 patients |
| `NuevoPacienteView.swift` | Multi-step wizard for new patient registration (see Wizard steps below) |
| `HistorialJornadaView.swift` | Scrollable list of all registered patients; tapping opens `ExpedientePacienteView` |
| `VistaPacienteRegistrado.swift` | Two-panel patient record: left panel shows personal data + notas + condiciones crónicas; right panel tabs: Historial (shows recetas with dose), Datos clínicos, Medicamentos (shows dose+duration), Línea de tiempo |
| `NuevaConsultaView.swift` | Follow-up consultation form; all four consultation types include a "Medicamentos recetados" section with nombre+cantidad+unidad picker+duracion |
| `PersonalView.swift` | Split view: list (340px) + `PerfilPersonalView`; `FormularioPersonalView` sheet with CURP auto-generation |
| `ConfigurarJornadaView.swift` | Full-screen form to start a new jornada: AMM municipality picker, services toggle grid, Personal checklist |
| `StatisticsDashboardView.swift` | Real SwiftData queries — no mock data |
| `CaritasSyncVM.swift` | `@MainActor ObservableObject`; syncs all entities to FastAPI backend |

### Wizard steps (`NuevoPacienteView.pasosDinamicos`)

| Key | Title | Condition |
|---|---|---|
| `identificacion` | Identificación del paciente | Always |
| `datos_personales` | Datos personales y residencia | Always |
| `consulta` | Motivo de consulta | Always — services filtered by `jornadaActiva.serviciosDisponibles` |
| `signos_vitales` | Signos vitales | Only when `servicioSeleccionado == "Consulta general"` |
| `recetas` | Receta médica | All services except "Entrega de medicamentos" |
| `privacidad` | Aviso de privacidad | Always |

### Recetas data flow

1. In the wizard (`NuevoPacienteView`) and in `NuevaConsultaView`, each medication row captures **nombre**, **cantidad** (numeric), **unidad** (picker: mg/g/ml/tab./cáp./gotas/sobre/amp.), **duración**, and **indicación**.
2. Dosis is stored as combined string `"500 mg"` in `RecetaLocal.dosis`.
3. `Consulta.recetasJSON` stores `[RecetaLocal]` as JSON for sync.
4. `MedicamentoPaciente` is also created with `indicacion = "500 mg · indicación"` so it appears in the Medicamentos tab.
5. On sync, `POST /registros-clinicos` returns `id_registro`; the app then POSTs each receta to `POST /registros-clinicos/{id_registro}/recetas`.

The `RecetaLocal`, `RecetaWizard`, and `unidadesDosis` are defined at file level in `NuevoPacienteView.swift` (and `MedicamentoTemporal` in `NuevaConsultaView.swift`). `RecetaLocal.encode/decode` static helpers live in `CaritasSyncVM.swift`.

### Sync (`CaritasSyncVM.swift`)

Sync order in `sincronizar()`:
1. `subirPersonalLocal` — only unsynced records
2. `subirJornadasLocales`
3. `subirPacientesLocales`
4. `descargarPacientesDelServidor` → returns `caritasId → serverUUID` map
5. `subirConsultasLocales` → reads `id_registro` from response → calls `subirRecetas`
6. `subirMedicamentosLocales`
7. `subirConsentimientosLocales`

All entities have `sincronizado: Bool?`; only `sincronizado != true` records are sent.

### Backend (`main.py` — FastAPI + MySQL, school VM)

**Base URL:** `http://10.14.255.97:8001` (requires school VPN/network)

| Method | Endpoint | Notes |
|---|---|---|
| GET/POST | `/pacientes` | |
| GET | `/pacientes/{id}` | |
| GET | `/pacientes/{id}/registros-clinicos` | |
| POST | `/registros-clinicos` | Returns `{"id_registro": "...", "mensaje": "..."}` — UUID generated in Python |
| GET | `/pacientes/{id}/medicamentos` | |
| POST | `/medicamentos-paciente` | |
| GET/POST | `/registros-clinicos/{id}/recetas` | |
| GET/POST | `/personal` | POST upserts by `id_personal` or `curp_personal` |
| GET/POST | `/jornadas` | |
| POST | `/consentimientos` | New — syncs `consentimiento_privacidad` table |

### Data normalization (`StringNormalizacion.swift`)

All data is normalized at save time via `String` extensions:

| Helper | Rule | Example |
|---|---|---|
| `.limpio` | Trim + collapse internal spaces | `"  Juan  "` → `"Juan"` |
| `.nombrePropio` | Title Case, respects Spanish prepositions (de/del/la/las/los) | `"JUAN DE LA ROSA"` → `"Juan de la Rosa"` |
| `.codigoNormalizado` | Uppercase + trim (for CURP, matrícula) | `"vagr930209hnllmf23"` → `"VAGR930209HNLLMF23"` |
| `.textoLibre` | First letter uppercase only (for notes, motivo, diagnóstico) | `"DOLOR de cabeza"` → `"Dolor de cabeza"` |

### Design system (`Colores.swift`)

| Token | Hex | Use |
|---|---|---|
| `Color.caritasPrimario` | `#009CA6` | Primary teal — buttons, active states |
| `Color.caritasAcento` | `#FF7F32` | Orange accent — "Registrar" CTA, current step indicator |
| `Color.caritasAzul` | `#003B5C` | Dark navy — headings |
| `Color.caritasGris` | `#888B8D` | Secondary text, inactive states |
| `Color.caritasSuave` | `#D1E0D7` | Light green — selected card backgrounds, header strips |

Never use raw hex values in views — always use these tokens.

### Navigation pattern

`ContentView` uses `SidebarToggleKey` environment key so any detail view can call `toggleSidebar()`.

### Location scope

Hardcoded to the 16 AMM municipalities of Nuevo León. `serviciosDisponibles` in the service picker is filtered to only show services enabled for the active jornada.

### Doctor picker filtering logic

Both `NuevoPacienteView` and `NuevaConsultaView` filter doctors by:
1. Only personal assigned to `jornadaActiva` (falls back to all active personal if no jornada)
2. `areasDeServicio.contains(servicioSeleccionado)` — doctors with empty `areasDeServicio` appear in all services

### Blood pressure storage

Captured as two fields (sistólica / diastólica), stored as `"120/80"` in `Consulta.presionArterial`.

### CURP auto-generation

`PersonalView.FormularioPersonalView` computes CURP using the RENAPO algorithm. First 16 chars are accurate; homoclave defaults to `"00"`. Field is editable.

## Known pending work

- Bug: `NuevaConsultaView` dental type still shows a duplicate "Dr. que atendió" field
- Feature: duplicate patient search in paso 1 is hardcoded (triggers on "tor..." prefix)
- Feature: CURP scan → auto-fill fecha de nacimiento and sexo
- Feature: frecuencia cardiaca auto-fill from pulso
- Feature: condiciones crónicas — model has `[String]` but no UI to add them in wizard
- Sync: `numero_personal` in DB is `INT NOT NULL UNIQUE` — assigned via `MAX+1` in backend
