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
        sexoPaciente: Sexo
        
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
    }
    
}
