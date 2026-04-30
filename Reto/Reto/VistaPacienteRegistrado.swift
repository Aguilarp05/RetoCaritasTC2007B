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
    var body: some View {
        Text("Aquí va el historial de visitas")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.blue)    }
}

struct DatosClinicosPacienteView: View {
    var body: some View {
        Text("Aquí van los datos clínicos")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.blue)    }
}

struct MedicamentosPacienteView: View {
    var body: some View {
        Text("Aquí van los medicamentos")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.blue)    }
}

struct LineaTiempoPacienteView: View {
    var body: some View {
        Text("Aquí va la línea de tiempo")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.blue)    }
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

