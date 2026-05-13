//
//  Consulta.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 04/05/26.
//

import Foundation
import SwiftData

@Model
class Consulta {
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

