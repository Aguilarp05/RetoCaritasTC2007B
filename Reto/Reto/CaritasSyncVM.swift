//
//  CaritasSyncVM.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 21/05/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class CaritasSyncVM: ObservableObject {
    @Published var isOffline: Bool = false
    @Published var mensajeError: String = ""

    let basePacientesUrl = "http://10.14.255.97:8001/pacientes"
    
    @MainActor
    func syncPacientesFromServer(context: ModelContext) async {
        guard !isOffline else { return }

        guard let url = URL(string: basePacientesUrl) else {
            mensajeError = "La URL de pacientes no es válida."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let pacientesDTO = try JSONDecoder().decode(
                [PacienteDTO].self,
                from: data
            )

            for pacienteDTO in pacientesDTO {
                guard let uuid = UUID(uuidString: pacienteDTO.idPaciente) else {
                    continue
                }

                let pacienteLocal = Paciente(
                    idPaciente: uuid,
                    primerNombre: pacienteDTO.primerNombrePaciente,
                    segundoNombre: pacienteDTO.segundoNombrePaciente,
                    primerApellido: pacienteDTO.primerApellido,
                    segundoApellido: pacienteDTO.segundoApellido,
                    curpPaciente: pacienteDTO.curpPaciente,
                    notas: pacienteDTO.notas,
                    fechaNacimiento: convertirFecha(pacienteDTO.fechaNacimientoPaciente),
                    lugarNacimiento: pacienteDTO.lugarNacimientoPaciente,
                    caritasId: pacienteDTO.caritasId,
                    sexoPaciente: convertirSexo(pacienteDTO.sexoPaciente)
                )

                context.insert(pacienteLocal)
            }

            try context.save()

        } catch {
            mensajeError = "Error al sincronizar pacientes: \(error.localizedDescription)"
            print(mensajeError)
        }
    }

    private func convertirFecha(_ texto: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.date(from: texto) ?? Date()
    }

    private func convertirSexo(_ texto: String) -> Sexo {
        switch texto {
        case "masculino":
            return .masculino
        case "femenino":
            return .femenino
        default:
            return .noDefinido
        }
    }
}

