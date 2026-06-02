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

// MARK: - Modo de apariencia (claro / oscuro / sistema)

enum AppearanceMode: String, CaseIterable {
    case sistema, claro, oscuro

    var colorScheme: ColorScheme? {
        switch self {
        case .sistema: return nil
        case .claro:   return .light
        case .oscuro:  return .dark
        }
    }

    var icono: String {
        switch self {
        case .sistema: return "circle.lefthalf.filled"
        case .claro:   return "sun.max.fill"
        case .oscuro:  return "moon.fill"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var syncVM = CaritasSyncVM()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.sistema.rawValue
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var mostrarConfigJornada = false
    @State private var seleccion: String = "dashboard"

    private var apariencia: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .sistema
    }

    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarMenuView(
                seleccion: $seleccion,
                jornadaActiva: jornadaActiva,
                onConfigurarJornada: { mostrarConfigJornada = true }
            )
            .environmentObject(syncVM)
        } detail: {
            Group {
                switch seleccion {
                case "nuevo":        NuevoPacienteView()
                case "historial":    HistorialJornadaView()
                case "estadisticas": StatisticsDashboardView()
                case "personal":     PersonalView()
                default:             DashboardView(onNuevaConsulta: { cambiarSeccion("nuevo") })
                }
            }
            .id(seleccion)
            .transition(.opacity)
        }
        .preferredColorScheme(apariencia.colorScheme)
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
        .task {
            syncVM.actualizarPendientes(context: modelContext)
        }
    }

    private func cambiarSeccion(_ nueva: String) {
        withAnimation(.easeInOut(duration: 0.22)) { seleccion = nueva }
    }
}

// MARK: - Sidebar menu

struct SidebarMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncVM: CaritasSyncVM
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.sistema.rawValue
    @Binding var seleccion: String
    let jornadaActiva: Jornada?
    let onConfigurarJornada: () -> Void

    @State private var confirmarCierre = false

    private let items: [(id: String, icono: String, label: String)] = [
        ("dashboard",    "square.grid.2x2.fill",          "Dashboard"),
        ("nuevo",        "person.badge.plus",              "Consulta"),
        ("historial",    "list.bullet.clipboard.fill",     "Historial"),
        ("estadisticas", "chart.bar.fill",                 "Estadísticas"),
        ("personal",     "person.2.badge.gearshape.fill",  "Personal médico"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            Image("Logotipo Cáritas de Monterrey, A.B.P.")
                .resizable()
                .scaledToFit()
                .frame(height: 72)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.bottom, 16)

            // Items de navegación
            VStack(spacing: 2) {
                ForEach(items, id: \.id) { item in
                    SidebarItemRow(id: item.id, icono: item.icono, label: item.label, seleccion: $seleccion)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Selector de apariencia
            appearanceSwitcher

            // Botón de sincronización
            Button {
                Task { await syncVM.sincronizar(context: modelContext) }
            } label: {
                HStack(spacing: 12) {
                    Group {
                        if syncVM.estaSincronizando {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.caritasSuaveFijo)
                        } else {
                            Image(systemName: syncVM.isOffline ? "wifi.slash" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(syncVM.isOffline ? "Sin conexión" : "Sincronizar")
                            .font(.subheadline).fontWeight(.medium)
                        if syncVM.isOffline {
                            Text("Los datos se guardan localmente")
                                .font(.caption2).opacity(0.7)
                        } else if let fecha = syncVM.ultimaSincronizacion {
                            Text("Última: \(fecha.formatted(.dateTime.hour().minute()))")
                                .font(.caption2).opacity(0.7)
                        } else if syncVM.pendientesSincronizacion > 0 {
                            Text(syncVM.desglosePendientes)
                                .font(.caption2).opacity(0.7)
                        }
                    }

                    Spacer()

                    if !syncVM.isOffline && syncVM.pendientesSincronizacion > 0 {
                        Text("\(syncVM.pendientesSincronizacion)")
                            .font(.caption2).fontWeight(.bold)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.caritasAcento)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(syncVM.isOffline ? Color.white.opacity(0.35) : Color.caritasSuaveFijo)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
            }
            .disabled(syncVM.isOffline || syncVM.estaSincronizando)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Separador inferior
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.bottom, 12)

            // Botón de jornada
            Button {
                if jornadaActiva != nil {
                    confirmarCierre = true
                } else {
                    onConfigurarJornada()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: jornadaActiva != nil ? "calendar.badge.checkmark" : "calendar.badge.plus")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(jornadaActiva != nil ? "Jornada activa" : "Configurar jornada")
                            .font(.subheadline).fontWeight(.medium)
                        if let j = jornadaActiva, let municipio = j.locacion?.municipio {
                            Text(municipio)
                                .font(.caption2)
                                .opacity(0.75)
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(jornadaActiva != nil ? .green : Color.caritasAcento)
                        .frame(width: 7, height: 7)
                }
                .foregroundStyle(jornadaActiva != nil ? Color.caritasPrimario : Color.caritasAcento)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill((jornadaActiva != nil ? Color.caritasPrimario : Color.caritasAcento).opacity(0.15))
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
            .confirmationDialog(
                "¿Cerrar la jornada de hoy?",
                isPresented: $confirmarCierre,
                titleVisibility: .visible
            ) {
                Button("Cerrar jornada", role: .destructive) {
                    cerrarJornada()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                if let j = jornadaActiva {
                    let lugar = [j.locacion?.comunidad, j.locacion?.municipio]
                        .compactMap { $0 }.joined(separator: ", ")
                    Text("Se registrará el cierre de la jornada en \(lugar).")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.caritasAzulFijo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Selector de apariencia

    private var appearanceSwitcher: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apariencia")
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.4))
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            HStack(spacing: 6) {
                ForEach(AppearanceMode.allCases, id: \.self) { modo in
                    let activo = appearanceMode == modo.rawValue
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appearanceMode = modo.rawValue
                        }
                    } label: {
                        Image(systemName: modo.icono)
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(activo ? Color.caritasAzulFijo : Color.white.opacity(0.55))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(activo ? Color.caritasSuaveFijo : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private func cerrarJornada() {
        guard let jornada = jornadaActiva else { return }
        jornada.horaFin = Date()
        try? modelContext.save()
    }
}

// MARK: - Fila de item del sidebar

struct SidebarItemRow: View {
    let id: String
    let icono: String
    let label: String
    @Binding var seleccion: String

    private var isSelected: Bool { seleccion == id }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { seleccion = id }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? Color.caritasPrimario : .white.opacity(0.5))
                    .frame(width: 22)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.caritasPrimario.opacity(0.18))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.caritasPrimario)
                                .frame(width: 3)
                                .padding(.vertical, 8)
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isSelected)
    }
}

// MARK: - Estilo de botón con realimentación táctil

/// Reduce ligeramente la escala al presionar — animación sutil para CTAs.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

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
