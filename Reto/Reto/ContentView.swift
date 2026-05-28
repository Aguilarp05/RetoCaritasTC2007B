//
//  ContentView.swift
//  Reto
//
//  Created by Juan Pablo Aguilar Varela on 08/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = CaritasSyncVM()

    @Environment(\.modelContext) private var modelContext
    @Query private var pacientes: [Paciente]

    private var pacienteDemo: Paciente {
        Paciente(
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
            municipio: "El Mezquital"
        )
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Pantallas demo") {
                    NavigationLink {
                        NuevoPacienteView()
                    } label: {
                        Label("Nuevo paciente", systemImage: "person.badge.plus")
                    }

                    NavigationLink {
                        ExpedientePacienteView(paciente: pacienteDemo)
                    } label: {
                        Label("Expediente demo", systemImage: "folder")
                    }

                    NavigationLink {
                        NuevaConsultaView(paciente: pacienteDemo)
                    } label: {
                        Label("Nueva consulta demo", systemImage: "stethoscope")
                    }

                    NavigationLink {
                        StatisticsDashboardView()
                    } label: {
                        Label("Estadísticas", systemImage: "chart.bar")
                    }
                }

                Section("Sincronización") {
                    Button {
                        Task {
                            await viewModel.syncPacientesFromServer(
                                context: modelContext
                            )
                        }
                    } label: {
                        Label(
                            "Sincronizar pacientes",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }

                    if !viewModel.mensajeError.isEmpty {
                        Text(viewModel.mensajeError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Pacientes de la BD") {
                    if pacientes.isEmpty {
                        Text("No hay pacientes sincronizados.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pacientes) { paciente in
                            NavigationLink {
                                ExpedientePacienteView(paciente: paciente)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(paciente.nombreCompleto)

                                    Text(paciente.caritasId)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reto")
        } detail: {
            VStack(spacing: 12) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.caritasPrimario)

                Text("Selecciona una pantalla")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("TEMPORAL")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Item.self,
                Paciente.self,
                Consulta.self,
                MedicamentoPaciente.self
            ],
            inMemory: true
        )
}
