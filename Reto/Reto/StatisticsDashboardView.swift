import SwiftUI

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
    let jornadas: Int
    let avgPerJornada: Int
    let communitiesVisited: Int

    let femalePercent: Int
    let malePercent: Int

    let ageGroups: [(String, Int)]
    let hourStats: [HourRangeStat]
    let diagnoses: [DiagnosisStat]
    let brigades: [BrigadeStat]
}

// MARK: - Datos de prueba

struct MockStatisticsProvider {
    let stats = DashboardStats(
        patientsToday: 32,
        jornadas: 1,
        avgPerJornada: 32,
        communitiesVisited: 1,
        femalePercent: 58,
        malePercent: 42,
        ageGroups: [
            ("0–17 años", 18),
            ("18–40 años", 31),
            ("41–60 años", 29),
            ("60+ años",  22)
        ],
        hourStats: [
            HourRangeStat(label: "8–9 am",   patients: 8),
            HourRangeStat(label: "9–10 am",  patients: 11),
            HourRangeStat(label: "10–11 am", patients: 7),
            HourRangeStat(label: "11–12 pm", patients: 4),
            HourRangeStat(label: "12–1 pm",  patients: 2)
        ],
        diagnoses: [
            DiagnosisStat(diagnosis: "Diabetes tipo 2",  count: 48),
            DiagnosisStat(diagnosis: "Hipertensión",      count: 38),
            DiagnosisStat(diagnosis: "Consulta general",  count: 34),
            DiagnosisStat(diagnosis: "Nutrición",         count: 25),
            DiagnosisStat(diagnosis: "Post-cirugía",      count: 16),
            DiagnosisStat(diagnosis: "Odontología",       count: 13)
        ],
        brigades: [
            BrigadeStat(brigade: "General",              count: 89),
            BrigadeStat(brigade: "Odontología",          count: 63),
            BrigadeStat(brigade: "Cirugía ambulatoria",  count: 44),
            BrigadeStat(brigade: "Nutrición y diabetes", count: 37),
            BrigadeStat(brigade: "Óptica",               count: 22),
            BrigadeStat(brigade: "Banco medicamentos",   count: 14)
        ]
    )
}

// MARK: - Vista principal

struct StatisticsDashboardView: View {
    private let provider = MockStatisticsProvider()

    @Environment(\.toggleSidebar) private var toggleSidebar

    @State private var pdfURL: URL?
    @State private var mostrarCompartir = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let stats = provider.stats

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // — Franja de encabezado —
                    HStack {
                        Button { toggleSidebar() } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundStyle(Color.caritasAzul)
                        }
                        .padding(.trailing, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estadísticas")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.caritasAzul)
                            Text("Brigadas de salud — Cáritas")
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        Spacer()
                        Button {
                            pdfURL = generarURLPDF(
                                EstadisticasPDFContentView(stats: stats),
                                nombre: "estadisticas_caritas"
                            )
                            if pdfURL != nil { mostrarCompartir = true }
                        } label: {
                            Label("Exportar PDF", systemImage: "arrow.down.doc")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.caritasPrimario)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.caritasSuave)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.caritasSuave)

                    Divider()

                    // — Cifras clave —
                    LazyVGrid(columns: summaryColumns(for: width), spacing: 0) {
                        statResumen(titulo: "Pacientes atendidos",   valor: "\(stats.patientsToday)",      subtitulo: "Hoy")
                        statResumen(titulo: "Jornadas realizadas",   valor: "\(stats.jornadas)",           subtitulo: "Jornada activa")
                        statResumen(titulo: "Promedio por jornada",  valor: "\(stats.avgPerJornada)",      subtitulo: "Pacientes")
                        statResumen(titulo: "Comunidades visitadas", valor: "\(stats.communitiesVisited)", subtitulo: "Activa")
                    }

                    Divider()

                    if width >= 900 {
                        HStack(alignment: .top, spacing: 0) {
                            graficaHoras(stats.hourStats)
                            Divider()
                            demografiaSeccion(stats)
                        }
                    } else {
                        graficaHoras(stats.hourStats)
                        Divider()
                        demografiaSeccion(stats)
                    }

                    Divider()

                    if width >= 900 {
                        HStack(alignment: .top, spacing: 0) {
                            listaRanked(titulo: "Diagnósticos más frecuentes",
                                        items: stats.diagnoses.map { ($0.diagnosis, $0.count) })
                            Divider()
                            listaRanked(titulo: "Pacientes por brigada",
                                        items: stats.brigades.map { ($0.brigade, $0.count) })
                        }
                    } else {
                        listaRanked(titulo: "Diagnósticos más frecuentes",
                                    items: stats.diagnoses.map { ($0.diagnosis, $0.count) })
                        Divider()
                        listaRanked(titulo: "Pacientes por brigada",
                                    items: stats.brigades.map { ($0.brigade, $0.count) })
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarCompartir) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Secciones internas

    private func statResumen(titulo: String, valor: String, subtitulo: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            Text(valor)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.caritasPrimario)
            Text(subtitulo)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func graficaHoras(_ datos: [HourRangeStat]) -> some View {
        let maxVal = datos.map(\.patients).max() ?? 1

        return VStack(alignment: .leading, spacing: 16) {
            Text("Pacientes por rango de hora")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris)
                .textCase(.uppercase)

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(datos) { stat in
                    VStack(spacing: 6) {
                        Text("\(stat.patients)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.caritasPrimario)
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.caritasPrimario)
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
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func demografiaSeccion(_ stats: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución por sexo y edad")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris)
                .textCase(.uppercase)

            HStack(spacing: 20) {
                bloqueDemo(titulo: "Femenino",  porcentaje: stats.femalePercent, total: 144, color: Color.caritasPrimario)
                bloqueDemo(titulo: "Masculino", porcentaje: stats.malePercent,   total: 104, color: Color.caritasAcento)
            }

            VStack(spacing: 10) {
                ForEach(stats.ageGroups, id: \.0) { group in
                    filaEdad(label: group.0, percent: group.1)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func bloqueDemo(titulo: String, porcentaje: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titulo)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            Text("\(porcentaje)%")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text("\(total) pacientes")
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
        }
    }

    private func filaEdad(label: String, percent: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
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
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.caritasAzul)
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func listaRanked(titulo: String, items: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris)
                .textCase(.uppercase)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        Text("\(i + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(i == 0 ? Color.caritasPrimario : Color.caritasGris)
                            .frame(width: 20)
                        Text(items[i].0)
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasAzul)
                            .lineLimit(1)
                        Spacer()
                        Text("\(items[i].1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.caritasPrimario)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)

                    if i < items.count - 1 {
                        Divider().padding(.leading, 24)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func summaryColumns(for width: CGFloat) -> [GridItem] {
        if width >= 1000 {
            return Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
        } else if width >= 600 {
            return Array(repeating: GridItem(.flexible(), spacing: 0), count: 2)
        } else {
            return [GridItem(.flexible())]
        }
    }
}

// MARK: - Contenido PDF de estadísticas

struct EstadisticasPDFContentView: View {
    let stats: DashboardStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFHeaderView(
                titulo: "Estadísticas de Jornada",
                subtitulo: "Brigadas de salud — Cáritas"
            )

            // Cifras clave
            PDFSectionView(titulo: "Resumen") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                    pdfStatItem(titulo: "Pacientes atendidos", valor: "\(stats.patientsToday)")
                    pdfStatItem(titulo: "Jornadas realizadas", valor: "\(stats.jornadas)")
                    pdfStatItem(titulo: "Promedio por jornada", valor: "\(stats.avgPerJornada)")
                    pdfStatItem(titulo: "Comunidades visitadas", valor: "\(stats.communitiesVisited)")
                }
                .padding(.bottom, 4)
            }

            // Gráfica de horas
            PDFSectionView(titulo: "Pacientes por rango de hora") {
                let maxVal = stats.hourStats.map(\.patients).max() ?? 1
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(stats.hourStats) { stat in
                        VStack(spacing: 4) {
                            Text("\(stat.patients)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.caritasPrimario)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.caritasPrimario)
                                .frame(height: max(6, 80 * CGFloat(stat.patients) / CGFloat(maxVal)))
                            Text(stat.label)
                                .font(.system(size: 8))
                                .foregroundStyle(Color.caritasGris)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            }

            // Diagnósticos y brigadas en dos columnas
            PDFSectionView(titulo: "Diagnósticos y brigadas") {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Diagnósticos más frecuentes")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 8)
                        ForEach(stats.diagnoses.prefix(5).indices, id: \.self) { i in
                            pdfRankedRow(rank: i + 1, nombre: stats.diagnoses[i].diagnosis, valor: stats.diagnoses[i].count)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle().fill(Color(.systemGray5)).frame(width: 0.5)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Pacientes por brigada")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 8)
                        ForEach(stats.brigades.prefix(5).indices, id: \.self) { i in
                            pdfRankedRow(rank: i + 1, nombre: stats.brigades[i].brigade, valor: stats.brigades[i].count)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, 4)
            }

            // Demografía
            PDFSectionView(titulo: "Distribución demográfica") {
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Femenino")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.caritasGris)
                        Text("\(stats.femalePercent)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.caritasPrimario)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Masculino")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.caritasGris)
                        Text("\(stats.malePercent)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.caritasAcento)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.ageGroups, id: \.0) { group in
                            HStack(spacing: 8) {
                                Text(group.0)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.caritasGris)
                                    .frame(width: 80, alignment: .leading)
                                Text("\(group.1)%")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.caritasAzul)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }

            // Pie de página
            HStack {
                Text("Generado por la app Cáritas")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.caritasGris)
                Spacer()
                Text(Date().formatted(.dateTime.day().month().year().hour().minute()))
                    .font(.system(size: 9))
                    .foregroundStyle(Color.caritasGris)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .frame(width: 595)
    }

    private func pdfStatItem(titulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valor)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.caritasPrimario)
            Text(titulo)
                .font(.system(size: 10))
                .foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pdfRankedRow(rank: Int, nombre: String, valor: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(rank == 1 ? Color.caritasPrimario : Color.caritasGris)
                .frame(width: 14)
            Text(nombre)
                .font(.system(size: 10))
                .foregroundStyle(Color.caritasAzul)
                .lineLimit(1)
            Spacer()
            Text("\(valor)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.caritasPrimario)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    StatisticsDashboardView()
}

#Preview("PDF") {
    ScrollView {
        EstadisticasPDFContentView(stats: MockStatisticsProvider().stats)
    }
}
