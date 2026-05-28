import SwiftUI
import SwiftData

// MARK: - Sidebar toggle environment key

private struct SidebarToggleKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var toggleSidebar: () -> Void {
        get { self[SidebarToggleKey.self] }
        set { self[SidebarToggleKey.self] = newValue }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var mostrarConfigJornada = false

    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List {
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

                NavigationLink {
                    NuevoPacienteView()
                } label: {
                    Label("Nuevo paciente", systemImage: "person.badge.plus")
                }

                NavigationLink {
                    HistorialJornadaView()
                } label: {
                    Label("Historial", systemImage: "list.bullet.clipboard")
                }

                NavigationLink {
                    StatisticsDashboardView()
                } label: {
                    Label("Estadísticas", systemImage: "chart.bar")
                }

                NavigationLink {
                    PersonalView()
                } label: {
                    Label("Personal médico", systemImage: "person.2.badge.gearshape")
                }

                Divider()

                Button {
                    mostrarConfigJornada = true
                } label: {
                    Label(
                        jornadaActiva != nil ? "Jornada activa" : "Configurar jornada",
                        systemImage: jornadaActiva != nil ? "calendar.badge.checkmark" : "calendar.badge.plus"
                    )
                    .foregroundStyle(jornadaActiva != nil ? Color.caritasPrimario : Color.caritasAcento)
                }
            }
            .navigationTitle("Cáritas")
        } detail: {
            DashboardView()
        }
        .environment(\.toggleSidebar, {
            withAnimation {
                columnVisibility = columnVisibility == .all ? .detailOnly : .all
            }
        })
        .fullScreenCover(isPresented: $mostrarConfigJornada) {
            ConfigurarJornadaView()
        }
        .onChange(of: jornadas, initial: true) { _, _ in
            if jornadaActiva == nil && !mostrarConfigJornada {
                mostrarConfigJornada = true
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
                MedicamentoPaciente.self,
                Jornada.self,
                Locacion.self,
                Personal.self,
                ConsentimientoPrivacidad.self,
            ],
            inMemory: true
        )
}
