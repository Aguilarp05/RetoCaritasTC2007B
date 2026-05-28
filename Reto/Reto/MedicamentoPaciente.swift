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

    // Additional DB fields (maps to recetas table)
    var duracion: String?
    var notasMedicamento: String?
    var consulta: Consulta?

    init(
        nombre: String,
        indicacion: String,
        fechaInicio: Date,
        fechaFin: Date? = nil,
        duracion: String? = nil,
        notasMedicamento: String? = nil
    ) {
        self.idMedicamento = UUID()
        self.nombre = nombre
        self.indicacion = indicacion
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
        self.duracion = duracion
        self.notasMedicamento = notasMedicamento
    }

    var estaActivo: Bool {
        fechaFin == nil
    }
}
