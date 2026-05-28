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

**SwiftUI + SwiftData**, no external dependencies, no network layer.

### Data models (`@Model` classes backed by SwiftData)

| File | Class | Key relationships |
|---|---|---|
| `Paciente.swift` | `Paciente` | owns `[Consulta]` and `[MedicamentoPaciente]` (cascade-delete); owns `[ConsentimientoPrivacidad]` |
| `Consulta.swift` | `Consulta` | belongs to one `Paciente`; holds `[String]` arrays for medicamentos/procedimientos |
| `MedicamentoPaciente.swift` | `MedicamentoPaciente` | belongs to one `Paciente`; `estaActivo` is `fechaFin == nil` |
| `Personal.swift` | `Personal` | `curpPersonal` is the functional PK (not all staff have a cédula); `matricula: String?` is nil for students/interns; linked to `[Jornada]` and `[Consulta]` |
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
| `DashboardView.swift` | Today's jornada banner, services availability grid, patient count, and last 5 patients list — all wired to live SwiftData queries |
| `NuevoPacienteView.swift` | Multi-step wizard (4–5 steps depending on service) for new patient registration; persists `Paciente` + `Consulta` + `ConsentimientoPrivacidad` to SwiftData on submit; includes `VistaFirma` (canvas signature pad) and embedded PDF viewer for the privacy notice |
| `HistorialJornadaView.swift` | Scrollable list of all registered patients; tapping a row opens `ExpedientePacienteView` |
| `VistaPacienteRegistrado.swift` | Two-panel patient record with tabbed detail area: Historial, Datos clínicos, Medicamentos, Línea de tiempo |
| `NuevaConsultaView.swift` | Form for logging a follow-up consultation; fields adapt to `TipoConsulta`; persists to SwiftData |
| `PersonalView.swift` | CRUD screen for medical staff; list with avatar/specialty/CURP; sheet-based add/edit form with CURP auto-generation from nombre, apellidos, fecha de nacimiento, sexo, and estado de nacimiento |
| `ConfigurarJornadaView.swift` | Full-screen form to start a new jornada: AMM municipality picker, services toggle grid, and checkmark list of active `Personal` |
| `StatisticsDashboardView.swift` | Dark-themed stats dashboard; currently uses mock data via `MockStatisticsProvider` |

### Design system (`Colores.swift`)

Custom `Color` extensions used everywhere — never use raw hex values in views:

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

### CURP auto-generation

`PersonalView.FormularioPersonalView` computes a CURP from nombre, apellidos, fecha de nacimiento, sexo, and estado de nacimiento using the RENAPO algorithm. The first 16 characters are accurate; the homoclave (last 2) defaults to `"00"` since it requires RENAPO's internal registry to compute. The field remains editable. When editing existing staff, fecha and estado are parsed back from the stored CURP.

## Current State Notes

- `StatisticsDashboardView` uses fully mock data — wiring to SwiftData is pending.
- `DatosClinicosPacienteView` and `LineaTiempoPacienteView` (tabs inside `VistaPacienteRegistrado`) still display static/demo values.
- `NuevoPacienteView` and `NuevaConsultaView` populate the doctor/personal picker from live `@Query` of `Personal` records — no hardcoded doctor names remain.
- `Item.swift` is unused; it exists only because Xcode's default template added it and removing it from the `ModelContainer` would require a migration.
