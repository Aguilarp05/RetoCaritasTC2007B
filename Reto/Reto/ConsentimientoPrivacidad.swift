//
//  ConsentimientoPrivacidad.swift
//  Reto
//

import Foundation
import SwiftData

@Model
class ConsentimientoPrivacidad {
    var idConsentimiento: UUID
    var nombreFirmante: String
    var fechaFirma: Date
    var acepta: Bool

    var paciente: Paciente?
    var sincronizado: Bool?

    init(paciente: Paciente, nombreFirmante: String, acepta: Bool = true) {
        self.idConsentimiento = UUID()
        self.nombreFirmante   = nombreFirmante
        self.fechaFirma       = Date()
        self.acepta           = acepta
        self.paciente         = paciente
    }
}
