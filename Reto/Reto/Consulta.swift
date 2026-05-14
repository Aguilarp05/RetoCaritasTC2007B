//
//  Consulta.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 04/05/26.
//

import Foundation
import SwiftData
enum TipoConsulta: String, Codable, CaseIterable, Identifiable {
    case consultaGeneral = "Consulta general"
    case entregaMedicamentos = "Entrega de medicamentos"
    case optometrista = "Optometrista"
    case dental = "Consulta dental"

    var id: String { rawValue }
}

@Model
class Consulta {
    var tipoConsulta: TipoConsulta
    var idConsulta: UUID
    var fecha: Date
    var lugar: String
    var motivo: String
    var diagnostico: String
    var notasMedico: String
    var medicamentos: [String]
    var procedimientos: [String]
    var medico: String

    init(
        tipoConsulta: TipoConsulta,
        fecha: Date,
        lugar: String,
        motivo: String,
        diagnostico: String,
        notasMedico: String,
        medicamentos: [String] = [],
        procedimientos: [String] = [],
        medico: String
    ) {
        self.idConsulta = UUID()
        self.tipoConsulta = tipoConsulta
        self.fecha = fecha
        self.lugar = lugar
        self.motivo = motivo
        self.diagnostico = diagnostico
        self.notasMedico = notasMedico
        self.medicamentos = medicamentos
        self.procedimientos = procedimientos
        self.medico = medico
    }
}


