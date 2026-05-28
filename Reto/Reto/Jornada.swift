//
//  Jornada.swift
//  Reto
//

import Foundation
import SwiftData

@Model
class Jornada {
    var idJornada: UUID
    var fecha: Date
    var horaInicio: Date
    var horaFin: Date?
    var serviciosDisponibles: [String]
    var personalNombres: [String]
    var createdAt: Date

    var locacion: Locacion?

    @Relationship
    var personal: [Personal] = []

    @Relationship(deleteRule: .nullify)
    var registrosClinicos: [Consulta] = []

    init(locacion: Locacion, fecha: Date = Date(), serviciosDisponibles: [String] = [], personalNombres: [String] = []) {
        self.idJornada              = UUID()
        self.locacion               = locacion
        self.fecha                  = fecha
        self.horaInicio             = Date()
        self.horaFin                = nil
        self.serviciosDisponibles   = serviciosDisponibles
        self.personalNombres        = personalNombres
        self.createdAt              = Date()
    }
}
