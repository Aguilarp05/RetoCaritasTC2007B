# Cáritas Brigadas Médicas

Aplicación iPadOS para gestión de jornadas médicas móviles de **Cáritas** en comunidades rurales del Área Metropolitana de Monterrey, Nuevo León.

## Descripción

La app acompaña al equipo médico durante una jornada: desde configurar el día (ubicación, servicios disponibles, personal en turno) hasta registrar pacientes, capturar consultas y generar el expediente de cada persona atendida.

## Funcionalidades principales

- **Jornada del día** — configuración de municipio, servicios disponibles y personal asignado
- **Registro de pacientes** — wizard paso a paso con CURP opcional, datos personales, motivo de consulta, signos vitales, datos socioeconómicos y firma de aviso de privacidad
- **Expediente del paciente** — historial de consultas, medicamentos activos, datos clínicos y línea de tiempo
- **Nueva consulta** — seguimiento para pacientes ya registrados; campos adaptativos por tipo de consulta (general, dental, optometría, entrega de medicamentos)
- **Personal médico** — alta, edición y baja de médicos, estudiantes y practicantes; CURP auto-generado a partir de los datos capturados
- **Dashboard** — resumen del día con conteo de pacientes, disponibilidad de servicios y últimos 5 atendidos
- **Historial** — lista completa de pacientes de la jornada con acceso al expediente
- **Estadísticas** — métricas de la brigada

## Stack técnico

| Elemento | Detalle |
|---|---|
| Lenguaje | Swift 5.9+ |
| UI | SwiftUI |
| Persistencia | SwiftData |
| Dependencias externas | Ninguna |
| Target | iPadOS 17+ |
| Orientación | Landscape (NavigationSplitView) |

## Estructura del proyecto

```
Reto/
└── Reto.xcodeproj
    └── Reto/               ← todo el código fuente
        ├── RetoApp.swift   ← ModelContainer y entry point
        ├── ContentView.swift
        ├── Colores.swift   ← design tokens (caritasPrimario, caritasAcento, ...)
        ├── *.swift         ← modelos SwiftData y vistas
        └── PDFExport.swift ← generación de PDF con ImageRenderer
```

## Cómo correr el proyecto

1. Abrir `Reto/Reto.xcodeproj` en Xcode
2. Seleccionar un simulador de iPad (se recomienda **iPad Pro 13-inch (M5)**)
3. Presionar ⌘R

```bash
# Build desde terminal
xcodebuild -project Reto/Reto.xcodeproj -scheme Reto \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

## Alcance geográfico

La app está enfocada en las 16 municipalidades del **Área Metropolitana de Monterrey (AMM)**, Nuevo León. Los pickers de ubicación reflejan este alcance.

## Equipo

Proyecto desarrollado como reto académico (TC2007B) en colaboración con Cáritas Monterrey.
