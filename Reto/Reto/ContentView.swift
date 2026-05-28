//
//  ContentView.swift
//  Reto
//
//  Created by Juan Pablo Aguilar Varela on 08/04/26.
//

/*import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        
        
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

*/
import SwiftUI
import SwiftData

struct ContentView: View {
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
    }

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    NuevoPacienteView()
                } label: {
                    Label("Nuevo paciente", systemImage: "person.badge.plus")
                }

                NavigationLink {
                    ExpedientePacienteView(paciente: pacienteDemo)
                } label: {
                    Label("Expediente del paciente", systemImage: "folder")
                }

                NavigationLink {
                    NuevaConsultaView(paciente: pacienteDemo)
                } label: {
                    Label("Nueva consulta demo", systemImage: "stethoscope")
                }
                NavigationLink {
                    StatisticsDashboardView()
                } label: {
                    Label("Estadisticas", systemImage: "chart.bar")
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

                Text("TEMPORAL ")
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

