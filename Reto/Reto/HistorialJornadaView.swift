import SwiftUI
import SwiftData

struct HistorialJornadaView: View {
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Environment(\.hideSidebar) private var hideSidebar
    @Query(sort: \Paciente.fechaRegistro, order: .reverse) private var todosLosPacientes: [Paciente]
    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]
    @State private var pacienteSeleccionado: Paciente?

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    private var pacientes: [Paciente] {
        guard let jornada = jornadaActiva else { return todosLosPacientes }
        let municipio = jornada.locacion?.municipio ?? ""
        return todosLosPacientes.filter { p in
            (!municipio.isEmpty && p.municipio == municipio) ||
            p.consultas.contains { $0.jornada?.idJornada == jornada.idJornada }
        }
    }

    // Pacientes agrupados por día de registro, más reciente primero
    private var pacientesPorFecha: [(fecha: Date, pacientes: [Paciente])] {
        let cal = Calendar.current
        let grupos = Dictionary(grouping: pacientes) { p in
            cal.startOfDay(for: p.fechaRegistro)
        }
        return grupos
            .sorted { $0.key > $1.key }
            .map { (fecha: $0.key, pacientes: $0.value.sorted { $0.fechaRegistro > $1.fechaRegistro }) }
    }

    private func etiquetaFecha(_ fecha: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(fecha)     { return "Hoy" }
        if cal.isDateInYesterday(fecha) { return "Ayer" }
        return fecha.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_MX")))
    }

    var body: some View {
        Group {
            if let paciente = pacienteSeleccionado {
                ExpedientePacienteView(
                    paciente: paciente,
                    onBack: { pacienteSeleccionado = nil }
                )
            } else {
                listaView
            }
        }
        .animation(.easeInOut(duration: 0.18), value: pacienteSeleccionado == nil)
    }

    // MARK: - Lista de pacientes

    private var listaView: some View {
        VStack(spacing: 0) {

            // Encabezado
            HStack {
                Button { toggleSidebar() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(Color.caritasAzul)
                }
                .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Historial")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasAzul)
                    let municipio = jornadaActiva?.locacion?.municipio ?? ""
                    Text(municipio.isEmpty ? "Todos los pacientes" : "Pacientes de \(municipio)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                }

                Spacer()

                Text("\(pacientes.count) paciente\(pacientes.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.caritasPrimario)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.caritasSuave)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.caritasSuave)

            Divider()

            if pacientes.isEmpty {
                estadoVacio
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(pacientesPorFecha, id: \.fecha) { grupo in

                            // Divisor de fecha
                            HStack(spacing: 10) {
                                Rectangle()
                                    .fill(Color.caritasGris.opacity(0.2))
                                    .frame(height: 1)
                                Text(etiquetaFecha(grupo.fecha))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.caritasGris)
                                    .fixedSize()
                                Rectangle()
                                    .fill(Color.caritasGris.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            ForEach(grupo.pacientes) { paciente in
                                Button {
                                    hideSidebar()
                                    pacienteSeleccionado = paciente
                                } label: {
                                    FilaPacienteHistorial(paciente: paciente)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, 94)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundStyle(Color.caritasGris.opacity(0.35))

            Text("Sin pacientes registrados")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.caritasAzul)

            Text("Los pacientes que registres durante la jornada aparecerán aquí.")
                .font(.subheadline)
                .foregroundStyle(Color.caritasGris)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Fila de paciente

struct FilaPacienteHistorial: View {
    let paciente: Paciente

    var body: some View {
        HStack(spacing: 16) {

            // Avatar con iniciales
            ZStack {
                Circle()
                    .fill(Color.caritasSuave)
                    .frame(width: 54, height: 54)
                Text(iniciales)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.caritasPrimario)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(paciente.nombreCompleto)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.caritasAzul)

                HStack(spacing: 5) {
                    if let condicion = paciente.condicionesCronicas.first {
                        Text(condicion)
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(paciente.fechaRegistro, style: .time)
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)

                if !paciente.consultas.isEmpty {
                    Text("\(paciente.consultas.count) consulta\(paciente.consultas.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.caritasPrimario)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.caritasGris.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var iniciales: String {
        paciente.nombreCompleto
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}

#Preview {
    HistorialJornadaView()
        .modelContainer(
            for: [Paciente.self, Consulta.self, MedicamentoPaciente.self],
            inMemory: true
        )
}
