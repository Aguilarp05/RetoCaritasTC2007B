import SwiftUI
import SwiftData

struct DashboardView: View {

    var onNuevaConsulta: (() -> Void)? = nil
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]
    @Query(sort: \Paciente.fechaRegistro, order: .reverse) private var pacientes: [Paciente]

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    private var serviciosDelDia: [ServicioDashboard] {
        let activos = jornadaActiva?.serviciosDisponibles ?? []
        return [
            ServicioDashboard(
                nombre: "Consulta general", icono: "stethoscope",
                disponible: activos.contains("Consulta general"),
                atendidos: contarAtendidos(.consultaGeneral)),
            ServicioDashboard(
                nombre: "Consulta dental", icono: "mouth.fill",
                disponible: activos.contains("Consulta dental"),
                atendidos: contarAtendidos(.dental)),
            ServicioDashboard(
                nombre: "Optometrista", icono: "eye.fill",
                disponible: activos.contains("Optometrista"),
                atendidos: contarAtendidos(.optometrista)),
            ServicioDashboard(
                nombre: "Entrega de medicamentos", icono: "pills.fill",
                disponible: activos.contains("Entrega de medicamentos"),
                atendidos: contarAtendidos(.entregaMedicamentos)),
        ]
    }

    private var totalPacientes: Int {
        let hoy = Calendar.current.startOfDay(for: Date())
        return pacientes.filter { $0.fechaRegistro >= hoy }.count
    }

    private func contarAtendidos(_ tipo: TipoConsulta) -> Int {
        let hoy = Calendar.current.startOfDay(for: Date())
        return pacientes.filter { paciente in
            paciente.fechaRegistro >= hoy &&
            paciente.consultas.contains { $0.tipoConsulta == tipo }
        }.count
    }

    private var ultimosPacientes: [Paciente] {
        Array(pacientes.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Franja de jornada
                HStack(alignment: .top) {
                    Button { toggleSidebar() } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(Color.caritasAzul)
                    }
                    .padding(.trailing, 8)

                    if let jornada = jornadaActiva {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brigada de hoy")
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                            Text([jornada.locacion?.comunidad, jornada.locacion?.municipio]
                                    .compactMap { $0 }.joined(separator: ", "))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.caritasAzul)
                            Text(jornada.locacion?.estado ?? "")
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(jornada.fecha.formatted(.dateTime.day().month(.wide).year()))
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasAzul)
                            if !jornada.personalNombres.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.caritasPrimario)
                                    Text(jornada.personalNombres.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(Color.caritasGris)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sin brigada activa")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.caritasAzul)
                            Text("Configura la brigada para comenzar")
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.caritasSuave)

                Divider()

                // Total de pacientes + botón acceso rápido
                HStack(alignment: .center, spacing: 10) {
                    Text("\(totalPacientes)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasPrimario)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pacientes")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.caritasAzul)
                        Text("Atendidos hoy")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasGris)
                    }
                    Spacer()
                    Button {
                        onNuevaConsulta?()
                    } label: {
                        Label("Nueva consulta", systemImage: "plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.caritasAcento)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                Divider()

                // Encabezado de servicios
                Text("Servicios")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.caritasGris)
                    .textCase(.uppercase)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Filas de servicios
                ForEach(serviciosDelDia) { servicio in
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            Image(systemName: servicio.icono)
                                .font(.title3)
                                .foregroundStyle(servicio.disponible ? Color.caritasPrimario : Color.caritasGris)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(servicio.nombre)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(servicio.disponible ? Color.caritasAzul : Color.caritasGris)
                                Text("\(servicio.atendidos) paciente\(servicio.atendidos == 1 ? "" : "s") atendido\(servicio.atendidos == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasGris)
                            }

                            Spacer()

                            HStack(spacing: 5) {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(servicio.disponible ? .green : Color(.systemGray4))
                                Text(servicio.disponible ? "Disponible" : "No disponible")
                                    .font(.caption)
                                    .foregroundStyle(servicio.disponible ? .green : Color.caritasGris)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)

                        Divider()
                            .padding(.leading, 68)
                    }
                }

                // Últimos pacientes
                if !ultimosPacientes.isEmpty {
                    Divider()

                    Text("Últimos pacientes")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.caritasGris)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    ForEach(ultimosPacientes) { paciente in
                        VStack(spacing: 0) {
                            filaUltimoPaciente(paciente)
                            Divider()
                                .padding(.leading, 78)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Fila de último paciente (dashboard)

extension DashboardView {
    func filaUltimoPaciente(_ paciente: Paciente) -> some View {
        let consulta = paciente.consultas.sorted { $0.fecha > $1.fecha }.first
        let iniciales = paciente.nombreCompleto
            .split(separator: " ").prefix(2)
            .compactMap { $0.first }.map(String.init).joined().uppercased()

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.caritasSuave)
                    .frame(width: 42, height: 42)
                Text(iniciales)
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(Color.caritasPrimario)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(paciente.nombreCompleto)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(Color.caritasAzul)
                if let c = consulta {
                    HStack(spacing: 4) {
                        Text(c.tipoConsulta.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color.caritasPrimario)
                        if !c.medico.isEmpty {
                            Text("·")
                                .font(.caption).foregroundStyle(Color.caritasGris)
                            Text(c.medico)
                                .font(.caption).foregroundStyle(Color.caritasGris)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            Text(paciente.fechaRegistro, style: .time)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 13)
    }
}

struct ServicioDashboard: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
    let disponible: Bool
    let atendidos: Int
}

#Preview {
    DashboardView()
        .modelContainer(
            for: [Jornada.self, Locacion.self, Paciente.self, Consulta.self],
            inMemory: true
        )
}
