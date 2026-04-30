//
//  VistaPacienteRegistrado.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 30/04/26.
//

import SwiftUI

enum SeccionExpediente: String, CaseIterable, Identifiable {
    case historial = "Historial"
    case datosClinicos = "Datos clínicos"
    case medicamentos = "Medicamentos"
    case lineaTiempo = "Línea de tiempo"

    var id: String { rawValue }
}

struct VisitaDemo: Identifiable {
    let id = UUID()
    let fecha: String
    let lugar: String
    let motivo: String
    let diagnostico: String
    let notasMedico: String
    let medicamentos: [String]
    let procedimientos: [String]
    let medico: String
}
struct EventoLineaTiempo: Identifiable {
    let id = UUID()
    let fecha: String
    let titulo: String
    let descripcion: String
    let tipo: TipoEventoLineaTiempo
}

enum TipoEventoLineaTiempo {
    case seguimiento
    case tratamiento
    case alerta
    case nota
    case inicio

    var color: Color {
        switch self {
        case .seguimiento:
            return .blue
        case .tratamiento:
            return .green
        case .alerta:
            return .orange
        case .nota:
            return .gray
        case .inicio:
            return .purple
        }
    }
}



struct VistaPacienteRegistrado: View {
    let paciente :Paciente
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "person.crop.circle.fill")

            Text(paciente.nombreCompleto)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(paciente.caritasId)

                        Text("Paciente activa")

                        Text("Datos personales")
                            .font(.headline)

                        FilaDatoPaciente(titulo: "Edad", valor: "\(paciente.edad) años")
                        FilaDatoPaciente(titulo: "Sexo", valor: paciente.sexoPaciente.rawValue)
                        FilaDatoPaciente(titulo: "Municipio", valor: paciente.municipio ?? "Sin municipio")
                        FilaDatoPaciente(titulo: "Estado", valor: paciente.estado ?? "Sin estado")
                        FilaDatoPaciente(titulo: "Contacto", valor: paciente.telefono ?? "-")

                        Text("Notas importantes")
                            .font(.headline)

                        Text(paciente.notas ?? "Sin notas registradas")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )

                        Text("Condiciones crónicas")
                            .font(.headline)
            
        }
        .padding(24)
        .frame(width: 320)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))


    }
}

struct FilaDatoPaciente: View {
    let titulo: String
    let valor: String

    var body: some View {
        HStack {
            Text(titulo)
                .foregroundStyle(.secondary)

            Spacer()

            Text(valor)
                .fontWeight(.semibold)
        }
    }
}

struct ExpedientePacienteView: View {
    let paciente: Paciente

    @State private var seccionSeleccionada: SeccionExpediente = .historial

    var body: some View {
        HStack(spacing: 0) {
            VistaPacienteRegistrado(paciente: paciente)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                Text("Expediente clínico")
                    .font(.title)
                    .fontWeight(.bold)

                Picker("Sección", selection: $seccionSeleccionada) {
                    ForEach(SeccionExpediente.allCases) { seccion in
                        Text(seccion.rawValue)
                            .tag(seccion)
                    }
                }
                .pickerStyle(.segmented)

                Text("Seleccionado: \(seccionSeleccionada.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.red)

                contenidoDeSeccion
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()
            }
            .padding(24)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
    }

    private var contenidoDeSeccion: some View {
        Group {
            switch seccionSeleccionada {
            case .historial:
                HistorialPacienteView()

            case .datosClinicos:
                DatosClinicosPacienteView()

            case .medicamentos:
                MedicamentosPacienteView()

            case .lineaTiempo:
                LineaTiempoPacienteView()
            }
        }
    }
}


    
struct HistorialPacienteView: View {
    let visitas: [VisitaDemo] = [
        VisitaDemo(
            fecha: "26 mar 2026",
            lugar: "El Mezquital",
            motivo: "Control rutinario · Glucosa 142",
            diagnostico: "Diabetes tipo 2 en control rutinario. Ligera mejoría.",
            notasMedico: "Ajuste de dosis. Dieta baja en carbohidratos.",
            medicamentos: ["Metformina 1000mg", "Vitamina D"],
            procedimientos: ["Toma de glucosa", "Nutrición"],
            medico: "Dra. Sánchez"
        ),
        VisitaDemo(
            fecha: "14 ene 2026",
            lugar: "El Mezquital",
            motivo: "Glucosa elevada · 178 mg/dL",
            diagnostico: "Glucosa elevada. Requiere seguimiento cercano.",
            notasMedico: "Se recomendó control nutricional y revisión de adherencia.",
            medicamentos: ["Metformina 850mg"],
            procedimientos: ["Toma de glucosa"],
            medico: "Dra. Sánchez"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("2026 — \(visitas.count) visitas")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(visitas) { visita in
                    TarjetaVisitaView(visita: visita)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct TarjetaVisitaView: View {
    let visita: VisitaDemo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(visita.fecha) — \(visita.lugar)")
                    .font(.headline)

                Spacer()

                Text(visita.motivo)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Diagnóstico")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(visita.diagnostico)
                .fontWeight(.semibold)

            Text("Notas del médico")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(visita.notasMedico)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medicamentos")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(visita.medicamentos, id: \.self) { medicamento in
                        Text(medicamento)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Procedimientos")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(visita.procedimientos, id: \.self) { procedimiento in
                        Text(procedimiento)
                    }
                }
            }

            Text("Médico")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(visita.medico)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct DatosClinicosPacienteView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    alignment: .leading,
                    spacing: 20
                ) {
                    DatoClinicoItem(titulo: "Tipo de sangre", valor: "O+")
                    DatoClinicoItem(titulo: "Peso", valor: "68 kg")
                    DatoClinicoItem(titulo: "Estatura", valor: "1.57 m")
                    DatoClinicoItem(titulo: "IMC", valor: "27.6 — Sobrepeso leve")
                }

                VStack(alignment: .leading, spacing: 16) {
                    DatoClinicoBloque(
                        titulo: "Alergias",
                        valor: "Penicilina (reacción cutánea severa)"
                    )

                    DatoClinicoBloque(
                        titulo: "Antecedentes familiares",
                        valor: "Madre con diabetes tipo 2. Padre con hipertensión."
                    )

                    DatoClinicoBloque(
                        titulo: "Antecedentes personales",
                        valor: "Diagnóstico de diabetes tipo 2 desde 2021. Sin cirugías previas. No fuma, no consume alcohol."
                    )

                    DatoClinicoBloque(
                        titulo: "Notas médicas recientes",
                        valor: "26 mar 2026: Ajuste de dosis. Dieta baja en carbohidratos.\n14 ene 2026: Glucosa elevada. Se recomendó control nutricional."
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DatoClinicoItem: View {
    let titulo: String
    let valor: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(valor)
                .font(.headline)
        }
    }
}

struct DatoClinicoBloque: View {
    let titulo: String
    let valor: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(valor)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


struct MedicamentosPacienteView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medicamentos activos")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    MedicamentoCardView(
                        nombre: "Metformina 1000mg",
                        indicacion: "1 tableta cada 12 hrs · Con alimentos",
                        estado: "Activo",
                        activo: true
                    )

                    MedicamentoCardView(
                        nombre: "Vitamina D 1000UI",
                        indicacion: "1 cápsula al día · Con desayuno",
                        estado: "Activo",
                        activo: true
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Anteriores")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    MedicamentoCardView(
                        nombre: "Metformina 850mg",
                        indicacion: "Ene 2026 — Mar 2026",
                        estado: "Suspendido",
                        activo: false
                    )

                    MedicamentoCardView(
                        nombre: "Metformina 500mg",
                        indicacion: "Mar 2024 — Mar 2025",
                        estado: "Suspendido",
                        activo: false
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}



struct MedicamentoCardView: View {
    let nombre: String
    let indicacion: String
    let estado: String
    let activo: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(nombre)
                    .font(.headline)

                Text(indicacion)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(estado)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(activo ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                .foregroundStyle(activo ? .green : .secondary)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct LineaTiempoPacienteView: View {
    let eventos: [EventoLineaTiempo] = [
        EventoLineaTiempo(
            fecha: "10 abr 2026",
            titulo: "Próximo seguimiento",
            descripcion: "Control de glucosa programado.",
            tipo: .seguimiento
        ),
        EventoLineaTiempo(
            fecha: "26 mar 2026",
            titulo: "Ajuste de dosis",
            descripcion: "Se ajustó tratamiento. Paciente con ligera mejoría.",
            tipo: .tratamiento
        ),
        EventoLineaTiempo(
            fecha: "14 ene 2026",
            titulo: "Glucosa elevada",
            descripcion: "Registro de 178 mg/dL. Se recomendó control nutricional.",
            tipo: .alerta
        ),
        EventoLineaTiempo(
            fecha: "03 nov 2025",
            titulo: "Evaluación nutricional",
            descripcion: "IMC 27.4. Se indicó seguimiento nutricional.",
            tipo: .nota
        ),
        EventoLineaTiempo(
            fecha: "Mar 2024",
            titulo: "Primera visita",
            descripcion: "Paciente ingresa al programa de seguimiento.",
            tipo: .inicio
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(eventos) { evento in
                    EventoLineaTiempoView(evento: evento)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EventoLineaTiempoView: View {
    let evento: EventoLineaTiempo

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(evento.tipo.color)
                    .frame(width: 14, height: 14)

                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(evento.fecha)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(evento.titulo)
                    .font(.headline)

                Text(evento.descripcion)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 24)
        }
    }
}






#Preview {
    ExpedientePacienteView(
        paciente: Paciente(
            primerNombre: "Lupita",
            primerApellido: "Torres",
            notas: "Alergia a penicilina. No administrar derivados.",
            fechaNacimiento: Calendar.current.date(
                from: DateComponents(year: 1992, month: 3, day: 12)
            )!,
            lugarNacimiento: "El Mezquital",
            caritasId: "C-003",
            sexoPaciente: .femenino,
            telefono: "618 234 5678",
            estado: "Durango",
            municipio: "El Mezquital",
            condicionesCronicas: [
                "Diabetes tipo 2",
                "Nutrición"
            ],
            fechaProximoSeguimiento: Calendar.current.date(
                from: DateComponents(year: 2026, month: 4, day: 10)
            ),
            motivoProximoSeguimiento: "Control glucosa"
        )
    )
}

