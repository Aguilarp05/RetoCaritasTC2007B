import SwiftUI
import SwiftData

// MARK: - Modelos

struct HourRangeStat: Identifiable {
    let id = UUID()
    let label: String
    let hour: Int
    let patients: Int
}

struct DiagnosisStat: Identifiable {
    let id = UUID()
    let diagnosis: String
    let count: Int
}

struct BrigadeStat: Identifiable {
    let id = UUID()
    let brigade: String
    let count: Int
}

struct TendenciaBrigada: Identifiable {
    let id = UUID()
    let fecha: Date
    let label: String
    let pacientes: Int
}

enum PeriodoHistorial: String, CaseIterable {
    case semana = "Semana"
    case mes    = "Mes"
    case anio   = "Año"
    case todo   = "Todo"

    var diasAtras: Int? {
        switch self {
        case .semana: return 7
        case .mes:    return 30
        case .anio:   return 365
        case .todo:   return nil
        }
    }
}

struct DashboardStats {
    let patientsToday: Int
    let serviciosActivos: Int
    let horaInicio: String
    let femaleCount: Int
    let maleCount: Int
    let femalePercent: Int
    let malePercent: Int
    let ageGroups: [(String, Int)]
    let hourStats: [HourRangeStat]
    let diagnoses: [DiagnosisStat]
    let brigades: [BrigadeStat]
}

struct StatsZona {
    let municipio: String
    let totalBrigadas: Int
    let totalPacientesUnicos: Int
    let pacientesRecurrentes: Int
    let tendencia: [TendenciaBrigada]
    let diagnoses: [DiagnosisStat]
    let brigades: [BrigadeStat]
    let femaleCount: Int
    let maleCount: Int
    let femalePercent: Int
    let malePercent: Int
    let ageGroups: [(String, Int)]
}

// MARK: - Vista principal

struct StatisticsDashboardView: View {
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Query private var pacientes: [Paciente]
    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]

    @State private var tabSeleccionada: TabStats = .jornada
    @State private var periodoSeleccionado: PeriodoHistorial = .todo
    @State private var pdfURL: URL?
    @State private var mostrarCompartir = false

    enum TabStats { case jornada, zona }

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    // MARK: - Stats jornada actual

    private var stats: DashboardStats {
        let cal = Calendar.current
        let pacientesHoy = pacientes.filter { cal.isDateInToday($0.fechaRegistro) }

        let horaInicio: String = jornadaActiva.map {
            $0.fecha.formatted(.dateTime.hour().minute().locale(Locale(identifier: "es_MX")))
        } ?? "—"

        // Todos los datos de jornada actual filtrados a pacientesHoy
        let total     = pacientesHoy.count
        let femenino  = pacientesHoy.filter { $0.sexoPaciente == .femenino  }.count
        let masculino = pacientesHoy.filter { $0.sexoPaciente == .masculino }.count
        let femalePercent = total > 0 ? Int(Double(femenino)  / Double(total) * 100) : 0
        let malePercent   = total > 0 ? Int(Double(masculino) / Double(total) * 100) : 0

        let gruposEdad: [(String, Int)] = [
            ("0–17",  pacientesHoy.filter { $0.edad <= 17 }.count),
            ("18–40", pacientesHoy.filter { (18...40).contains($0.edad) }.count),
            ("41–60", pacientesHoy.filter { (41...60).contains($0.edad) }.count),
            ("60+",   pacientesHoy.filter { $0.edad > 60 }.count),
        ]
        let ageGroups = gruposEdad.map { ($0.0, total > 0 ? Int(Double($0.1) / Double(total) * 100) : 0) }

        var hourCounts: [Int: Int] = [:]
        for p in pacientesHoy {
            hourCounts[cal.component(.hour, from: p.fechaRegistro), default: 0] += 1
        }
        let startHour: Int = jornadaActiva.map { cal.component(.hour, from: $0.fecha) }
            ?? hourCounts.keys.min()
            ?? cal.component(.hour, from: Date())
        let endHour = max(cal.component(.hour, from: Date()), hourCounts.keys.max() ?? startHour)

        let hourStats = (startHour...max(startHour, endHour)).map { h -> HourRangeStat in
            let suffix  = h < 12 ? "am" : "pm"
            let display = h == 0 ? 12 : (h <= 12 ? h : h - 12)
            return HourRangeStat(label: "\(display)\(suffix)", hour: h, patients: hourCounts[h] ?? 0)
        }

        let consultasHoy = pacientesHoy.flatMap { $0.consultas }
        var diagCounts: [String: Int] = [:]
        for c in consultasHoy where !c.diagnostico.isEmpty { diagCounts[c.diagnostico, default: 0] += 1 }
        let diagnoses = diagCounts.sorted { $0.value > $1.value }.prefix(6)
            .map { DiagnosisStat(diagnosis: $0.key, count: $0.value) }

        var brigadeCounts: [String: Int] = [:]
        for c in consultasHoy { brigadeCounts[c.tipoConsulta.rawValue, default: 0] += 1 }
        let brigades = brigadeCounts.sorted { $0.value > $1.value }
            .map { BrigadeStat(brigade: $0.key, count: $0.value) }

        return DashboardStats(
            patientsToday:    pacientesHoy.count,
            serviciosActivos: jornadaActiva?.serviciosDisponibles.count ?? 0,
            horaInicio:       horaInicio,
            femaleCount:      femenino,
            maleCount:        masculino,
            femalePercent:    femalePercent,
            malePercent:      malePercent,
            ageGroups:        ageGroups,
            hourStats:        hourStats,
            diagnoses:        Array(diagnoses),
            brigades:         brigades
        )
    }

    // MARK: - Stats historial zona

    private var statsZona: StatsZona {
        let municipio = jornadaActiva?.locacion?.municipio ?? ""
        let cal = Calendar.current

        let fechaLimite: Date? = periodoSeleccionado.diasAtras.map {
            cal.date(byAdding: .day, value: -$0, to: Date()) ?? Date()
        }

        let jornadasZona = jornadas.filter { j in
            j.locacion?.municipio == municipio &&
            (fechaLimite == nil || j.fecha >= fechaLimite!)
        }
        let idsJornadasZona = Set(jornadasZona.map { $0.idJornada })

        let pacientesZona = pacientes.filter { p in
            p.consultas.contains { c in
                idsJornadasZona.contains(c.jornada?.idJornada ?? UUID())
            }
        }

        let recurrentes = pacientesZona.filter { p in
            p.consultas.filter { c in
                idsJornadasZona.contains(c.jornada?.idJornada ?? UUID())
            }.count > 1
        }.count

        let tendencia: [TendenciaBrigada] = jornadasZona
            .sorted { $0.fecha < $1.fecha }
            .map { j in
                let count = pacientes.filter { p in
                    p.consultas.contains { $0.jornada?.idJornada == j.idJornada }
                }.count
                let label = j.fecha.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_MX")))
                return TendenciaBrigada(fecha: j.fecha, label: label, pacientes: count)
            }

        let consultasZona = pacientesZona.flatMap { $0.consultas }.filter { c in
            idsJornadasZona.contains(c.jornada?.idJornada ?? UUID())
        }

        var diagCounts: [String: Int] = [:]
        for c in consultasZona where !c.diagnostico.isEmpty { diagCounts[c.diagnostico, default: 0] += 1 }
        let diagnoses = diagCounts.sorted { $0.value > $1.value }.prefix(6)
            .map { DiagnosisStat(diagnosis: $0.key, count: $0.value) }

        var brigadeCounts: [String: Int] = [:]
        for c in consultasZona { brigadeCounts[c.tipoConsulta.rawValue, default: 0] += 1 }
        let brigades = brigadeCounts.sorted { $0.value > $1.value }
            .map { BrigadeStat(brigade: $0.key, count: $0.value) }

        let total     = pacientesZona.count
        let femenino  = pacientesZona.filter { $0.sexoPaciente == .femenino  }.count
        let masculino = pacientesZona.filter { $0.sexoPaciente == .masculino }.count
        let femalePercent = total > 0 ? Int(Double(femenino)  / Double(total) * 100) : 0
        let malePercent   = total > 0 ? Int(Double(masculino) / Double(total) * 100) : 0

        let gruposEdad: [(String, Int)] = [
            ("0–17",  pacientesZona.filter { $0.edad <= 17 }.count),
            ("18–40", pacientesZona.filter { (18...40).contains($0.edad) }.count),
            ("41–60", pacientesZona.filter { (41...60).contains($0.edad) }.count),
            ("60+",   pacientesZona.filter { $0.edad > 60 }.count),
        ]
        let ageGroups = gruposEdad.map { ($0.0, total > 0 ? Int(Double($0.1) / Double(total) * 100) : 0) }

        return StatsZona(
            municipio:             municipio.isEmpty ? "Sin jornada activa" : municipio,
            totalBrigadas:         jornadasZona.count,
            totalPacientesUnicos:  total,
            pacientesRecurrentes:  recurrentes,
            tendencia:             tendencia,
            diagnoses:             Array(diagnoses),
            brigades:              brigades,
            femaleCount:           femenino,
            maleCount:             masculino,
            femalePercent:         femalePercent,
            malePercent:           malePercent,
            ageGroups:             ageGroups
        )
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let s = stats
            let z = statsZona

            VStack(spacing: 0) {

                // — Encabezado —
                HStack {
                    Button { toggleSidebar() } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(Color.caritasAzul)
                    }
                    .padding(.trailing, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estadísticas")
                            .font(.title2).fontWeight(.bold)
                            .foregroundStyle(Color.caritasAzul)
                        Text(tabSeleccionada == .jornada
                             ? "Brigada de hoy"
                             : "Historial · \(z.municipio)")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasGris)
                    }
                    Spacer()
                    if tabSeleccionada == .jornada {
                        Button {
                            pdfURL = generarURLPDF(
                                EstadisticasPDFContentView(stats: s),
                                nombre: "estadisticas_caritas"
                            )
                            if pdfURL != nil { mostrarCompartir = true }
                        } label: {
                            Label("Exportar PDF", systemImage: "arrow.down.doc")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(Color.caritasPrimario)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.caritasSuave)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.caritasSuave)

                // — Selector de pestañas —
                HStack(spacing: 0) {
                    tabBtn("Jornada actual", tab: .jornada)
                    tabBtn("Historial de la zona", tab: .zona)
                }
                .background(Color(.systemBackground))

                Divider()

                // — Contenido —
                ScrollView {
                    if tabSeleccionada == .jornada {
                        jornadaContent(s, width: width)
                    } else {
                        zonaContent(z, width: width)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarCompartir) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Tab selector

    @ViewBuilder
    private func tabBtn(_ titulo: String, tab: TabStats) -> some View {
        let activa = tabSeleccionada == tab
        Button { withAnimation(.easeInOut(duration: 0.2)) { tabSeleccionada = tab } } label: {
            VStack(spacing: 0) {
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(activa ? .semibold : .regular)
                    .foregroundStyle(activa ? Color.caritasPrimario : Color.caritasGris)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                Rectangle()
                    .fill(activa ? Color.caritasPrimario : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contenido: Jornada actual

    @ViewBuilder
    private func jornadaContent(_ s: DashboardStats, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            LazyVGrid(columns: summaryColumns(for: width, count: 3), spacing: 0) {
                statResumen(titulo: "Pacientes atendidos", valor: "\(s.patientsToday)",    subtitulo: "Hoy")
                statResumen(titulo: "Servicios activos",   valor: "\(s.serviciosActivos)", subtitulo: "En esta jornada")
                statResumen(titulo: "Inicio de jornada",   valor: s.horaInicio,            subtitulo: "Hora de apertura")
            }

            Divider()

            if width >= 900 {
                HStack(alignment: .top, spacing: 0) {
                    graficaHoras(s.hourStats)
                    Divider()
                    demografiaSeccion(femalePercent: s.femalePercent, femaleCount: s.femaleCount,
                                      malePercent: s.malePercent, maleCount: s.maleCount,
                                      ageGroups: s.ageGroups)
                }
            } else {
                graficaHoras(s.hourStats)
                Divider()
                demografiaSeccion(femalePercent: s.femalePercent, femaleCount: s.femaleCount,
                                  malePercent: s.malePercent, maleCount: s.maleCount,
                                  ageGroups: s.ageGroups)
            }

            Divider()

            if width >= 900 {
                HStack(alignment: .top, spacing: 0) {
                    listaRanked(titulo: "Diagnósticos más frecuentes",
                                items: s.diagnoses.map { ($0.diagnosis, $0.count) },
                                vacio: "Sin diagnósticos registrados aún")
                    Divider()
                    listaRanked(titulo: "Pacientes por tipo de servicio",
                                items: s.brigades.map { ($0.brigade, $0.count) },
                                vacio: "Sin consultas registradas aún")
                }
            } else {
                listaRanked(titulo: "Diagnósticos más frecuentes",
                            items: s.diagnoses.map { ($0.diagnosis, $0.count) },
                            vacio: "Sin diagnósticos registrados aún")
                Divider()
                listaRanked(titulo: "Pacientes por tipo de servicio",
                            items: s.brigades.map { ($0.brigade, $0.count) },
                            vacio: "Sin consultas registradas aún")
            }
        }
    }

    // MARK: - Contenido: Historial de la zona

    @ViewBuilder
    private func zonaContent(_ z: StatsZona, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Selector de período
            HStack {
                Text("Período")
                    .font(.caption).foregroundStyle(Color.caritasGris)
                Spacer()
                Picker("Período", selection: $periodoSeleccionado) {
                    ForEach(PeriodoHistorial.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
            .background(Color(.systemGroupedBackground))

            Divider()

            LazyVGrid(columns: summaryColumns(for: width, count: 3), spacing: 0) {
                statResumen(titulo: "Brigadas realizadas",    valor: "\(z.totalBrigadas)",         subtitulo: z.municipio)
                statResumen(titulo: "Pacientes únicos",       valor: "\(z.totalPacientesUnicos)",  subtitulo: "Histórico")
                statResumen(titulo: "Pacientes recurrentes",  valor: "\(z.pacientesRecurrentes)",  subtitulo: "Más de 1 consulta")
            }

            Divider()

            // Tendencia de pacientes por brigada
            VStack(alignment: .leading, spacing: 16) {
                Text("Pacientes por brigada")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Color.caritasGris).textCase(.uppercase)

                if z.tendencia.isEmpty {
                    Text("Sin brigadas registradas en esta zona")
                        .font(.subheadline).foregroundStyle(Color.caritasGris)
                } else {
                    let maxVal = z.tendencia.map(\.pacientes).max().flatMap { $0 > 0 ? $0 : nil } ?? 1
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 14) {
                            ForEach(z.tendencia) { brigada in
                                VStack(spacing: 6) {
                                    Text(brigada.pacientes > 0 ? "\(brigada.pacientes)" : "")
                                        .font(.caption2).fontWeight(.semibold)
                                        .foregroundStyle(Color.caritasPrimario)
                                    VStack {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(brigada.pacientes > 0 ? Color.caritasPrimario : Color(.systemGray5))
                                            .frame(height: max(8, 130 * CGFloat(brigada.pacientes) / CGFloat(maxVal)))
                                    }
                                    .frame(height: 130)
                                    Text(brigada.label)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.caritasGris)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 52)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 20)

            Divider()

            if width >= 900 {
                HStack(alignment: .top, spacing: 0) {
                    demografiaSeccion(femalePercent: z.femalePercent, femaleCount: z.femaleCount,
                                      malePercent: z.malePercent, maleCount: z.maleCount,
                                      ageGroups: z.ageGroups)
                    Divider()
                    listaRanked(titulo: "Perfil epidemiológico de la zona",
                                items: z.diagnoses.map { ($0.diagnosis, $0.count) },
                                vacio: "Sin diagnósticos registrados")
                }
            } else {
                demografiaSeccion(femalePercent: z.femalePercent, femaleCount: z.femaleCount,
                                  malePercent: z.malePercent, maleCount: z.maleCount,
                                  ageGroups: z.ageGroups)
                Divider()
                listaRanked(titulo: "Perfil epidemiológico de la zona",
                            items: z.diagnoses.map { ($0.diagnosis, $0.count) },
                            vacio: "Sin diagnósticos registrados")
            }

            Divider()

            listaRanked(titulo: "Servicios más solicitados en la zona",
                        items: z.brigades.map { ($0.brigade, $0.count) },
                        vacio: "Sin consultas registradas")
        }
    }

    // MARK: - Componentes compartidos

    private func statResumen(titulo: String, valor: String, subtitulo: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo).font(.caption).foregroundStyle(Color.caritasGris)
            Text(valor).font(.system(size: 36, weight: .bold)).foregroundStyle(Color.caritasPrimario)
            Text(subtitulo).font(.caption).foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func graficaHoras(_ datos: [HourRangeStat]) -> some View {
        let maxVal = datos.map(\.patients).max().flatMap { $0 > 0 ? $0 : nil } ?? 1
        return VStack(alignment: .leading, spacing: 16) {
            Text("Registros por hora — hoy")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris).textCase(.uppercase)
            if datos.isEmpty {
                Text("La jornada aún no tiene registros")
                    .font(.subheadline).foregroundStyle(Color.caritasGris)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 14) {
                        ForEach(datos) { stat in
                            let esActual = stat.hour == Calendar.current.component(.hour, from: Date())
                            VStack(spacing: 6) {
                                Text(stat.patients > 0 ? "\(stat.patients)" : "")
                                    .font(.caption2).fontWeight(.semibold)
                                    .foregroundStyle(Color.caritasPrimario)
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(esActual ? Color.caritasAcento : (stat.patients > 0 ? Color.caritasPrimario : Color(.systemGray5)))
                                        .frame(height: max(8, 130 * CGFloat(stat.patients) / CGFloat(maxVal)))
                                }
                                .frame(height: 130)
                                Text(stat.label)
                                    .font(.system(size: 10, weight: esActual ? .bold : .medium))
                                    .foregroundStyle(esActual ? Color.caritasAcento : Color.caritasGris)
                            }
                            .frame(width: 44)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func demografiaSeccion(femalePercent: Int, femaleCount: Int,
                                   malePercent: Int, maleCount: Int,
                                   ageGroups: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución por sexo y edad")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris).textCase(.uppercase)
            HStack(spacing: 20) {
                bloqueDemo(titulo: "Femenino",  porcentaje: femalePercent, total: femaleCount, color: Color.caritasPrimario)
                bloqueDemo(titulo: "Masculino", porcentaje: malePercent,   total: maleCount,   color: Color.caritasAcento)
            }
            VStack(spacing: 10) {
                ForEach(ageGroups, id: \.0) { filaEdad(label: $0.0, percent: $0.1) }
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func bloqueDemo(titulo: String, porcentaje: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titulo).font(.caption).foregroundStyle(Color.caritasGris)
            Text("\(porcentaje)%").font(.system(size: 28, weight: .bold)).foregroundStyle(color)
            Text("\(total) pacientes").font(.caption).foregroundStyle(Color.caritasGris)
        }
    }

    private func filaEdad(label: String, percent: Int) -> some View {
        HStack(spacing: 12) {
            Text(label).font(.caption).foregroundStyle(Color.caritasGris)
                .frame(width: 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule().fill(Color.caritasPrimario.opacity(0.75))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 8)
            Text("\(percent)%").font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasAzul).frame(width: 34, alignment: .trailing)
        }
    }

    private func listaRanked(titulo: String, items: [(String, Int)], vacio: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo).font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris).textCase(.uppercase)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 12)
            if items.isEmpty {
                Text(vacio).font(.subheadline).foregroundStyle(Color.caritasGris)
                    .padding(.horizontal, 24).padding(.bottom, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text("\(i + 1)").font(.caption).fontWeight(.bold)
                                .foregroundStyle(i == 0 ? Color.caritasPrimario : Color.caritasGris)
                                .frame(width: 20)
                            Text(items[i].0).font(.subheadline).foregroundStyle(Color.caritasAzul).lineLimit(1)
                            Spacer()
                            Text("\(items[i].1)").font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Color.caritasPrimario)
                        }
                        .padding(.horizontal, 24).padding(.vertical, 11)
                        if i < items.count - 1 { Divider().padding(.leading, 24) }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func summaryColumns(for width: CGFloat, count: Int) -> [GridItem] {
        let cols = width >= 800 ? count : min(count, 2)
        return Array(repeating: GridItem(.flexible(), spacing: 0), count: cols)
    }
}

// MARK: - PDF (jornada actual)

struct EstadisticasPDFContentView: View {
    let stats: DashboardStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFHeaderView(titulo: "Estadísticas de Jornada", subtitulo: "Brigadas de salud — Cáritas")

            PDFSectionView(titulo: "Resumen") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                    pdfStatItem(titulo: "Pacientes atendidos", valor: "\(stats.patientsToday)")
                    pdfStatItem(titulo: "Servicios activos",   valor: "\(stats.serviciosActivos)")
                    pdfStatItem(titulo: "Inicio de jornada",   valor: stats.horaInicio)
                }
                .padding(.bottom, 4)
            }

            PDFSectionView(titulo: "Registros por hora — hoy") {
                let maxVal = stats.hourStats.map(\.patients).max().flatMap { $0 > 0 ? $0 : nil } ?? 1
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(stats.hourStats) { stat in
                        VStack(spacing: 4) {
                            Text(stat.patients > 0 ? "\(stat.patients)" : "")
                                .font(.system(size: 9, weight: .bold)).foregroundStyle(Color.caritasPrimario)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stat.patients > 0 ? Color.caritasPrimario : Color(.systemGray5))
                                .frame(height: max(6, 80 * CGFloat(stat.patients) / CGFloat(maxVal)))
                            Text(stat.label).font(.system(size: 8)).foregroundStyle(Color.caritasGris)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
                .padding(.horizontal, 32).padding(.bottom, 12)
            }

            PDFSectionView(titulo: "Diagnósticos y servicios") {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Diagnósticos más frecuentes")
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 32).padding(.bottom, 8)
                        ForEach(stats.diagnoses.prefix(5).indices, id: \.self) { i in
                            pdfRankedRow(rank: i+1, nombre: stats.diagnoses[i].diagnosis, valor: stats.diagnoses[i].count)
                        }
                        if stats.diagnoses.isEmpty {
                            Text("Sin datos").font(.system(size: 10)).foregroundStyle(Color.caritasGris).padding(.horizontal, 32)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color(.systemGray5)).frame(width: 0.5)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Pacientes por tipo de servicio")
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 32).padding(.bottom, 8)
                        ForEach(stats.brigades.prefix(5).indices, id: \.self) { i in
                            pdfRankedRow(rank: i+1, nombre: stats.brigades[i].brigade, valor: stats.brigades[i].count)
                        }
                        if stats.brigades.isEmpty {
                            Text("Sin datos").font(.system(size: 10)).foregroundStyle(Color.caritasGris).padding(.horizontal, 32)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, 4)
            }

            PDFSectionView(titulo: "Distribución demográfica") {
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Femenino").font(.system(size: 10)).foregroundStyle(Color.caritasGris)
                        Text("\(stats.femalePercent)%").font(.system(size: 24, weight: .bold)).foregroundStyle(Color.caritasPrimario)
                        Text("\(stats.femaleCount) pacientes").font(.system(size: 9)).foregroundStyle(Color.caritasGris)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Masculino").font(.system(size: 10)).foregroundStyle(Color.caritasGris)
                        Text("\(stats.malePercent)%").font(.system(size: 24, weight: .bold)).foregroundStyle(Color.caritasAcento)
                        Text("\(stats.maleCount) pacientes").font(.system(size: 9)).foregroundStyle(Color.caritasGris)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.ageGroups, id: \.0) { group in
                            HStack(spacing: 8) {
                                Text(group.0).font(.system(size: 10)).foregroundStyle(Color.caritasGris).frame(width: 60, alignment: .leading)
                                Text("\(group.1)%").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.caritasAzul)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32).padding(.bottom, 16)
            }

            HStack {
                Text("Generado por la app Cáritas").font(.system(size: 9)).foregroundStyle(Color.caritasGris)
                Spacer()
                Text(Date().formatted(.dateTime.day().month().year().hour().minute())).font(.system(size: 9)).foregroundStyle(Color.caritasGris)
            }
            .padding(.horizontal, 32).padding(.vertical, 16)
        }
        .background(Color.white)
        .frame(width: 595)
    }

    private func pdfStatItem(titulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valor).font(.system(size: 28, weight: .bold)).foregroundStyle(Color.caritasPrimario)
            Text(titulo).font(.system(size: 10)).foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 32).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pdfRankedRow(rank: Int, nombre: String, valor: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)").font(.system(size: 9, weight: .bold))
                .foregroundStyle(rank == 1 ? Color.caritasPrimario : Color.caritasGris).frame(width: 14)
            Text(nombre).font(.system(size: 10)).foregroundStyle(Color.caritasAzul).lineLimit(1)
            Spacer()
            Text("\(valor)").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.caritasPrimario)
        }
        .padding(.horizontal, 32).padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    StatisticsDashboardView()
        .modelContainer(
            for: [Paciente.self, Consulta.self, Jornada.self, Locacion.self],
            inMemory: true
        )
}
