//
//  PacienteDTO.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 21/05/26.
//

import Foundation
import Combine
struct PacienteDTO: Codable, Identifiable {
    let idPaciente: String
    let caritasId: String
    let primerNombrePaciente: String
    let segundoNombrePaciente: String?
    let primerApellido: String
    let segundoApellido: String?
    let curpPaciente: String?
    let fechaNacimientoPaciente: String
    let lugarNacimientoPaciente: String
    let sexoPaciente: String
    let domicilio: String?
    let colonia: String?
    let numIntegrantesFamilia: Int?
    let ingresosMensuales: Double?
    let gradoEstudios: String?
    let tieneImss: Bool?
    let notas: String?
    let fechaRegistroPaciente: String

    var id: String {
        idPaciente
    }

    enum CodingKeys: String, CodingKey {
        case idPaciente = "id_paciente"
        case caritasId = "caritas_id"
        case primerNombrePaciente = "primer_nombre_paciente"
        case segundoNombrePaciente = "segundo_nombre_paciente"
        case primerApellido = "primer_apellido"
        case segundoApellido = "segundo_apellido"
        case curpPaciente = "curp_paciente"
        case fechaNacimientoPaciente = "fecha_nacimiento_paciente"
        case lugarNacimientoPaciente = "lugar_nacimiento_paciente"
        case sexoPaciente = "sexo_paciente"
        case domicilio
        case colonia
        case numIntegrantesFamilia = "num_integrantes_familia"
        case ingresosMensuales = "ingresos_mensuales"
        case gradoEstudios = "grado_estudios"
        case tieneImss = "tiene_imss"
        case notas
        case fechaRegistroPaciente = "fecha_registro_paciente"
    }
}
