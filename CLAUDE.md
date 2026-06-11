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
| `Paciente.swift` | `Paciente` | owns `[Consulta]` and `[MedicamentoPaciente]` (cascade-delete); owns `[ConsentimientoPrivacidad]`; `condicionesCronicas: [String]` |
| `Consulta.swift` | `Consulta` | belongs to one `Paciente`; `recetasJSON: String` stores `[RecetaLocal]` as JSON (nombre + dosis combinada + duracion); `medicamentos: [String]` for names only |
| `MedicamentoPaciente.swift` | `MedicamentoPaciente` | belongs to `Paciente`; `indicacion` = dosis + instrucciones combinadas; `duracion: String?`; `estaActivo` = `fechaFin == nil` |
| `Personal.swift` | `Personal` | `curpPersonal` is functional PK; `areasDeServicio: [String]`; `matricula: String?` nil for students |
| `Jornada.swift` | `Jornada` | `serviciosDisponibles: [String]` controls active services; owns `[Personal]` and `locacion: Locacion?` |
| `Locacion.swift` | `Locacion` | always estado = "Nuevo León" (AMM scope) |
| `ConsentimientoPrivacidad.swift` | `ConsentimientoPrivacidad` | belongs to `Paciente`; has `sincronizado: Bool?` |

`RetoApp.swift` creates the single `ModelContainer` with the full schema.

Domain enums: `Sexo` (masculino / femenino / noDefinido) and `TipoConsulta` (consultaGeneral / entregaMedicamentos / optometrista / dental).

`Paciente` does **not** have follow-up scheduling fields — Cáritas operates on walk-in basis only.

### Views

| File | Purpose |
|---|---|
| `ContentView.swift` | Root `NavigationSplitView`; sidebar; auto-opens `ConfigurarJornadaView` when no active jornada; passes `syncVM` as `environmentObject` to `ConfigurarJornadaView` |
| `DashboardView.swift` | Jornada banner, services grid, patient count and last 5 patients — all filtered by active jornada; tapping a patient closes the sidebar and opens `ExpedientePacienteView` |
| `NuevoPacienteView.swift` | Multi-step wizard for new patient registration (see Wizard steps below) |
| `HistorialJornadaView.swift` | Patient list filtered by the active jornada's municipality plus any patient attended today; tapping a patient closes the sidebar and opens `ExpedientePacienteView` |
| `VistaPacienteRegistrado.swift` | Narrow left panel (340 pt) with patient demographics — always used inside `ExpedientePacienteView` |
| `ExpedientePacienteView.swift` | Full two-panel expediente: `VistaPacienteRegistrado` left + tabbed right panel |
| `NuevaConsultaView.swift` | Follow-up consultation form; all four types include "Medicamentos recetados" section with nombre + cantidad + unidad picker + duración |
| `PersonalView.swift` | Split view: list + `PerfilPersonalView`; `FormularioPersonalView` sheet with CURP auto-generation |
| `ConfigurarJornadaView.swift` | Full-screen jornada setup: AMM municipality, services toggle, personal checklist; on save downloads patients for that municipality from the server if online |
| `StatisticsDashboardView.swift` | Real SwiftData queries — no mock data |
| `CaritasSyncVM.swift` | `@MainActor ObservableObject`; syncs all entities to FastAPI backend; injected as `@EnvironmentObject` |

### Wizard steps (`NuevoPacienteView.pasosDinamicos`)

| Key | Title | Condition |
|---|---|---|
| `identificacion` | Identificación del paciente | Always — two options: "Primera visita" (new) or "Ya tiene expediente" (returning); returning path searches SwiftData by name/CURP with `similaridad()` |
| `datos_personales` | Datos personales y residencia | Always — sexo is `Sexo?` (nil = not selected); duplicate detection runs live via `candidatoDuplicado` (score ≥ 70 shows orange banner with "Ver expediente →") |
| `consulta` | Motivo de consulta | Always — services picker filtered by `jornadaActiva.serviciosDisponibles`; auto-selects doctor if only one is available |
| `signos_vitales` | Signos vitales | Only when `servicioSeleccionado == "Consulta general"`; frecuencia cardiaca auto-fills from pulso |
| `recetas` | Receta médica | All services except "Entrega de medicamentos" |
| `privacidad` | Aviso de privacidad | Always — shows summary card (nombre, municipio, servicio, médico, sexo) below the signature area |

**Wizard UX:**
- Top-right X button: if no data entered, discards immediately; otherwise shows "¿Descartar el registro?" alert
- After saving: animated toast banner slides up from bottom ("✓ [Nombre] registrado"), auto-dismisses after 2.5s, then resets the form

### Duplicate patient detection (`NuevoPacienteView.candidatoDuplicado`)

Runs live in `paso_datos_personales` once primer nombre + primer apellido have ≥ 2 chars each. Weighted score 0–100:

| Field | Points |
|---|---|
| Primer nombre exact | 30 |
| Primer nombre prefix | 15 |
| Primer apellido exact | 30 |
| Primer apellido prefix | 15 |
| Fecha de nacimiento same day | 25 |
| Fecha de nacimiento same year | 10 |
| Segundo apellido exact | 10 |
| Municipio match | 5 |

Score ≥ 70 → orange banner appears at top of paso 2 with patient name, age, municipio, score, and "Ver expediente →" button. Dismissable per candidate; resets on `reiniciarFormulario()`.

### Recetas data flow

1. Wizard (`NuevoPacienteView`) and `NuevaConsultaView` capture: nombre, cantidad (numeric), unidad (picker: mg/g/ml/tab./cáp./gotas/sobre/amp.), duración, indicación
2. Dosis stored as combined `"500 mg"` in `RecetaLocal.dosis`
3. `Consulta.recetasJSON` stores `[RecetaLocal]` as JSON
4. `MedicamentoPaciente` also created with `indicacion = "500 mg · indicación"` for the Medicamentos tab
5. On sync: `POST /registros-clinicos` returns `id_registro` → app POSTs each receta to `POST /registros-clinicos/{id_registro}/recetas`

`RecetaLocal`, `RecetaWizard`, `unidadesDosis` are defined at file level in `NuevoPacienteView.swift`. `MedicamentoTemporal` in `NuevaConsultaView.swift`. `RecetaLocal.encode/decode` helpers in `CaritasSyncVM.swift`.

### Expediente clínico (`ExpedientePacienteView`)

Two-panel layout: left panel (`VistaPacienteRegistrado`, 340 pt fixed width) + right panel (tabbed expediente).

**Tabs (in order):**

| Tab | View | Content |
|---|---|---|
| **Datos clínicos** (default) | `DatosClinicosPacienteView` | IMC calculated from talla in cm, blood pressure, vitals, socioeconomic data |
| **Medicamentos** | `HistorialMedicamentosPacienteView` | Prescription history grouped by consultation — shows nombre, dosis, duración, notas; only shows consultations that have recetas |
| **Consultas** | `LineaTiempoPacienteView` | Expandable timeline — each consultation entry shows date, type, doctor; tap to expand full details (motivo, diagnóstico, notas, recetas, vitals, procedimientos) |

**Tab selector UI:** Full-width square buttons with a 2px `caritasPrimario` bottom border on the active tab. Uses `withAnimation(.easeInOut)` on selection.

**Never use `VistaPacienteRegistrado` directly as a navigation destination** — it is only the left panel. Use `ExpedientePacienteView` with an `onBack` closure.

### Patient filtering by jornada

- **Dashboard counts and "últimos pacientes":** filtered to patients who have a consulta linked to `jornadaActiva` (by `$0.jornada?.idJornada == jornada.idJornada`)
- **Historial list:** shows patients where `paciente.municipio == jornadaActiva.locacion.municipio` (pre-loaded from server) **OR** patients with at least one consulta in the active jornada (registered during the brigade, may live in another municipality)
- **Fallback:** if no active jornada, shows all patients

### Patient pre-loading (offline support)

When starting a jornada in `ConfigurarJornadaView`:
1. Jornada saved locally immediately (works offline)
2. If online, shows loading overlay "Descargando pacientes de [municipio]…"
3. Calls `syncVM.descargarPacientesPorMunicipio(_:context:)` → `GET /pacientes?municipio=X`
4. Inserts patients not already stored locally, marked `sincronizado = true`
5. Patients are available offline for the entire brigade day

Note: `paciente.municipio` is the patient's **residence** municipality, which may differ from the brigade's location. Do not pre-fill the patient registration form's municipio field from the active jornada.

### Sync (`CaritasSyncVM.swift`)

Sync order in `sincronizar()`:
1. `subirPersonalLocal` — only `sincronizado != true` records
2. `subirJornadasLocales`
3. `subirPacientesLocales`
4. `descargarPacientesDelServidor` → returns `caritasId → serverUUID` map
5. `subirConsultasLocales` → reads `id_registro` from response → calls `subirRecetas`
6. `subirMedicamentosLocales`
7. `subirConsentimientosLocales`

`CaritasSyncVM` is injected as `@EnvironmentObject` at the root. `fullScreenCover` and `sheet` modals must explicitly receive `.environmentObject(syncVM)` since SwiftUI does not inherit environment through these.

### Backend (`main.py` — FastAPI + MySQL, school VM)

**Base URL:** `http://10.14.255.97:8001` (requires school VPN/network)

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/pacientes?municipio=X` | Optional filter — returns only patients from that municipality when provided |
| POST | `/pacientes` | |
| GET | `/pacientes/{id}` | |
| GET | `/pacientes/{id}/registros-clinicos` | |
| POST | `/registros-clinicos` | Returns `{"id_registro": "...", "mensaje": "..."}` — UUID generated in Python with `uuid.uuid4()` |
| GET/POST | `/registros-clinicos/{id}/recetas` | |
| GET | `/pacientes/{id}/medicamentos` | |
| POST | `/medicamentos-paciente` | |
| GET/POST | `/personal` | POST upserts by `id_personal` or `curp_personal`; auto-assigns `numero_personal` via `MAX+1` |
| GET/POST | `/jornadas` | |
| POST | `/consentimientos` | Inserts into `consentimiento_privacidad` table |

### Data normalization (`StringNormalizacion.swift`)

All data is normalized at save time via `String` extensions. Always pre-compute normalized values as `let` constants before passing to SwiftData initializers — calling these properties inline inside an `@Model` init can confuse Swift's `@dynamicMemberLookup` type inference.

| Helper | Rule | Example |
|---|---|---|
| `.limpio` | Trim + collapse internal spaces | `"  Juan  "` → `"Juan"` |
| `.nombrePropio` | Title Case, respects Spanish prepositions (de/del/la/las/los/y/e/el) | `"JUAN DE LA ROSA"` → `"Juan de la Rosa"` |
| `.codigoNormalizado` | Uppercase + trim (CURP, matrícula) | `"vagr930209hnllmf23"` → `"VAGR930209HNLLMF23"` |
| `.textoLibre` | First letter uppercase only (notes, motivo, diagnóstico) | `"DOLOR de cabeza"` → `"Dolor de cabeza"` |

### Design system (`Colores.swift`)

| Token | Hex | Use |
|---|---|---|
| `Color.caritasPrimario` | `#009CA6` | Primary teal — buttons, active tab indicator, active states |
| `Color.caritasAcento` | `#FF7F32` | Orange accent — "Registrar" CTA, current step indicator, duplicate detection banner |
| `Color.caritasAzul` | `#003B5C` | Dark navy — headings, patient names |
| `Color.caritasGris` | `#888B8D` | Secondary text, inactive states |
| `Color.caritasSuave` | `#D1E0D7` | Light green — selected backgrounds, active tab fill, header strips, auto-selected doctor chip |

Never use raw hex values in views — always use these tokens.

### Navigation pattern

`ContentView` exposes two environment keys:
- `toggleSidebar` — toggles sidebar open/closed (used by hamburger buttons in each view)
- `hideSidebar` — always collapses to `.detailOnly` (called when opening a patient expediente from Dashboard or Historial so the full two-panel layout has room)

### Doctor picker behavior

Both `NuevoPacienteView` (paso consulta) and `NuevaConsultaView`:
1. Personal pool: assigned to `jornadaActiva` (falls back to all active `Personal` if no jornada)
2. Filtered by `areasDeServicio.contains(servicioSeleccionado)` — doctors with empty `areasDeServicio` appear in all services
3. **If exactly one doctor is available:** shows a teal chip with checkmark instead of a picker, and `medicoSeleccionado` is set automatically
4. Recalculates when `servicioSeleccionado` changes

### Blood pressure storage

Captured as two fields (sistólica / diastólica), stored as `"120/80"` in `Consulta.presionArterial`.

### CURP auto-generation

`PersonalView.FormularioPersonalView` computes CURP using RENAPO algorithm. First 16 chars accurate; homoclave defaults to `"00"`. Field is editable.

## Known pending work

- Feature: condiciones crónicas — model has `[String]` but no UI to add them in the wizard or edit them in the expediente
- Feature: search/filter bar in `HistorialJornadaView`
- Feature: CURP scan → auto-fill fecha de nacimiento and sexo
