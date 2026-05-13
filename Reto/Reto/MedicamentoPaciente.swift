//
//  MedicamentoPaciente.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 13/05/26.
//
import Foundation
import SwiftData

@Model
class MedicamentoPaciente {
    var idMedicamento: UUID
    var nombre: String
    var indicacion: String
    var fechaInicio: Date
    var fechaFin: Date?

    init(
        nombre: String,
        indicacion: String,
        fechaInicio: Date,
        fechaFin: Date? = nil
    ) {
        self.idMedicamento = UUID()
        self.nombre = nombre
        self.indicacion = indicacion
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
    }

    var estaActivo: Bool {
        fechaFin == nil
    }
}
