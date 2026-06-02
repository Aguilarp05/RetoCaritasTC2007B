import SwiftUI
import SwiftData

struct MedicamentoTemporal: Identifiable {
    let id = UUID()
    var nombre: String
    var indicacion: String
    var fechaInicio: Date
}

struct NuevaConsultaView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Personal.nombrePersonal) private var todoElPersonal: [Personal]
    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

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
    @State private var presionSistolica = ""
    @State private var presionDiastolica = ""
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
        let medicoOk = !medico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch tipoConsulta {
        case .consultaGeneral:
            return medicoOk &&
                   !motivo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !diagnostico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .entregaMedicamentos:
            return medicoOk &&
                   !motivo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .optometrista:
            return medicoOk &&
                   !diagnosticoOptometria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .dental:
            return medicoOk &&
                   !servicioDental.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var puedeAgregarMedicamento: Bool {
        !medicamentoNombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Franja del paciente
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.caritasPrimario)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(paciente.nombreCompleto)
                            .font(.headline)
                            .foregroundStyle(Color.caritasAzul)
                        Text("\(paciente.edad) años · \(paciente.sexoPaciente.rawValue.capitalized)")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasGris)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.caritasSuave)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // — Tipo de consulta —
                        seccionHeader("Tipo de consulta")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(TipoConsulta.allCases) { tipo in
                                botonTipoConsulta(tipo)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                        Divider()

                        // — Datos de la consulta —
                        seccionHeader("Datos de la consulta")
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fecha")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasGris)
                                DatePicker("", selection: $fecha, displayedComponents: .date)
                                    .labelsHidden()
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            campo("Lugar", texto: $lugar)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Médico / Personal")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasGris)
                                let base = jornadaActiva.map { $0.personal } ?? todoElPersonal.filter { $0.esActivo }
                let activos = base.filter { p in
                    p.areasDeServicio.isEmpty || p.areasDeServicio.contains(tipoConsulta.rawValue)
                }
                                if activos.isEmpty {
                                    TextField("Nombre del médico", text: $medico)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .font(.subheadline)
                                } else {
                                    Picker("Personal", selection: $medico) {
                                        Text("Selecciona quién atiende").tag("")
                                        ForEach(activos) { p in
                                            Text("\(p.nombreCompleto) · \(p.especialidad)").tag(p.nombreCompleto)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                        Divider()

                        camposEspecificosPorTipo
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Nueva consulta")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if lugar.isEmpty, let loc = jornadaActiva?.locacion {
                    lugar = [loc.municipio, loc.comunidad].compactMap { $0 }.joined(separator: ", ")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Color.caritasGris)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardarConsulta() }
                        .foregroundStyle(puedeGuardar ? Color.caritasPrimario : Color.caritasGris)
                        .fontWeight(.semibold)
                        .disabled(!puedeGuardar)
                }
            }
        }
    }

    // MARK: - Helpers de layout

    private func seccionHeader(_ titulo: String) -> some View {
        Text(titulo)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.caritasGris)
            .textCase(.uppercase)
            .kerning(0.5)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func campo(_ etiqueta: String, placeholder: String = "", texto: Binding<String>, multilinea: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            if multilinea {
                TextField(placeholder.isEmpty ? etiqueta : placeholder, text: texto, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            } else {
                TextField(placeholder.isEmpty ? etiqueta : placeholder, text: texto)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }
        }
    }

    private func campoLectura(_ etiqueta: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            Text(valor)
                .font(.subheadline)
                .foregroundStyle(Color.caritasAzul)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func botonTipoConsulta(_ tipo: TipoConsulta) -> some View {
        Button { tipoConsulta = tipo } label: {
            Text(tipo.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .foregroundStyle(tipoConsulta == tipo ? Color.caritasPrimario : Color.caritasAzul)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(tipoConsulta == tipo ? Color.caritasSuave : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tipoConsulta == tipo ? Color.caritasPrimario : Color.clear, lineWidth: 1)
                )
        }
    }

    private func botonToggle(_ etiqueta: String, valor: Bool, binding: Binding<Bool>) -> some View {
        Button { binding.wrappedValue = valor } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(binding.wrappedValue == valor ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(binding.wrappedValue == valor ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(binding.wrappedValue == valor ? Color.caritasPrimario : Color.clear, lineWidth: 1)
                )
        }
    }

    // MARK: - Campos por tipo

    @ViewBuilder
    private var camposEspecificosPorTipo: some View {
        switch tipoConsulta {
        case .consultaGeneral:
            seccionHeader("Registro del paciente")
            VStack(spacing: 12) {
                campo("Motivo", texto: $motivo, multilinea: true)
                campo("Diagnóstico", texto: $diagnostico, multilinea: true)
                campo("Notas médicas", texto: $notasMedico, multilinea: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Divider()

            seccionHeader("Signos físicos generales")
            VStack(spacing: 12) {
                campo("Peso (kg)", placeholder: "Ej. 65.5", texto: $peso)
                campo("Talla (cm)", placeholder: "Ej. 165", texto: $talla)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presión arterial")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    HStack(spacing: 6) {
                        TextField("Sist.", text: $presionSistolica)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.subheadline)
                        Text("/")
                            .font(.title3)
                            .foregroundStyle(Color.caritasGris)
                        TextField("Diast.", text: $presionDiastolica)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.subheadline)
                    }
                }
                campo("Pulso (lpm)", placeholder: "Ej. 72", texto: $pulso)
                campo("Frec. cardiaca", placeholder: "Ej. 75", texto: $frecuenciaCardiaca)
                campo("Frec. respiratoria", placeholder: "Ej. 16", texto: $frecuenciaRespiratoria)
                campo("Perímetro abdominal (cm)", placeholder: "Ej. 85", texto: $perimetroAbdominal)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Divider()

            seccionHeader("Procedimientos")
            campo("Procedimientos", placeholder: "Separados por coma", texto: $procedimientosTexto)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

        case .entregaMedicamentos:
            seccionHeader("Entrega de medicamentos")
            VStack(spacing: 12) {
                campo("Motivo", texto: $motivo)
                VStack(alignment: .leading, spacing: 4) {
                    Text("¿Tiene IMSS?")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonToggle("Sí", valor: true,  binding: $tieneIMSS)
                        botonToggle("No", valor: false, binding: $tieneIMSS)
                    }
                }
                campo("Medicamentos entregados", texto: $medicamentosEntregados)
                campo("Cantidad", texto: $cantidadMedicamento)
                campo("Notas", texto: $notasMedico, multilinea: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Divider()

            seccionHeader("Medicamentos indicados")
            medicamentosIndicadosSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

        case .optometrista:
            seccionHeader("Optometrista")
            VStack(spacing: 12) {
                campoLectura("Nombre", valor: paciente.nombreCompleto)
                campoLectura("Sexo",   valor: paciente.sexoPaciente.rawValue.capitalized)
                campoLectura("Edad",   valor: "\(paciente.edad) años")
                campo("Diagnóstico", texto: $diagnosticoOptometria, multilinea: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

        case .dental:
            seccionHeader("Consulta dental")
            VStack(spacing: 12) {
                campoLectura("Nombre", valor: paciente.nombreCompleto)
                campoLectura("Edad",   valor: "\(paciente.edad) años")
                campoLectura("Sexo",   valor: paciente.sexoPaciente.rawValue.capitalized)
                campoLectura("CURP",   valor: paciente.curpPaciente ?? "Sin CURP")
                campo("Servicio recibido", texto: $servicioDental, multilinea: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Sección de medicamentos

    private var medicamentosIndicadosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !medicamentosIndicados.isEmpty {
                VStack(spacing: 0) {
                    ForEach(medicamentosIndicados) { med in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(med.nombre)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.caritasAzul)
                                if !med.indicacion.isEmpty {
                                    Text(med.indicacion)
                                        .font(.caption)
                                        .foregroundStyle(Color.caritasGris)
                                }
                            }
                            Spacer()
                            Text(med.fechaInicio.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                            Button {
                                medicamentosIndicados.removeAll { $0.id == med.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.caritasGris)
                                    .font(.subheadline)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 10)

                        Divider()
                    }
                }
                .padding(.bottom, 4)
            }

            campo("Nombre del medicamento", texto: $medicamentoNombre)
            campo("Indicación", texto: $medicamentoIndicacion)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fecha de inicio")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                DatePicker("", selection: $medicamentoFechaInicio, displayedComponents: .date)
                    .labelsHidden()
                    .padding(6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button { agregarMedicamento() } label: {
                Label("Agregar medicamento", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(puedeAgregarMedicamento ? Color.caritasPrimario : Color.caritasGris)
            }
            .disabled(!puedeAgregarMedicamento)
        }
    }

    // MARK: - Lógica

    private func agregarMedicamento() {
        medicamentosIndicados.append(MedicamentoTemporal(
            nombre: medicamentoNombre,
            indicacion: medicamentoIndicacion,
            fechaInicio: medicamentoFechaInicio
        ))
        medicamentoNombre = ""
        medicamentoIndicacion = ""
        medicamentoFechaInicio = Date()
    }

    private func guardarConsulta() {
        let nuevaConsulta = Consulta(
            tipoConsulta:          tipoConsulta,
            fecha:                 fecha,
            lugar:                 lugar,
            motivo:                motivo,
            diagnostico:           diagnostico,
            notasMedico:           notasMedico,
            medicamentos:          medicamentosIndicados.map { $0.nombre },
            procedimientos:        separarPorComas(procedimientosTexto),
            medico:                medico,
            peso:                  Double(peso),
            talla:                 Double(talla),
            perimetroAbdominal:    Double(perimetroAbdominal),
            presionArterial:       (presionSistolica.isEmpty || presionDiastolica.isEmpty) ? nil : "\(presionSistolica)/\(presionDiastolica)",
            pulso:                 Int(pulso),
            frecuenciaCardiaca:    Int(frecuenciaCardiaca),
            frecuenciaRespiratoria: Int(frecuenciaRespiratoria),
            servicioDentalRecibido: tipoConsulta == .dental ? servicioDental : nil,
            diagnosticoOptometria: tipoConsulta == .optometrista ? diagnosticoOptometria : nil,
            medicamentosEntregados: tipoConsulta == .entregaMedicamentos ? medicamentosEntregados : nil,
            cantidadMedicamentos:  tipoConsulta == .entregaMedicamentos ? Int(cantidadMedicamento) : nil
        )
        paciente.consultas.append(nuevaConsulta)
        for med in medicamentosIndicados {
            paciente.medicamentos.append(MedicamentoPaciente(
                nombre:    med.nombre,
                indicacion: med.indicacion,
                fechaInicio: med.fechaInicio
            ))
        }
        dismiss()
    }

    private func separarPorComas(_ texto: String) -> [String] {
        texto.split(separator: ",")
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
            fechaNacimiento: Calendar.current.date(from: DateComponents(year: 1992, month: 3, day: 12))!,
            lugarNacimiento: "El Mezquital",
            caritasId: "C-003",
            sexoPaciente: .femenino,
            telefono: "618 234 5678",
            estado: "Durango",
            municipio: "El Mezquital",
            condicionesCronicas: ["Diabetes tipo 2", "Nutrición"],
            fechaProximoSeguimiento: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 10)),
            motivoProximoSeguimiento: "Control glucosa"
        )
    )
}
