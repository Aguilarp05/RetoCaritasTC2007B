import SwiftUI

struct MedicamentoTemporal: Identifiable {
    let id = UUID()
    var nombre: String
    var indicacion: String
    var fechaInicio: Date
}

struct NuevaConsultaView: View {
    @Environment(\.dismiss) private var dismiss

    let paciente: Paciente

    @State private var fecha = Date()
    @State private var lugar = ""
    @State private var motivo = ""
    @State private var diagnostico = ""
    @State private var notasMedico = ""
    @State private var procedimientosTexto = ""
    @State private var medico = ""

    @State private var medicamentoNombre = ""
    @State private var medicamentoIndicacion = ""
    @State private var medicamentoFechaInicio = Date()
    @State private var medicamentosIndicados: [MedicamentoTemporal] = []
    
    @State private var peso = ""
    @State private var talla = ""
    @State private var perimetroAbdominal = ""
    @State private var presionArterial = ""
    @State private var pulso = ""
    @State private var frecuenciaCardiaca = ""
    @State private var frecuenciaRespiratoria = ""

    @State private var tieneIMSS = false
    @State private var medicamentosEntregados = ""
    @State private var cantidadMedicamento = ""

    @State private var diagnosticoOptometria = ""
    @State private var servicioDental = ""

    
    @State private var tipoConsulta: TipoConsulta = .consultaGeneral


    private var puedeGuardar: Bool {
        !motivo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !diagnostico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !medico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var puedeAgregarMedicamento: Bool {
        !medicamentoNombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Tipo de consulta") {
                        Picker("Tipo", selection: $tipoConsulta) {
                            ForEach(TipoConsulta.allCases) { tipo in
                                Text(tipo.rawValue)
                                    .tag(tipo)
                            }
                        }
                    }

                    camposComunes

                    camposEspecificosPorTipo
                }
                .frame(maxWidth: 760)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
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
                    .disabled(!puedeGuardar)
                }
            }
        }
    }

    
    private var camposComunes: some View {
        Section("Datos de la consulta") {
            DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
            TextField("Lugar", text: $lugar)
            TextField("Médico", text: $medico)
        }
    }

    private var camposEspecificosPorTipo: some View {
        Group {
            switch tipoConsulta {
            case .consultaGeneral:
                Group {
                    Section("Registro del paciente") {
                        TextField("Motivo", text: $motivo)
                        TextField("Diagnóstico", text: $diagnostico, axis: .vertical)
                        TextField("Notas médicas", text: $notasMedico, axis: .vertical)
                    }

                    Section("Signos físicos generales") {
                        TextField("Peso", text: $peso)
                        TextField("Talla", text: $talla)
                        TextField("Perímetro abdominal", text: $perimetroAbdominal)
                        TextField("Presión arterial", text: $presionArterial)
                        TextField("Pulso", text: $pulso)
                        TextField("Frecuencia cardiaca", text: $frecuenciaCardiaca)
                        TextField("Frecuencia respiratoria", text: $frecuenciaRespiratoria)
                    }

                    Section("Procedimientos") {
                        TextField("Procedimientos separados por coma", text: $procedimientosTexto)
                    }
                }

            case .entregaMedicamentos:
                Group {
                    Section("Entrega de medicamentos") {
                        TextField("Motivo", text: $motivo)

                        Picker("¿Tiene IMSS?", selection: $tieneIMSS) {
                            Text("Sí").tag(true)
                            Text("No").tag(false)
                        }

                        TextField("Medicamentos entregados", text: $medicamentosEntregados)
                        TextField("Cantidad", text: $cantidadMedicamento)
                        TextField("Notas", text: $notasMedico, axis: .vertical)
                    }

                    Section("Medicamentos indicados") {
                        medicamentosIndicadosSection
                    }
                }

            case .optometrista:
                Section("Optometrista") {
                    TextField("Nombre", text: .constant(paciente.nombreCompleto))
                        .disabled(true)

                    Picker("Género", selection: .constant(paciente.sexoPaciente)) {
                        Text("Masculino").tag(Sexo.masculino)
                        Text("Femenino").tag(Sexo.femenino)
                        Text("No definido").tag(Sexo.noDefinido)
                    }
                    .disabled(true)

                    TextField("Edad", text: .constant("\(paciente.edad) años"))
                        .disabled(true)

                    TextField("Diagnóstico", text: $diagnosticoOptometria, axis: .vertical)
                }

            case .dental:
                Section("Consulta dental") {
                    TextField("Dr. atendió", text: $medico)

                    TextField("Nombre", text: .constant(paciente.nombreCompleto))
                        .disabled(true)

                    TextField("Edad", text: .constant("\(paciente.edad) años"))
                        .disabled(true)

                    Picker("Género", selection: .constant(paciente.sexoPaciente)) {
                        Text("Masculino").tag(Sexo.masculino)
                        Text("Femenino").tag(Sexo.femenino)
                        Text("No definido").tag(Sexo.noDefinido)
                    }
                    .disabled(true)

                    TextField("CURP", text: .constant(paciente.curpPaciente ?? "Sin CURP"))
                        .disabled(true)

                    TextField("Servicio recibido", text: $servicioDental, axis: .vertical)
                }
            }
        }
    }

    private var medicamentosIndicadosSection: some View {
        Group {
            if medicamentosIndicados.isEmpty {
                Text("Sin medicamentos agregados.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(medicamentosIndicados) { medicamento in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicamento.nombre)
                            .font(.headline)

                        Text(medicamento.indicacion)
                            .foregroundStyle(.secondary)

                        Text("Desde \(medicamento.fechaInicio.formatted(.dateTime.day().month().year()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indices in
                    medicamentosIndicados.remove(atOffsets: indices)
                }
            }

            TextField("Nombre del medicamento", text: $medicamentoNombre)
            TextField("Indicación", text: $medicamentoIndicacion)

            DatePicker(
                "Fecha de inicio",
                selection: $medicamentoFechaInicio,
                displayedComponents: .date
            )

            Button {
                agregarMedicamento()
            } label: {
                Label("Agregar medicamento", systemImage: "plus.circle.fill")
            }
            .disabled(!puedeAgregarMedicamento)
        }
    }


    private func agregarMedicamento() {
        let medicamento = MedicamentoTemporal(
            nombre: medicamentoNombre,
            indicacion: medicamentoIndicacion,
            fechaInicio: medicamentoFechaInicio
        )

        medicamentosIndicados.append(medicamento)

        medicamentoNombre = ""
        medicamentoIndicacion = ""
        medicamentoFechaInicio = Date()
    }

    private func guardarConsulta() {
        let nuevaConsulta = Consulta(
            tipoConsulta: tipoConsulta,
            fecha: fecha,
            lugar: lugar,
            motivo: motivo,
            diagnostico: diagnostico,
            notasMedico: notasMedico,
            medicamentos: medicamentosIndicados.map { $0.nombre },
            procedimientos: separarPorComas(procedimientosTexto),
            medico: medico
        )


        paciente.consultas.append(nuevaConsulta)

        for medicamentoTemporal in medicamentosIndicados {
            let medicamento = MedicamentoPaciente(
                nombre: medicamentoTemporal.nombre,
                indicacion: medicamentoTemporal.indicacion,
                fechaInicio: medicamentoTemporal.fechaInicio
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


#Preview {
    NuevaConsultaView(
        paciente: Paciente(
            primerNombre: "Lupita",
            primerApellido: "Torres",
            notas: "Alergia a penicilina. No administrar derivados.",
            fechaNacimiento: Calendar.current.date(
                from: DateComponents(year: 1992, month: 3, day: 12)
            )!,
            lugarNacimiento: "El Mezquital",
            caritasId: "C-003",
            sexoPaciente: .femenino,
            telefono: "618 234 5678",
            estado: "Durango",
            municipio: "El Mezquital",
            condicionesCronicas: [
                "Diabetes tipo 2",
                "Nutrición"
            ],
            fechaProximoSeguimiento: Calendar.current.date(
                from: DateComponents(year: 2026, month: 4, day: 10)
            ),
            motivoProximoSeguimiento: "Control glucosa"
        )
    )
}
