import Foundation
import SwiftData
import SwiftUI
import Network
import Combine

// MARK: - DTOs Paciente

struct PacienteCreateDTO: Encodable {
    let caritasId: String
    let primerNombrePaciente: String
    let segundoNombrePaciente: String?
    let primerApellido: String
    let segundoApellido: String?
    let curpPaciente: String?
    let fechaNacimientoPaciente: String
    let lugarNacimientoPaciente: String
    let sexoPaciente: String
    let telefono: String?
    let municipio: String?
    let estado: String?
    let domicilio: String?
    let colonia: String?
    let numIntegrantesFamilia: Int?
    let ingresosMensuales: String?
    let gradoEstudios: String?
    let tieneImss: Bool
    let notas: String?
    let condicionesCronicas: [String]

    enum CodingKeys: String, CodingKey {
        case caritasId              = "caritas_id"
        case primerNombrePaciente   = "primer_nombre_paciente"
        case segundoNombrePaciente  = "segundo_nombre_paciente"
        case primerApellido         = "primer_apellido"
        case segundoApellido        = "segundo_apellido"
        case curpPaciente           = "curp_paciente"
        case fechaNacimientoPaciente = "fecha_nacimiento_paciente"
        case lugarNacimientoPaciente = "lugar_nacimiento_paciente"
        case sexoPaciente           = "sexo_paciente"
        case telefono, municipio, estado, domicilio, colonia
        case numIntegrantesFamilia  = "num_integrantes_familia"
        case ingresosMensuales      = "ingresos_mensuales"
        case gradoEstudios          = "grado_estudios"
        case tieneImss              = "tiene_imss"
        case notas
        case condicionesCronicas    = "condiciones_cronicas"
    }
}

struct PacienteOutDTO: Decodable {
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
    let telefono: String?
    let municipio: String?
    let estado: String?
    let domicilio: String?
    let colonia: String?
    let numIntegrantesFamilia: Int?
    let ingresosMensuales: String?
    let gradoEstudios: String?
    let tieneImss: Bool
    let notas: String?
    let condicionesCronicas: [String]

    enum CodingKeys: String, CodingKey {
        case idPaciente             = "id_paciente"
        case caritasId              = "caritas_id"
        case primerNombrePaciente   = "primer_nombre_paciente"
        case segundoNombrePaciente  = "segundo_nombre_paciente"
        case primerApellido         = "primer_apellido"
        case segundoApellido        = "segundo_apellido"
        case curpPaciente           = "curp_paciente"
        case fechaNacimientoPaciente = "fecha_nacimiento_paciente"
        case lugarNacimientoPaciente = "lugar_nacimiento_paciente"
        case sexoPaciente           = "sexo_paciente"
        case telefono, municipio, estado, domicilio, colonia
        case numIntegrantesFamilia  = "num_integrantes_familia"
        case ingresosMensuales      = "ingresos_mensuales"
        case gradoEstudios          = "grado_estudios"
        case tieneImss              = "tiene_imss"
        case notas
        case condicionesCronicas    = "condiciones_cronicas"
    }
}

// MARK: - DTOs Consulta (registros_clinicos)

struct ConsultaCreateDTO: Encodable {
    let idPaciente: String
    let idJornada: String?
    let idPersonal: String?
    let folio: String?
    let tipoServicio: String
    let tipoPaciente: String
    let lugar: String?
    let motivoConsulta: String?
    let diagnostico: String?
    let notasMedico: String?
    let peso: Double?
    let talla: Double?
    let perimetroAbdominal: Double?
    let presionArterial: String?
    let pulso: Int?
    let frecuenciaCardiaca: Int?
    let frecuenciaRespiratoria: Int?
    let servicioDentalRecibido: String?
    let diagnosticoOptometria: String?
    let medicamentosEntregados: String?
    let cantidadMedicamentos: Int?
    let procedimientos: [String]

    enum CodingKeys: String, CodingKey {
        case idPaciente             = "id_paciente"
        case idJornada              = "id_jornada"
        case idPersonal             = "id_personal"
        case folio
        case tipoServicio           = "tipo_servicio"
        case tipoPaciente           = "tipo_paciente"
        case lugar
        case motivoConsulta         = "motivo_consulta"
        case diagnostico
        case notasMedico            = "notas_medico"
        case peso, talla
        case perimetroAbdominal     = "perimetro_abdominal"
        case presionArterial        = "presion_arterial"
        case pulso
        case frecuenciaCardiaca     = "frecuencia_cardiaca"
        case frecuenciaRespiratoria = "frecuencia_respiratoria"
        case servicioDentalRecibido = "servicio_dental_recibido"
        case diagnosticoOptometria  = "diagnostico_optometria"
        case medicamentosEntregados = "medicamentos_entregados"
        case cantidadMedicamentos   = "cantidad_medicamentos"
        case procedimientos
    }
}

// MARK: - DTOs Personal

struct PersonalCreateDTO: Encodable {
    let idPersonal: String
    let curpPersonal: String
    let nombrePersonal: String
    let apellidosPersonal: String
    let sexoPersonal: String
    let especialidad: String
    let areasDeServicio: [String]
    let matricula: String?
    let esActivo: Bool

    enum CodingKeys: String, CodingKey {
        case idPersonal         = "id_personal"
        case curpPersonal       = "curp_personal"
        case nombrePersonal     = "nombre_personal"
        case apellidosPersonal  = "apellidos_personal"
        case sexoPersonal       = "sexo_personal"
        case especialidad
        case areasDeServicio    = "areas_de_servicio"
        case matricula
        case esActivo           = "es_activo"
    }
}

// MARK: - DTOs Jornada

struct JornadaCreateDTO: Encodable {
    let idJornada: String
    let idLocacion: String
    let fecha: String
    let horaInicio: String
    let horaFin: String?
    let serviciosDisponibles: [String]
    let estado: String
    let municipio: String
    let comunidad: String?
    let personalIds: [String]

    enum CodingKeys: String, CodingKey {
        case idJornada            = "id_jornada"
        case idLocacion           = "id_locacion"
        case fecha
        case horaInicio           = "hora_inicio"
        case horaFin              = "hora_fin"
        case serviciosDisponibles = "servicios_disponibles"
        case estado, municipio, comunidad
        case personalIds          = "personal_ids"
    }
}

// MARK: - Receta local (usado en Consulta.recetasJSON y en sync)

struct RecetaLocal: Codable {
    let nombre: String
    let dosis: String
    let duracion: String
    let notas: String?

    static func encode(_ meds: [MedicamentoTemporal]) -> String {
        let recetas = meds.map { RecetaLocal(nombre: $0.nombre, dosis: $0.dosisCompleta, duracion: $0.duracion, notas: $0.indicacion.isEmpty ? nil : $0.indicacion) }
        guard let data = try? JSONEncoder().encode(recetas) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func decode(_ json: String) -> [RecetaLocal] {
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([RecetaLocal].self, from: data)) ?? []
    }
}

// MARK: - DTOs Receta

struct RecetaCreateDTO: Encodable {
    let medicamento: String
    let dosis: String
    let duracion: String
    let notas: String?
}

struct ConsultaOutDTO: Decodable {
    let idRegistro: String
    enum CodingKeys: String, CodingKey {
        case idRegistro = "id_registro"
    }
}

// MARK: - DTOs Consentimiento

struct ConsentimientoCreateDTO: Encodable {
    let idConsentimiento: String
    let idPaciente: String
    let nombreFirmante: String
    let fechaFirma: String
    let acepta: Bool

    enum CodingKeys: String, CodingKey {
        case idConsentimiento = "id_consentimiento"
        case idPaciente       = "id_paciente"
        case nombreFirmante   = "nombre_firmante"
        case fechaFirma       = "fecha_firma"
        case acepta
    }
}

// MARK: - DTOs Medicamento (medicamentos_paciente)

struct MedicamentoCreateDTO: Encodable {
    let idPaciente: String
    let nombre: String
    let indicacion: String
    let fechaInicio: String
    let fechaFin: String?
    let duracion: String?
    let notas: String?

    enum CodingKeys: String, CodingKey {
        case idPaciente = "id_paciente"
        case nombre, indicacion
        case fechaInicio = "fecha_inicio"
        case fechaFin    = "fecha_fin"
        case duracion, notas
    }
}

// MARK: - ViewModel

@MainActor
class CaritasSyncVM: ObservableObject {
    @Published var isOffline: Bool = true
    @Published var estaSincronizando: Bool = false
    @Published var pendientesSincronizacion: Int = 0
    @Published var desglosePendientes: String = ""
    @Published var mensajeError: String = ""
    @Published var ultimaSincronizacion: Date? = nil

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "dev.caritas.network")
    private let baseURL = "http://10.14.255.97:8001"

    private let fechaFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withTimeZone]
        return f
    }()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit { monitor.cancel() }

    // MARK: - Sync principal

    func sincronizar(context: ModelContext) async {
        guard !isOffline, !estaSincronizando else {
            if isOffline { mensajeError = "Sin conexión. Los datos se guardan localmente." }
            return
        }
        estaSincronizando = true
        mensajeError = ""
        defer { estaSincronizando = false }

        // 1. Subir personal y jornadas primero (consultas los referencian)
        await subirPersonalLocal(context: context)
        await subirJornadasLocales(context: context)

        // 2. Subir pacientes nuevos
        await subirPacientesLocales(context: context)

        // 3. Descargar pacientes del servidor → devuelve mapa caritasId → serverUUID
        let caritasIdMap = await descargarPacientesDelServidor(context: context)

        // 4. Subir consultas, medicamentos y consentimientos usando el mapa de IDs
        await subirConsultasLocales(context: context, caritasIdMap: caritasIdMap)
        await subirMedicamentosLocales(context: context, caritasIdMap: caritasIdMap)
        await subirConsentimientosLocales(context: context, caritasIdMap: caritasIdMap)

        actualizarPendientes(context: context)
        if mensajeError.isEmpty { ultimaSincronizacion = Date() }
    }

    // MARK: - Personal: subida

    func subirPersonalLocal(context: ModelContext) async {
        guard let url = URL(string: "\(baseURL)/personal") else { return }
        let todos = (try? context.fetch(FetchDescriptor<Personal>()))?.filter { $0.sincronizado != true } ?? []

        for persona in todos {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(personalACreateDTO(persona))
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    persona.sincronizado = true
                }
            } catch {
                print("Error personal \(persona.curpPersonal): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Jornadas: subida

    func subirJornadasLocales(context: ModelContext) async {
        guard let url = URL(string: "\(baseURL)/jornadas") else { return }
        let pendientes = (try? context.fetch(FetchDescriptor<Jornada>()))?.filter { $0.sincronizado != true } ?? []

        for jornada in pendientes {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(jornadaACreateDTO(jornada))
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    jornada.sincronizado = true
                }
            } catch {
                print("Error jornada \(jornada.idJornada): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Pacientes: subida

    func subirPacientesLocales(context: ModelContext) async {
        guard let url = URL(string: "\(baseURL)/pacientes") else { return }
        let pendientes = (try? context.fetch(FetchDescriptor<Paciente>()))?.filter { $0.sincronizado != true } ?? []

        for paciente in pendientes {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(pacienteACreateDTO(paciente))
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    paciente.sincronizado = true
                }
            } catch {
                print("Error paciente \(paciente.caritasId): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Pacientes: descarga → devuelve caritasId → serverUUID

    @discardableResult
    func descargarPacientesDelServidor(context: ModelContext) async -> [String: String] {
        guard let url = URL(string: "\(baseURL)/pacientes") else { return [:] }
        var caritasIdMap: [String: String] = [:]

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let dtos = try JSONDecoder().decode([PacienteOutDTO].self, from: data)

            let existentes = try context.fetch(FetchDescriptor<Paciente>())
            let caritasIdsLocales = Set(existentes.map { $0.caritasId })

            for dto in dtos {
                caritasIdMap[dto.caritasId] = dto.idPaciente
                if !caritasIdsLocales.contains(dto.caritasId) {
                    let paciente = outDTOaPaciente(dto)
                    paciente.sincronizado = true
                    context.insert(paciente)
                }
            }
            try context.save()
        } catch {
            mensajeError = "Error al descargar pacientes: \(error.localizedDescription)"
        }
        return caritasIdMap
    }

    // MARK: - Consultas: subida

    func subirConsultasLocales(context: ModelContext, caritasIdMap: [String: String]) async {
        guard let url = URL(string: "\(baseURL)/registros-clinicos") else { return }
        let pendientes = (try? context.fetch(FetchDescriptor<Consulta>()))?.filter { $0.sincronizado != true } ?? []

        for consulta in pendientes {
            do {
                guard let paciente = try? context.fetch(FetchDescriptor<Paciente>())
                    .first(where: { $0.consultas.contains(where: { $0.idConsulta == consulta.idConsulta }) })
                else { print("Error \(consulta.idConsulta): paciente no encontrado"); continue }

                guard let serverIdPaciente = caritasIdMap[paciente.caritasId]
                else { print("Error \(consulta.idConsulta): caritasId '\(paciente.caritasId)' no en mapa"); continue }

                let idJornada  = consulta.jornada?.idJornada.uuidString
                let idPersonal = consulta.personalMedico?.idPersonal.uuidString

                let dto = consultaACreateDTO(consulta, idPaciente: serverIdPaciente,
                                             idJornada: idJornada, idPersonal: idPersonal)
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(dto)
                request.timeoutInterval = 10

                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    consulta.sincronizado = true
                    if let outDTO = try? JSONDecoder().decode(ConsultaOutDTO.self, from: data) {
                        await subirRecetas(consulta, idRegistro: outDTO.idRegistro)
                    }
                }
            } catch {
                print("Error consulta \(consulta.idConsulta): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Recetas: subida

    private func subirRecetas(_ consulta: Consulta, idRegistro: String) async {
        let recetas = RecetaLocal.decode(consulta.recetasJSON)
        guard !recetas.isEmpty,
              let url = URL(string: "\(baseURL)/registros-clinicos/\(idRegistro)/recetas") else { return }

        for receta in recetas {
            do {
                let dto = RecetaCreateDTO(medicamento: receta.nombre, dosis: receta.dosis,
                                         duracion: receta.duracion, notas: receta.notas)
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(dto)
                request.timeoutInterval = 10
                let (_, _) = try await URLSession.shared.data(for: request)
            } catch {
                print("Error receta '\(receta.nombre)': \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Medicamentos: subida

    func subirMedicamentosLocales(context: ModelContext, caritasIdMap: [String: String]) async {
        guard let url = URL(string: "\(baseURL)/medicamentos-paciente") else { return }
        let pendientes = (try? context.fetch(FetchDescriptor<MedicamentoPaciente>()))?.filter { $0.sincronizado != true } ?? []

        for med in pendientes {
            do {
                guard let paciente = try? context.fetch(FetchDescriptor<Paciente>())
                    .first(where: { $0.medicamentos.contains(where: { $0.idMedicamento == med.idMedicamento }) }),
                      let serverIdPaciente = caritasIdMap[paciente.caritasId]
                else { continue }

                let dto = MedicamentoCreateDTO(
                    idPaciente:  serverIdPaciente,
                    nombre:      med.nombre,
                    indicacion:  med.indicacion,
                    fechaInicio: fechaFormatter.string(from: med.fechaInicio),
                    fechaFin:    med.fechaFin.map { fechaFormatter.string(from: $0) },
                    duracion:    med.duracion,
                    notas:       med.notasMedicamento
                )
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(dto)
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    med.sincronizado = true
                }
            } catch {
                print("Error medicamento \(med.idMedicamento): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Consentimientos: subida

    func subirConsentimientosLocales(context: ModelContext, caritasIdMap: [String: String]) async {
        guard let url = URL(string: "\(baseURL)/consentimientos") else { return }
        let pendientes = (try? context.fetch(FetchDescriptor<ConsentimientoPrivacidad>()))?.filter { $0.sincronizado != true } ?? []

        for consentimiento in pendientes {
            do {
                guard let paciente = consentimiento.paciente,
                      let serverIdPaciente = caritasIdMap[paciente.caritasId]
                else { print("Error consentimiento \(consentimiento.idConsentimiento): paciente no encontrado"); continue }

                let dto = ConsentimientoCreateDTO(
                    idConsentimiento: consentimiento.idConsentimiento.uuidString,
                    idPaciente:       serverIdPaciente,
                    nombreFirmante:   consentimiento.nombreFirmante,
                    fechaFirma:       isoFormatter.string(from: consentimiento.fechaFirma),
                    acepta:           consentimiento.acepta
                )
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(dto)
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...201).contains(http.statusCode) || http.statusCode == 409 {
                    consentimiento.sincronizado = true
                }
            } catch {
                print("Error consentimiento \(consentimiento.idConsentimiento): \(error.localizedDescription)")
            }
        }
        try? context.save()
    }

    // MARK: - Contar pendientes

    func actualizarPendientes(context: ModelContext) {
        let pacientes        = (try? context.fetch(FetchDescriptor<Paciente>())) ?? []
        let consultas        = (try? context.fetch(FetchDescriptor<Consulta>())) ?? []
        let medicamentos     = (try? context.fetch(FetchDescriptor<MedicamentoPaciente>())) ?? []
        let personal         = (try? context.fetch(FetchDescriptor<Personal>())) ?? []
        let jornadas         = (try? context.fetch(FetchDescriptor<Jornada>())) ?? []
        let consentimientos  = (try? context.fetch(FetchDescriptor<ConsentimientoPrivacidad>())) ?? []

        let p  = pacientes.filter       { $0.sincronizado != true }.count
        let c  = consultas.filter       { $0.sincronizado != true }.count
        let m  = medicamentos.filter    { $0.sincronizado != true }.count
        let pe = personal.filter        { $0.sincronizado != true }.count
        let j  = jornadas.filter        { $0.sincronizado != true }.count
        let co = consentimientos.filter { $0.sincronizado != true }.count

        pendientesSincronizacion = p + c + m + pe + j + co
        desglosePendientes = "Pacientes: \(p) · Consultas: \(c) · Medicamentos: \(m) · Personal: \(pe) · Jornadas: \(j) · Consentimientos: \(co)"
        print("Pendientes — \(desglosePendientes)")
    }

    // MARK: - Conversiones Personal / Jornada

    private func personalACreateDTO(_ p: Personal) -> PersonalCreateDTO {
        PersonalCreateDTO(
            idPersonal:        p.idPersonal.uuidString,
            curpPersonal:      p.curpPersonal,
            nombrePersonal:    p.nombrePersonal,
            apellidosPersonal: p.apellidosPersonal,
            sexoPersonal:      sexoParaServidor(p.sexoPersonal),
            especialidad:      p.especialidad,
            areasDeServicio:   p.areasDeServicio,
            matricula:         p.matricula,
            esActivo:          p.esActivo
        )
    }

    private func jornadaACreateDTO(_ j: Jornada) -> JornadaCreateDTO {
        JornadaCreateDTO(
            idJornada:            j.idJornada.uuidString,
            idLocacion:           j.locacion?.idLocacion.uuidString ?? UUID().uuidString,
            fecha:                fechaFormatter.string(from: j.fecha),
            horaInicio:           isoFormatter.string(from: j.horaInicio),
            horaFin:              j.horaFin.map { isoFormatter.string(from: $0) },
            serviciosDisponibles: j.serviciosDisponibles,
            estado:               j.locacion?.estado ?? "Nuevo León",
            municipio:            j.locacion?.municipio ?? "",
            comunidad:            j.locacion?.comunidad,
            personalIds:          j.personal.map { $0.idPersonal.uuidString }
        )
    }

    // MARK: - Conversiones Paciente

    private func pacienteACreateDTO(_ p: Paciente) -> PacienteCreateDTO {
        PacienteCreateDTO(
            caritasId:               p.caritasId,
            primerNombrePaciente:    p.primerNombre,
            segundoNombrePaciente:   p.segundoNombre,
            primerApellido:          p.primerApellido,
            segundoApellido:         p.segundoApellido,
            curpPaciente:            p.curpPaciente,
            fechaNacimientoPaciente: fechaFormatter.string(from: p.fechaNacimiento),
            lugarNacimientoPaciente: p.lugarNacimiento,
            sexoPaciente:            sexoParaServidor(p.sexoPaciente),
            telefono:                p.telefono,
            municipio:               p.municipio,
            estado:                  p.estado,
            domicilio:               p.domicilio,
            colonia:                 p.colonia,
            numIntegrantesFamilia:   p.numIntegrantesFamilia,
            ingresosMensuales:       p.ingresosMensuales,
            gradoEstudios:           p.gradoEstudios,
            tieneImss:               p.tieneIMSS,
            notas:                   p.notas,
            condicionesCronicas:     p.condicionesCronicas
        )
    }

    private func outDTOaPaciente(_ dto: PacienteOutDTO) -> Paciente {
        Paciente(
            primerNombre:          dto.primerNombrePaciente,
            segundoNombre:         dto.segundoNombrePaciente,
            primerApellido:        dto.primerApellido,
            segundoApellido:       dto.segundoApellido,
            curpPaciente:          dto.curpPaciente,
            notas:                 dto.notas,
            fechaNacimiento:       fechaFormatter.date(from: dto.fechaNacimientoPaciente) ?? Date(),
            lugarNacimiento:       dto.lugarNacimientoPaciente,
            caritasId:             dto.caritasId,
            sexoPaciente:          convertirSexo(dto.sexoPaciente),
            telefono:              dto.telefono,
            estado:                dto.estado,
            municipio:             dto.municipio,
            condicionesCronicas:   dto.condicionesCronicas,
            domicilio:             dto.domicilio,
            colonia:               dto.colonia,
            numIntegrantesFamilia: dto.numIntegrantesFamilia,
            ingresosMensuales:     dto.ingresosMensuales,
            gradoEstudios:         dto.gradoEstudios,
            tieneIMSS:             dto.tieneImss
        )
    }

    // MARK: - Conversiones Consulta

    private func consultaACreateDTO(_ c: Consulta, idPaciente: String,
                                    idJornada: String?, idPersonal: String?) -> ConsultaCreateDTO {
        ConsultaCreateDTO(
            idPaciente:              idPaciente,
            idJornada:               idJornada,
            idPersonal:              idPersonal,
            folio:                   c.folio,
            tipoServicio:            tipoConsultaParaServidor(c.tipoConsulta),
            tipoPaciente:            c.tipoPaciente.rawValue,
            lugar:                   c.lugar.isEmpty ? nil : c.lugar,
            motivoConsulta:          c.motivo.isEmpty ? nil : c.motivo,
            diagnostico:             c.diagnostico.isEmpty ? nil : c.diagnostico,
            notasMedico:             c.notasMedico.isEmpty ? nil : c.notasMedico,
            peso:                    c.peso,
            talla:                   c.talla,
            perimetroAbdominal:      c.perimetroAbdominal,
            presionArterial:         c.presionArterial,
            pulso:                   c.pulso,
            frecuenciaCardiaca:      c.frecuenciaCardiaca,
            frecuenciaRespiratoria:  c.frecuenciaRespiratoria,
            servicioDentalRecibido:  c.servicioDentalRecibido,
            diagnosticoOptometria:   c.diagnosticoOptometria,
            medicamentosEntregados:  c.medicamentosEntregados,
            cantidadMedicamentos:    c.cantidadMedicamentos,
            procedimientos:          c.procedimientos
        )
    }

    // MARK: - Helpers

    private func tipoConsultaParaServidor(_ tipo: TipoConsulta) -> String {
        tipo.rawValue  // "Consulta general", "Consulta dental", "Optometrista", "Entrega de medicamentos"
    }

    private func sexoParaServidor(_ sexo: Sexo) -> String {
        switch sexo {
        case .masculino:  return "masculino"
        case .femenino:   return "femenino"
        case .noDefinido: return "no_binario"
        }
    }

    private func convertirSexo(_ texto: String) -> Sexo {
        switch texto {
        case "masculino": return .masculino
        case "femenino":  return .femenino
        default:          return .noDefinido
        }
    }
}
