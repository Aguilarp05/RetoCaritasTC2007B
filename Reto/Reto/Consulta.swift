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

enum TipoPaciente: String, Codable, CaseIterable {
    case inicial     = "inicial"
    case subsecuente = "subsecuente"
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

    // Additional DB fields
    var tipoPaciente: TipoPaciente
    var folio: String?
    var peso: Double?
    var talla: Double?
    var perimetroAbdominal: Double?
    var presionArterial: String?
    var pulso: Int?
    var frecuenciaCardiaca: Int?
    var frecuenciaRespiratoria: Int?
    var servicioDentalRecibido: String?
    var diagnosticoOptometria: String?
    var medicamentosEntregados: String?
    var cantidadMedicamentos: Int?

    var recetasJSON: String = ""

    var jornada: Jornada?
    var personalMedico: Personal?
    var sincronizado: Bool?

    init(
        tipoConsulta: TipoConsulta,
        fecha: Date,
        lugar: String,
        motivo: String,
        diagnostico: String,
        notasMedico: String,
        medicamentos: [String] = [],
        procedimientos: [String] = [],
        medico: String,
        tipoPaciente: TipoPaciente = .inicial,
        folio: String? = nil,
        peso: Double? = nil,
        talla: Double? = nil,
        perimetroAbdominal: Double? = nil,
        presionArterial: String? = nil,
        pulso: Int? = nil,
        frecuenciaCardiaca: Int? = nil,
        frecuenciaRespiratoria: Int? = nil,
        servicioDentalRecibido: String? = nil,
        diagnosticoOptometria: String? = nil,
        medicamentosEntregados: String? = nil,
        cantidadMedicamentos: Int? = nil
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
        self.tipoPaciente = tipoPaciente
        self.folio = folio
        self.peso = peso
        self.talla = talla
        self.perimetroAbdominal = perimetroAbdominal
        self.presionArterial = presionArterial
        self.pulso = pulso
        self.frecuenciaCardiaca = frecuenciaCardiaca
        self.frecuenciaRespiratoria = frecuenciaRespiratoria
        self.servicioDentalRecibido = servicioDentalRecibido
        self.diagnosticoOptometria = diagnosticoOptometria
        self.medicamentosEntregados = medicamentosEntregados
        self.cantidadMedicamentos = cantidadMedicamentos
    }
}


