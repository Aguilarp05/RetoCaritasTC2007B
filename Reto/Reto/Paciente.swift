//
//  Paciente.swift
//  Reto
//
//  Created by Juan Pablo Aguilar Varela on 20/04/26.
//

import Foundation
import SwiftData

enum Sexo: String, Codable {
    case masculino
    case femenino
    case noDefinido = "no binario"
}

@Model
class Paciente {
    var idPaciente: UUID
    var primerNombre: String
    var segundoNombre: String?
    var primerApellido: String
    var segundoApellido: String?
    var curpPaciente: String?
    var fechaRegistro: Date
    var notas: String?
    var fechaNacimiento: Date
    var lugarNacimiento: String
    var caritasId: String
    var sexoPaciente: Sexo
    var telefono: String?
    var municipio: String?
    var estado: String?
    var nombreCompleto: String {
        [
            primerNombre,
            segundoNombre,
            primerApellido,
            segundoApellido
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
    var condicionesCronicas: [String]
    
    var fechaProximoSeguimiento: Date?
    var motivoProximoSeguimiento: String?

    var edad: Int {
        Calendar.current.dateComponents([.year], from: fechaNacimiento, to: Date()).year ?? 0
    }
    
    
    
    init (
    primerNombre: String,
    segundoNombre: String? = nil,
    primerApellido: String,
    segundoApellido: String? = nil,
    curpPaciente: String? = nil,
    notas: String? = nil,
    fechaNacimiento: Date,
    lugarNacimiento: String,
    caritasId: String,
    sexoPaciente: Sexo,
    telefono : String? = nil,
    estado : String? = nil ,
    municipio: String? = nil,
    condicionesCronicas : [String],
    fechaProximoSeguimiento: Date? = nil,
    motivoProximoSeguimiento: String? = nil

        
        
    ){
        self.idPaciente      = UUID()
        self.primerNombre    = primerNombre
        self.segundoNombre   = segundoNombre
        self.primerApellido  = primerApellido
        self.segundoApellido = segundoApellido
        self.curpPaciente    = curpPaciente
        self.fechaRegistro   = Date()
        self.notas           = notas
        self.fechaNacimiento = fechaNacimiento
        self.lugarNacimiento = lugarNacimiento
        self.caritasId       = caritasId
        self.sexoPaciente    = sexoPaciente
        self.telefono = telefono
        self.municipio = municipio
        self.estado = estado
        self.condicionesCronicas = condicionesCronicas
        self.fechaProximoSeguimiento = fechaProximoSeguimiento
        self.motivoProximoSeguimiento = motivoProximoSeguimiento

    }
    
}
