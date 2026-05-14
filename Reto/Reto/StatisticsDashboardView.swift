//
//  StatisticsDashboardView.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 14/05/26.
//

import SwiftUI

// MARK: - MODELS

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

// MARK: - MOCK PROVIDER

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
            ("60+ años", 22)
        ],
        hourStats: [
            HourRangeStat(label: "8–9 am", patients: 8),
            HourRangeStat(label: "9–10 am", patients: 11),
            HourRangeStat(label: "10–11 am", patients: 7),
            HourRangeStat(label: "11–12 pm", patients: 4),
            HourRangeStat(label: "12–1 pm", patients: 2)
        ],
        diagnoses: [
            DiagnosisStat(diagnosis: "Diabetes tipo 2", count: 48),
            DiagnosisStat(diagnosis: "Hipertensión", count: 38),
            DiagnosisStat(diagnosis: "Consulta general", count: 34),
            DiagnosisStat(diagnosis: "Nutrición", count: 25),
            DiagnosisStat(diagnosis: "Post-cirugía", count: 16),
            DiagnosisStat(diagnosis: "Odontología", count: 13)
        ],
        brigades: [
            BrigadeStat(brigade: "General", count: 89),
            BrigadeStat(brigade: "Odontología", count: 63),
            BrigadeStat(brigade: "Cirugía ambulatoria", count: 44),
            BrigadeStat(brigade: "Nutrición y diabetes", count: 37),
            BrigadeStat(brigade: "Óptica", count: 22),
            BrigadeStat(brigade: "Banco medicamentos", count: 14)
        ]
    )
}

// MARK: - MAIN VIEW

struct StatisticsDashboardView: View {
    private let provider = MockStatisticsProvider()
    private let maxContentWidth: CGFloat = 1240

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let stats = provider.stats

            ScrollView {
                VStack(spacing: 20) {
                    header

                    LazyVGrid(
                        columns: summaryColumns(for: width),
                        spacing: 16
                    ) {
                        StatCard(
                            title: "Pacientes atendidos",
                            value: "\(stats.patientsToday)",
                            subtitle: "Hoy"
                        )

                        StatCard(
                            title: "Jornadas realizadas",
                            value: "\(stats.jornadas)",
                            subtitle: "Jornada activa"
                        )

                        StatCard(
                            title: "Promedio por jornada",
                            value: "\(stats.avgPerJornada)",
                            subtitle: "Pacientes hoy"
                        )

                        StatCard(
                            title: "Comunidades visitadas",
                            value: "\(stats.communitiesVisited)",
                            subtitle: "Comunidad activa"
                        )
                    }

                    if width >= 900 {
                        HStack(alignment: .top, spacing: 16) {
                            HourChartCard(stats: stats.hourStats)
                            DemographicsCard(stats: stats)
                        }
                    } else {
                        VStack(spacing: 16) {
                            HourChartCard(stats: stats.hourStats)
                            DemographicsCard(stats: stats)
                        }
                    }

                    if width >= 900 {
                        HStack(alignment: .top, spacing: 16) {
                            RankedListCard(
                                title: "Diagnósticos más frecuentes",
                                items: stats.diagnoses.map { ($0.diagnosis, $0.count) }
                            )

                            RankedListCard(
                                title: "Pacientes por brigada",
                                items: stats.brigades.map { ($0.brigade, $0.count) }
                            )
                        }
                    } else {
                        VStack(spacing: 16) {
                            RankedListCard(
                                title: "Diagnósticos más frecuentes",
                                items: stats.diagnoses.map { ($0.diagnosis, $0.count) }
                            )

                            RankedListCard(
                                title: "Pacientes por brigada",
                                items: stats.brigades.map { ($0.brigade, $0.count) }
                            )
                        }
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.12),
                        Color(red: 0.08, green: 0.08, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estadísticas")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                Text("Brigadas de salud — Cáritas")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {
                // Aquí después puedes conectar exportación real
            } label: {
                Text("Exportar PDF")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
            }
        }
        .padding(.bottom, 4)
    }

    private func summaryColumns(for width: CGFloat) -> [GridItem] {
        if width >= 1200 {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
        } else if width >= 700 {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        } else {
            return [GridItem(.flexible())]
        }
    }
}

// MARK: - CARD VIEWS

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray)

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.green.opacity(0.8))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(16)
        .background(cardBackground)
    }
}

struct HourChartCard: View {
    let stats: [HourRangeStat]

    private var maxValue: Int {
        stats.map(\.patients).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pacientes por rango de hora")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(stats) { stat in
                    VStack(spacing: 8) {
                        VStack {
                            Spacer()

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.9))
                                .frame(height: barHeight(for: stat.patients))
                        }
                        .frame(height: 170)

                        Text(stat.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 70)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 290, alignment: .topLeading)
        .padding(16)
        .background(cardBackground)
    }

    private func barHeight(for value: Int) -> CGFloat {
        let maxBarHeight: CGFloat = 150
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(10, maxBarHeight * ratio)
    }
}

struct DemographicsCard: View {
    let stats: DashboardStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución por sexo y edad")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                demographicBlock(
                    title: "Femenino",
                    percent: stats.femalePercent,
                    patients: 144,
                    tint: .purple
                )

                demographicBlock(
                    title: "Masculino",
                    percent: stats.malePercent,
                    patients: 104,
                    tint: .green
                )
            }

            VStack(spacing: 12) {
                ForEach(stats.ageGroups, id: \.0) { group in
                    ageRow(label: group.0, percent: group.1)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 290, alignment: .topLeading)
        .padding(16)
        .background(cardBackground)
    }

    private func demographicBlock(title: String, percent: Int, patients: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray)

            Text("\(percent)%")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(tint)

            Text("\(patients) pacientes")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func ageRow(label: String, percent: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(Color.purple.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 10)

            Text("\(percent)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

struct RankedListCard: View {
    let title: String
    let items: [(String, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    RankedRow(
                        name: item.0,
                        value: item.1
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
        .padding(16)
        .background(cardBackground)
    }
}

struct RankedRow: View {
    let name: String
    let value: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray)
                .lineLimit(1)

            Spacer(minLength: 10)

            Text("\(value)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SHARED CARD BACKGROUND

private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18)
        .fill(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
}

// MARK: - PREVIEW

#Preview {
    StatisticsDashboardView()
}
