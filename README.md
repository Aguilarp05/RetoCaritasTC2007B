# Cáritas — App de Brigadas Médicas

iOS/iPadOS app para **Cáritas** — organización católica que realiza brigadas médicas móviles en comunidades rurales de México. Gestiona registro de pacientes, consultas, medicamentos, personal médico y estadísticas por jornada. UI y variables principalmente en español.

El proyecto Xcode está en `Reto/Reto.xcodeproj`. Todo el código fuente vive bajo `Reto/Reto/`. El backend es `main.py` en la raíz del repositorio.

## Build & Run

Abre `Reto/Reto.xcodeproj` en Xcode, selecciona un simulador de iPad (el layout usa `NavigationSplitView`) y presiona ⌘R.

```bash
# Build
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build

# Tests
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

## Stack técnico

| Elemento | Detalle |
|---|---|
| Lenguaje | Swift 5.9+ |
| UI | SwiftUI |
| Persistencia | SwiftData |
| Backend | FastAPI + MySQL (VM escolar, requiere VPN) |
| Dependencias externas | Ninguna |
| Target | iPadOS 17+ |
| Orientación | Landscape (`NavigationSplitView`) |

## Funcionalidades principales

- **Configurar jornada** — municipio AMM, servicios disponibles y personal asignado
- **Registro de pacientes** — wizard multi-paso con CURP, datos personales, motivo de consulta, signos vitales, receta médica y aviso de privacidad con firma
- **Receta médica** — nombre del medicamento, cantidad con selector de unidad (mg / g / ml / tab. / cáp. / gotas / sobre / amp.) y duración
- **Expediente del paciente** — historial de consultas con recetas completas, medicamentos activos con dosis y duración, datos clínicos (IMC calculado) y línea de tiempo
- **Nueva consulta** — seguimiento para pacientes ya registrados; sección de medicamentos recetados disponible en todos los tipos de consulta (general, dental, optometría, entrega)
- **Personal médico** — alta/edición con CURP auto-generado, áreas de servicio múltiples, filtrado por jornada activa
- **Servicios filtrados por jornada** — el picker de servicios solo muestra los habilitados al configurar el día; el picker de médico solo muestra personal asignado a la jornada
- **Dashboard** — resumen del día con conteo de pacientes y disponibilidad de servicios
- **Estadísticas** — métricas reales desde SwiftData: distribución por sexo/edad, registros por hora, diagnósticos frecuentes
- **Sincronización** — sube pacientes, consultas, recetas, medicamentos, personal, jornadas y consentimientos al backend FastAPI

## Arquitectura

### Modelos de datos (`@Model` — SwiftData)

| Archivo | Clase | Notas clave |
|---|---|---|
| `Paciente.swift` | `Paciente` | Raíz; posee `[Consulta]`, `[MedicamentoPaciente]` (cascade-delete) y `[ConsentimientoPrivacidad]` |
| `Consulta.swift` | `Consulta` | `recetasJSON: String` almacena `[RecetaLocal]` en JSON (nombre + dosis combinada + duracion); `medicamentos: [String]` para nombres |
| `MedicamentoPaciente.swift` | `MedicamentoPaciente` | `indicacion` = dosis + instrucciones combinadas; `duracion: String?`; `estaActivo` = `fechaFin == nil` |
| `Personal.swift` | `Personal` | `curpPersonal` es PK funcional; `areasDeServicio: [String]`; `matricula: String?` nil para estudiantes |
| `Jornada.swift` | `Jornada` | `serviciosDisponibles: [String]` controla qué servicios están activos ese día |
| `Locacion.swift` | `Locacion` | Siempre estado = "Nuevo León" (alcance AMM) |
| `ConsentimientoPrivacidad.swift` | `ConsentimientoPrivacidad` | Pertenece a un `Paciente`; tiene `sincronizado: Bool?` |

### Pasos del wizard (`NuevoPacienteView`)

| Paso | Condición |
|---|---|
| Identificación | Siempre |
| Datos personales | Siempre |
| Motivo de consulta | Siempre — servicios filtrados por jornada activa |
| Signos vitales | Solo "Consulta general" |
| Receta médica | Todos excepto "Entrega de medicamentos" |
| Aviso de privacidad | Siempre |

### Flujo de recetas

1. El formulario captura **nombre**, **cantidad** (numérico) + **unidad** (picker), **duración** e **indicación**
2. La dosis se guarda como `"500 mg"` en `RecetaLocal.dosis`
3. `Consulta.recetasJSON` guarda `[RecetaLocal]` como JSON
4. `MedicamentoPaciente` se crea con `indicacion = "500 mg · indicación"` para que aparezca en la pestaña Medicamentos
5. En sync: `POST /registros-clinicos` devuelve `id_registro` → se postean las recetas a `POST /registros-clinicos/{id}/recetas`

### Normalización de datos (`StringNormalizacion.swift`)

Todos los datos se normalizan al guardar:

| Helper | Aplica a | Ejemplo |
|---|---|---|
| `.nombrePropio` | Nombres, apellidos, municipio | `"JUAN DE LA ROSA"` → `"Juan de la Rosa"` |
| `.codigoNormalizado` | CURP, matrícula | `"vagr930"` → `"VAGR930"` |
| `.textoLibre` | Motivo, diagnóstico, notas | `"DOLOR cabeza"` → `"Dolor cabeza"` |
| `.limpio` | Todos | Trim + colapsa espacios |

### Backend (`main.py` — FastAPI + MySQL)

**URL:** `http://10.14.255.97:8001` — requiere VPN o red escolar

| Endpoint | Método | Notas |
|---|---|---|
| `/pacientes` | GET / POST | |
| `/pacientes/{id}/registros-clinicos` | GET | |
| `/registros-clinicos` | POST | Devuelve `id_registro` (UUID generado en Python) |
| `/registros-clinicos/{id}/recetas` | GET / POST | |
| `/pacientes/{id}/medicamentos` | GET | |
| `/medicamentos-paciente` | POST | |
| `/personal` | GET / POST | POST hace upsert por `id_personal` o `curp_personal` |
| `/jornadas` | GET / POST | |
| `/consentimientos` | POST | Sincroniza `consentimiento_privacidad` |

### Sistema de diseño (`Colores.swift`)

| Token | Hex | Uso |
|---|---|---|
| `Color.caritasPrimario` | `#009CA6` | Teal — botones, estados activos |
| `Color.caritasAcento` | `#FF7F32` | Naranja — CTA "Registrar", indicador de paso actual |
| `Color.caritasAzul` | `#003B5C` | Azul marino — encabezados |
| `Color.caritasGris` | `#888B8D` | Texto secundario, estados inactivos |
| `Color.caritasSuave` | `#D1E0D7` | Verde claro — fondos de tarjetas seleccionadas |

Nunca usar valores hex crudos en vistas — siempre usar estos tokens.

## Alcance geográfico

Las 16 municipalidades del **Área Metropolitana de Monterrey (AMM)**, Nuevo León.

## Equipo

Proyecto académico **TC2007B** en colaboración con Cáritas Monterrey.
