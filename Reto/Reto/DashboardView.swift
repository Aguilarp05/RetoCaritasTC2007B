//
//  DashboardView.swift
//  Reto
//
//  Created by Juan Pablo Aguilar Varela on 21/05/26.
//

import SwiftUI

struct DashboardView: View {

    // Datos fijos por ahora — se reemplazarán con la jornada real
    let comunidad = "Sierra Ventana"
    let municipio = "Monterrey"
    let estado = "Nuevo Leon"
    let fecha = Date()
    let personalEnTurno = ["Dra. Rosa Sánchez", "Dr. Jorge Ramírez"]

    let serviciosDisponibles = [
        ServicioDashboard(nombre: "Consulta general",       icono: "stethoscope",        disponible: true,  atendidos: 12),
        ServicioDashboard(nombre: "Dental",                 icono: "mouth.fill",         disponible: true,  atendidos: 5),
        ServicioDashboard(nombre: "Optometrista",           icono: "eye.fill",           disponible: false, atendidos: 0),
        ServicioDashboard(nombre: "Medicamentos",           icono: "pills.fill",         disponible: true,  atendidos: 8),
    ]

    var totalPacientes: Int {
        serviciosDisponibles.reduce(0) { $0 + $1.atendidos }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Banner jornada
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Jornada de hoy")
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                            Text("\(comunidad), \(municipio)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.caritasAzul)
                            Text(estado)
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(fecha.formatted(.dateTime.day().month(.wide).year()))
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasAzul)
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasPrimario)
                                Text(personalEnTurno.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasGris)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.caritasSuave)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Total pacientes
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total de pacientes hoy")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                        Text("\(totalPacientes)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.caritasPrimario)
                    }
                    Spacer()
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.caritasSuave)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 0.5))

                // Servicios
                Text("Servicios")
                    .font(.headline)
                    .foregroundStyle(Color.caritasAzul)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(serviciosDisponibles) { servicio in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: servicio.icono)
                                    .foregroundStyle(servicio.disponible ? Color.caritasPrimario : Color.caritasGris)
                                Spacer()
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(servicio.disponible ? Color.green : Color(.systemGray4))
                            }
                            Text(servicio.nombre)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(servicio.disponible ? Color.caritasAzul : Color.caritasGris)
                            Text("\(servicio.atendidos) pacientes")
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                        }
                        .padding(16)
                        .background(servicio.disponible ? Color.white : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(servicio.disponible ? Color.caritasPrimario.opacity(0.3) : Color(.systemGray4), lineWidth: 0.5)
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .colorScheme(.light)
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
}
