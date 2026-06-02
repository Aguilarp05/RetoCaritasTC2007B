# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS/iPadOS app for **Cáritas** — a Catholic charity that runs mobile medical brigades in rural Mexican communities. The app manages patient registration, medical consultations, medications, medical staff, and per-jornada (brigade day) statistics. The UI and variable names are primarily in Spanish.

The Xcode project is at `Reto/Reto.xcodeproj`. All source lives under `Reto/Reto/`.

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
| `Consulta.swift` | `Consulta` | belongs to one `Paciente`; holds `[String]` arrays for medicamentos/procedimientos; `notasMedico: String` stores per-visit doctor notes |
| `MedicamentoPaciente.swift` | `MedicamentoPaciente` | belongs to one `Paciente`; `estaActivo` is `fechaFin == nil` |
| `Personal.swift` | `Personal` | `curpPersonal` is the functional PK; `especialidad` is their professional title (e.g. "Médico general"); `areasDeServicio: [String]` lists which brigade services they can cover (can rotate); `matricula: String?` is nil for students/interns |
| `Jornada.swift` | `Jornada` | owns `locacion: Locacion?`; has `[Personal]` relationship and a `personalNombres: [String]` denormalized copy for display |
| `Locacion.swift` | `Locacion` | location data for a jornada; always estado = "Nuevo León" (AMM scope) |
| `ConsentimientoPrivacidad.swift` | `ConsentimientoPrivacidad` | belongs to one `Paciente` |
| `Item.swift` | `Item` | Xcode template leftover — registered in `ModelContainer` but unused |

`RetoApp.swift` creates the single `ModelContainer` with the full schema and injects it via `.modelContainer()`.

Domain enums: `Sexo` (masculino / femenino / noDefinido) and `TipoConsulta` (consultaGeneral / entregaMedicamentos / optometrista / dental).

### Views

| File | Purpose |
|---|---|
| `ContentView.swift` | Root `NavigationSplitView`; sidebar with links to all main screens; auto-opens `ConfigurarJornadaView` when no active jornada exists |
| `DashboardView.swift` | Today's jornada banner, services availability grid, patient count, and last 5 patients list — wired to live SwiftData queries |
| `NuevoPacienteView.swift` | Multi-step wizard (4–5 steps) for new patient registration; paso 3 includes `notasMedico` field; presión arterial split into sistólica/diastólica; `numIntegrantes` is a stepper; doctor picker filters by active jornada's personal AND selected service area |
| `HistorialJornadaView.swift` | Scrollable list of all registered patients; tapping a row opens `ExpedientePacienteView` |
| `VistaPacienteRegistrado.swift` | Two-panel patient record: left panel shows personal data + notas importantes + condiciones crónicas; right panel has tabs: Historial, Datos clínicos (real SwiftData — IMC calculated from talla in cm), Medicamentos, Línea de tiempo (real SwiftData) |
| `NuevaConsultaView.swift` | Form for follow-up consultations; `puedeGuardar` is type-aware (each TipoConsulta has its own required fields); doctor picker filters by jornada + service area; lugar auto-fills from active jornada |
| `PersonalView.swift` | Split view: list on left (340px), `PerfilPersonalView` on right when a doctor is selected; `FormularioPersonalView` sheet with professional title picker + multi-select `areasDeServicio` chips |
| `ConfigurarJornadaView.swift` | Full-screen form to start a new jornada: AMM municipality picker, services toggle grid, and checkmark list of active `Personal` |
| `StatisticsDashboardView.swift` | Real SwiftData queries — no mock data; shows today's patients, jornadas, communities, sex/age distribution, hourly registration chart, top diagnoses, patients by service type |
| `CaritasSyncVM.swift` | `@MainActor ObservableObject`; syncs pacientes, consultas, medicamentos to FastAPI backend at `http://10.14.255.97:8001`; requires school VPN/network; marks records with `sincronizado: Bool?` |

### Backend (`main.py` — not in repo, runs on school VM)

FastAPI + MySQL. Endpoints: `GET/POST /pacientes`, `GET /pacientes/{id}/registros-clinicos`, `POST /registros-clinicos`, `GET /pacientes/{id}/medicamentos`, `POST /medicamentos-paciente`, `GET/POST /registros-clinicos/{id}/recetas`.

**Missing endpoints (pending):** `/personal`, `/jornadas` — these tables exist in DB but have no API endpoints yet.

**Pending sync work:** recetas never synced (need `id_registro` returned from POST); personal and jornadas not synced; `numero_personal` in DB is `INT NOT NULL UNIQUE` but no one assigns it.

### Design system (`Colores.swift`)

Custom `Color` extensions — never use raw hex values in views:

| Token | Hex | Use |
|---|---|---|
| `Color.caritasPrimario` | `#009CA6` | Primary teal — buttons, active states |
| `Color.caritasAcento` | `#FF7F32` | Orange accent — "Registrar" CTA, current step indicator |
| `Color.caritasAzul` | `#003B5C` | Dark navy — headings |
| `Color.caritasGris` | `#888B8D` | Secondary text, inactive states |
| `Color.caritasSuave` | `#D1E0D7` | Light green — selected card backgrounds, header strips |

### Navigation pattern

`ContentView` uses a custom `SidebarToggleKey` environment key so any detail view can call `toggleSidebar()` to show/hide the sidebar without needing a direct reference to the split view.

### Location scope

Both `NuevoPacienteView` and `ConfigurarJornadaView` use a hardcoded `municipiosAMM: [String]` list of the 16 Área Metropolitana de Monterrey municipalities. The estado is always hardcoded to `"Nuevo León"`.

### Doctor picker filtering logic

In both `NuevoPacienteView` and `NuevaConsultaView`:
1. Get `jornadaActiva` (today's jornada with `horaFin == nil`)
2. Use `jornadaActiva.personal` as the base pool; fall back to all active `Personal` if no jornada
3. Filter that pool by `areasDeServicio.contains(selectedService)` — doctors with empty `areasDeServicio` appear in all services

### CURP auto-generation

`PersonalView.FormularioPersonalView` computes a CURP from nombre, apellidos, fecha de nacimiento, sexo, and estado de nacimiento using the RENAPO algorithm. The first 16 characters are accurate; the homoclave (last 2) defaults to `"00"`. The field remains editable.

### Blood pressure storage

Presión arterial is captured as two separate fields (sistólica / diastólica) in the UI and stored/sent as a single string `"120/80"` in the `presionArterial` field of `Consulta`.

## Known pending work

- Bug: `NuevaConsultaView` dental type shows a duplicate "Dr. que atendió" field on top of the shared medico picker
- Feature: duplicate patient search in `NuevoPacienteView` paso 1 is hardcoded (triggers on "tor..." prefix) — should query SwiftData
- Feature: CURP scan → auto-fill fecha de nacimiento and sexo in paso 1
- Feature: frecuencia cardiaca auto-fill from pulso
- Feature: condiciones crónicas — model has `[String]` but no UI to add them in the wizard
- Sync: personal, jornadas, recetas not yet synced to backend
- Sync: `POST /registros-clinicos` must return `id_registro` before recetas can be synced
