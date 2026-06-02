import SwiftUI
import SwiftData

// MARK: - Modelos

struct HourRangeStat: Identifiable {
    let id = UUID()
    let label: String
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

struct DashboardStats {
    let patientsToday: Int
    let jornadasHoy: Int
    let avgPerJornada: Int
    let communitiesVisited: Int

    let femaleCount: Int
    let maleCount: Int
    let femalePercent: Int
    let malePercent: Int

    let ageGroups: [(String, Int)]
    let hourStats: [HourRangeStat]
    let diagnoses: [DiagnosisStat]
    let brigades: [BrigadeStat]
}

// MARK: - Vista principal

struct StatisticsDashboardView: View {
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Query private var pacientes: [Paciente]
    @Query private var jornadas: [Jornada]
    @Query private var consultas: [Consulta]

    @State private var pdfURL: URL?
    @State private var mostrarCompartir = false

    private var stats: DashboardStats {
        let cal = Calendar.current

        let pacientesHoy = pacientes.filter { cal.isDateInToday($0.fechaRegistro) }
        let jornadasHoy  = jornadas.filter  { cal.isDateInToday($0.fecha) }
        let jornadasCount = jornadasHoy.count
        let avg = jornadasCount > 0 ? pacientesHoy.count / jornadasCount : pacientesHoy.count

        let comunidades = Set(jornadas.compactMap { $0.locacion?.municipio }).count

        let total    = pacientes.count
        let femenino = pacientes.filter { $0.sexoPaciente == .femenino  }.count
        let masculino = pacientes.filter { $0.sexoPaciente == .masculino }.count
        let femalePercent = total > 0 ? Int(Double(femenino)  / Double(total) * 100) : 0
        let malePercent   = total > 0 ? Int(Double(masculino) / Double(total) * 100) : 0

        let gruposEdad: [(String, Int)] = [
            ("0–17 años",  pacientes.filter { $0.edad <= 17 }.count),
            ("18–40 años", pacientes.filter { (18...40).contains($0.edad) }.count),
            ("41–60 años", pacientes.filter { (41...60).contains($0.edad) }.count),
            ("60+ años",   pacientes.filter { $0.edad > 60 }.count),
        ]
        let ageGroups = gruposEdad.map { ($0.0, total > 0 ? Int(Double($0.1) / Double(total) * 100) : 0) }

        var hourCounts: [Int: Int] = [:]
        for p in pacientesHoy {
            let h = cal.component(.hour, from: p.fechaRegistro)
            hourCounts[h, default: 0] += 1
        }
        let hourStats = (8...13).map { h -> HourRangeStat in
            let label: String
            if h < 12      { label = "\(h)–\(h + 1) am" }
            else if h == 12 { label = "12–1 pm" }
            else            { label = "\(h - 12)–\(h - 11) pm" }
            return HourRangeStat(label: label, patients: hourCounts[h] ?? 0)
        }

        var diagCounts: [String: Int] = [:]
        for c in consultas where !c.diagnostico.isEmpty {
            diagCounts[c.diagnostico, default: 0] += 1
        }
        let diagnoses = diagCounts.sorted { $0.value > $1.value }.prefix(6).map {
            DiagnosisStat(diagnosis: $0.key, count: $0.value)
        }

        var brigadeCounts: [String: Int] = [:]
        for c in consultas {
            brigadeCounts[c.tipoConsulta.rawValue, default: 0] += 1
        }
        let brigades = brigadeCounts.sorted { $0.value > $1.value }.map {
            BrigadeStat(brigade: $0.key, count: $0.value)
        }

        return DashboardStats(
            patientsToday:     pacientesHoy.count,
            jornadasHoy:       jornadasCount,
            avgPerJornada:     avg,
            communitiesVisited: comunidades,
            femaleCount:       femenino,
            maleCount:         masculino,
            femalePercent:     femalePercent,
            malePercent:       malePercent,
            ageGroups:         ageGroups,
            hourStats:         hourStats,
            diagnoses:         Array(diagnoses),
            brigades:          brigades
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let s = stats

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

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
                            Text("Brigadas de salud — Cáritas")
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        Spacer()
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
                    .padding(.horizontal, 24).padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.caritasSuave)

                    Divider()

                    // — Cifras clave —
                    LazyVGrid(columns: summaryColumns(for: width), spacing: 0) {
                        statResumen(titulo: "Pacientes atendidos",   valor: "\(s.patientsToday)",      subtitulo: "Hoy")
                        statResumen(titulo: "Jornadas realizadas",   valor: "\(s.jornadasHoy)",         subtitulo: "Hoy")
                        statResumen(titulo: "Promedio por jornada",  valor: "\(s.avgPerJornada)",       subtitulo: "Pacientes")
                        statResumen(titulo: "Comunidades visitadas", valor: "\(s.communitiesVisited)",  subtitulo: "Total")
                    }

                    Divider()

                    if width >= 900 {
                        HStack(alignment: .top, spacing: 0) {
                            graficaHoras(s.hourStats)
                            Divider()
                            demografiaSeccion(s)
                        }
                    } else {
                        graficaHoras(s.hourStats)
                        Divider()
                        demografiaSeccion(s)
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
            .background(Color(.systemBackground))
        }
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarCompartir) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Componentes

    private func statResumen(titulo: String, valor: String, subtitulo: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.caption).foregroundStyle(Color.caritasGris)
            Text(valor)
                .font(.system(size: 36, weight: .bold)).foregroundStyle(Color.caritasPrimario)
            Text(subtitulo)
                .font(.caption).foregroundStyle(Color.caritasGris)
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

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(datos) { stat in
                    VStack(spacing: 6) {
                        Text(stat.patients > 0 ? "\(stat.patients)" : "")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundStyle(Color.caritasPrimario)
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stat.patients > 0 ? Color.caritasPrimario : Color(.systemGray5))
                                .frame(height: max(8, 130 * CGFloat(stat.patients) / CGFloat(maxVal)))
                        }
                        .frame(height: 130)
                        Text(stat.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.caritasGris)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func demografiaSeccion(_ s: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución por sexo y edad")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris).textCase(.uppercase)

            HStack(spacing: 20) {
                bloqueDemo(titulo: "Femenino",  porcentaje: s.femalePercent, total: s.femaleCount,  color: Color.caritasPrimario)
                bloqueDemo(titulo: "Masculino", porcentaje: s.malePercent,   total: s.maleCount,    color: Color.caritasAcento)
            }

            VStack(spacing: 10) {
                ForEach(s.ageGroups, id: \.0) { group in
                    filaEdad(label: group.0, percent: group.1)
                }
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
            Text(label)
                .font(.caption).foregroundStyle(Color.caritasGris)
                .frame(width: 80, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(Color.caritasPrimario.opacity(0.75))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 8)
            Text("\(percent)%")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasAzul)
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func listaRanked(titulo: String, items: [(String, Int)], vacio: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris).textCase(.uppercase)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 12)

            if items.isEmpty {
                Text(vacio)
                    .font(.subheadline).foregroundStyle(Color.caritasGris)
                    .padding(.horizontal, 24).padding(.bottom, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text("\(i + 1)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(i == 0 ? Color.caritasPrimario : Color.caritasGris)
                                .frame(width: 20)
                            Text(items[i].0)
                                .font(.subheadline).foregroundStyle(Color.caritasAzul).lineLimit(1)
                            Spacer()
                            Text("\(items[i].1)")
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.caritasPrimario)
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

    private func summaryColumns(for width: CGFloat) -> [GridItem] {
        if width >= 1000 { return Array(repeating: GridItem(.flexible(), spacing: 0), count: 4) }
        else if width >= 600 { return Array(repeating: GridItem(.flexible(), spacing: 0), count: 2) }
        else { return [GridItem(.flexible())] }
    }
}

// MARK: - PDF

struct EstadisticasPDFContentView: View {
    let stats: DashboardStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFHeaderView(titulo: "Estadísticas de Jornada", subtitulo: "Brigadas de salud — Cáritas")

            PDFSectionView(titulo: "Resumen") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                    pdfStatItem(titulo: "Pacientes hoy",         valor: "\(stats.patientsToday)")
                    pdfStatItem(titulo: "Jornadas hoy",          valor: "\(stats.jornadasHoy)")
                    pdfStatItem(titulo: "Promedio por jornada",  valor: "\(stats.avgPerJornada)")
                    pdfStatItem(titulo: "Comunidades visitadas", valor: "\(stats.communitiesVisited)")
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
                            Text(stat.label)
                                .font(.system(size: 8)).foregroundStyle(Color.caritasGris)
                                .multilineTextAlignment(.center)
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
                            pdfRankedRow(rank: i + 1, nombre: stats.diagnoses[i].diagnosis, valor: stats.diagnoses[i].count)
                        }
                        if stats.diagnoses.isEmpty {
                            Text("Sin datos").font(.system(size: 10)).foregroundStyle(Color.caritasGris).padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color(.systemGray5)).frame(width: 0.5)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Pacientes por tipo de servicio")
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 32).padding(.bottom, 8)
                        ForEach(stats.brigades.prefix(5).indices, id: \.self) { i in
                            pdfRankedRow(rank: i + 1, nombre: stats.brigades[i].brigade, valor: stats.brigades[i].count)
                        }
                        if stats.brigades.isEmpty {
                            Text("Sin datos").font(.system(size: 10)).foregroundStyle(Color.caritasGris).padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                                Text(group.0).font(.system(size: 10)).foregroundStyle(Color.caritasGris).frame(width: 80, alignment: .leading)
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
