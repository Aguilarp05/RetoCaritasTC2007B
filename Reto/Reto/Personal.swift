import Foundation
import SwiftData

@Model
class Personal {
    var idPersonal: UUID
    var curpPersonal: String          // Identificador principal — CURP (PK funcional)
    var nombrePersonal: String
    var apellidosPersonal: String
    var sexoPersonal: Sexo
    var especialidad: String
    var areasDeServicio: [String]
    var matricula: String?            // Cédula profesional — nil si es estudiante/practicante
    var esActivo: Bool
    var fechaCreacionPersonal: Date

    @Relationship(inverse: \Jornada.personal)
    var jornadas: [Jornada] = []

    @Relationship(deleteRule: .nullify)
    var consultas: [Consulta] = []

    init(
        curpPersonal: String,
        nombrePersonal: String,
        apellidosPersonal: String,
        sexoPersonal: Sexo,
        especialidad: String,
        areasDeServicio: [String] = [],
        matricula: String? = nil
    ) {
        self.idPersonal            = UUID()
        self.curpPersonal          = curpPersonal.uppercased().trimmingCharacters(in: .whitespaces)
        self.nombrePersonal        = nombrePersonal
        self.apellidosPersonal     = apellidosPersonal
        self.sexoPersonal          = sexoPersonal
        self.especialidad          = especialidad
        self.areasDeServicio       = areasDeServicio
        self.matricula             = (matricula?.trimmingCharacters(in: .whitespaces).isEmpty == false) ? matricula : nil
        self.esActivo              = true
        self.fechaCreacionPersonal = Date()
    }

    var nombreCompleto: String { "\(nombrePersonal) \(apellidosPersonal)" }
}
