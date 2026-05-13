//
//  VistaConsulta.swift
//  Reto
//
//  Created by RAFAEL VALDEZ GOMEZ on 04/05/26.
//

import SwiftUI

struct NuevaConsultaView: View {
    @Environment(\.dismiss) private var dismiss

    let paciente: Paciente

    @State private var fecha = Date()
    @State private var lugar = ""
    @State private var motivo = ""
    @State private var diagnostico = ""
    @State private var notasMedico = ""
    @State private var medicamentosTexto = ""
    @State private var procedimientosTexto = ""
    @State private var medico = ""
    @State private var medicamentoNombre = ""
    @State private var medicamentoIndicacion = ""
    @State private var medicamentoFechaInicio = Date()


    var body: some View {
        NavigationStack {
            Form {
                Section("Datos de la consulta") {
                    DatePicker("Fecha", selection: $fecha, displayedComponents: .date)

                    TextField("Lugar", text: $lugar)
                    TextField("Motivo", text: $motivo)
                    TextField("Médico", text: $medico)
                }

                Section("Evaluación médica") {
                    TextField("Diagnóstico", text: $diagnostico, axis: .vertical)

                    TextEditor(text: $notasMedico)
                        .frame(minHeight: 120)
                }

                Section("Tratamiento") {
                    TextField("Medicamentos separados por coma", text: $medicamentosTexto)

                    TextField("Procedimientos separados por coma", text: $procedimientosTexto)
                }
                Section("Medicamento indicado") {
                    TextField("Nombre del medicamento", text: $medicamentoNombre)
                    TextField("Indicación", text: $medicamentoIndicacion)
                    DatePicker("Fecha de inicio", selection: $medicamentoFechaInicio, displayedComponents: .date)
                }

            }
            .navigationTitle("Nueva consulta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardarConsulta()
                    }
                }
            }
        }
    }

    private func guardarConsulta() {
        let nuevaConsulta = Consulta(
            fecha: fecha,
            lugar: lugar,
            motivo: motivo,
            diagnostico: diagnostico,
            notasMedico: notasMedico,
            medicamentos: separarPorComas(medicamentosTexto),
            procedimientos: separarPorComas(procedimientosTexto),
            medico: medico
        )

        paciente.consultas.append(nuevaConsulta)
        if !medicamentoNombre.isEmpty {
            let medicamento = MedicamentoPaciente(
                nombre: medicamentoNombre,
                indicacion: medicamentoIndicacion,
                fechaInicio: medicamentoFechaInicio
            )

            paciente.medicamentos.append(medicamento)
        }


        dismiss()
    }

    private func separarPorComas(_ texto: String) -> [String] {
        texto
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
