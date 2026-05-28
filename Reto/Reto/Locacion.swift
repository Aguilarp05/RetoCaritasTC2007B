//
//  Locacion.swift
//  Reto
//

import Foundation
import SwiftData

@Model
class Locacion {
    var idLocacion: UUID
    var estado: String
    var municipio: String
    var comunidad: String?
    var fechaCreacion: Date

    @Relationship(deleteRule: .nullify)
    var jornadas: [Jornada] = []

    init(estado: String, municipio: String, comunidad: String? = nil) {
        self.idLocacion   = UUID()
        self.estado       = estado
        self.municipio    = municipio
        self.comunidad    = comunidad
        self.fechaCreacion = Date()
    }
}
