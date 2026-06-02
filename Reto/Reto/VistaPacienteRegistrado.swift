import SwiftUI
import SwiftData

enum SeccionExpediente: String, CaseIterable, Identifiable {
    case historial     = "Historial"
    case datosClinicos = "Datos clínicos"
    case medicamentos  = "Medicamentos"
    case lineaTiempo   = "Línea de tiempo"

    var id: String { rawValue }
}

struct EventoLineaTiempo: Identifiable {
    let id = UUID()
    let fecha: String
    let titulo: String
    let descripcion: String
    let tipo: TipoEventoLineaTiempo
}

enum TipoEventoLineaTiempo {
    case seguimiento, tratamiento, alerta, nota, inicio

    var color: Color {
        switch self {
        case .seguimiento: return Color.caritasPrimario
        case .tratamiento: return .green
        case .alerta:      return Color.caritasAcento
        case .nota:        return Color.caritasGris
        case .inicio:      return Color.caritasAzul
        }
    }
}

// MARK: - Panel lateral del paciente

struct VistaPacienteRegistrado: View {
    @Bindable var paciente: Paciente
    @Environment(\.toggleSidebar) private var toggleSidebar
    var onBack: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Encabezado
                VStack(alignment: .leading, spacing: 10) {
                    if let back = onBack {
                        Button { back() } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.medium))
                                Text("Historial")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.caritasPrimario)
                        }
                    } else {
                        Button { toggleSidebar() } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundStyle(Color.caritasAzul)
                        }
                    }

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.caritasPrimario)

                    Text(paciente.nombreCompleto)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasAzul)

                    HStack(spacing: 8) {
                        Text("Paciente activa")
                            .font(.caption)
                            .foregroundStyle(Color.caritasPrimario)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.caritasSuave)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.caritasSuave.opacity(0.5))

                Divider()

                // Datos personales
                seccionHeader("Datos personales")

                VStack(spacing: 0) {
                    FilaDatoPaciente(titulo: "Edad",      valor: "\(paciente.edad) años")
                    Divider().padding(.leading, 20)
                    FilaDatoPaciente(titulo: "Sexo",      valor: paciente.sexoPaciente.rawValue.capitalized)
                    Divider().padding(.leading, 20)
                    FilaDatoPaciente(titulo: "Municipio", valor: paciente.municipio ?? "—")
                    Divider().padding(.leading, 20)
                    FilaDatoPaciente(titulo: "Estado",    valor: paciente.estado ?? "—")
                    Divider().padding(.leading, 20)
                    FilaDatoPaciente(titulo: "Contacto",  valor: paciente.telefono ?? "—")
                }

                // Notas importantes
                if let notas = paciente.notas, !notas.isEmpty {
                    Divider()
                    seccionHeader("Notas importantes")

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.caritasAcento)
                            .font(.subheadline)
                        Text(notas)
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasNota)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                // Condiciones crónicas
                if !paciente.condicionesCronicas.isEmpty {
                    Divider()
                    seccionHeader("Condiciones crónicas")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(paciente.condicionesCronicas, id: \.self) { condicion in
                            Text(condicion)
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasAzul)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 340)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
    }

    private func seccionHeader(_ titulo: String) -> some View {
        Text(titulo)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.caritasGris)
            .textCase(.uppercase)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Fila de dato

struct FilaDatoPaciente: View {
    let titulo: String
    let valor: String

    var body: some View {
        HStack {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(Color.caritasGris)
            Spacer()
            Text(valor)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.caritasAzul)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Vista principal del expediente

struct ExpedientePacienteView: View {
    @Bindable var paciente: Paciente
    var onBack: (() -> Void)? = nil
    @State private var mostrarNuevaConsulta = false
    @State private var seccionSeleccionada: SeccionExpediente = .historial
    @State private var pdfURL: URL?
    @State private var mostrarCompartirExpediente = false

    var body: some View {
        HStack(spacing: 0) {
            VistaPacienteRegistrado(paciente: paciente, onBack: onBack)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                // Encabezado del expediente
                HStack {
                    Text("Expediente clínico")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasAzul)
                    Spacer()
                    Button {
                        pdfURL = generarURLPDF(
                            ExpedientePDFContentView(paciente: paciente),
                            nombre: "expediente_\(paciente.caritasId)"
                        )
                        if pdfURL != nil { mostrarCompartirExpediente = true }
                    } label: {
                        Label("Exportar", systemImage: "arrow.down.doc")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.caritasPrimario)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.caritasSuave)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        mostrarNuevaConsulta = true
                    } label: {
                        Label("Nueva consulta", systemImage: "plus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.caritasPrimario)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                .background(Color.caritasSuave)

                Picker("Sección", selection: $seccionSeleccionada) {
                    ForEach(SeccionExpediente.allCases) { seccion in
                        Text(seccion.rawValue).tag(seccion)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.caritasPrimario)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Divider()

                contenidoDeSeccion
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground))
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $mostrarNuevaConsulta) {
            NuevaConsultaView(paciente: paciente)
        }
        .sheet(isPresented: $mostrarCompartirExpediente) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var contenidoDeSeccion: some View {
        Group {
            switch seccionSeleccionada {
            case .historial:     HistorialPacienteView(consultas: paciente.consultas)
            case .datosClinicos: DatosClinicosPacienteView(paciente: paciente)
            case .medicamentos:  MedicamentosPacienteView(medicamentos: paciente.medicamentos)
            case .lineaTiempo:   LineaTiempoPacienteView(paciente: paciente)
            }
        }
    }
}

// MARK: - Historial

struct HistorialPacienteView: View {
    let consultas: [Consulta]

    var consultasOrdenadas: [Consulta] {
        consultas.sorted { $0.fecha > $1.fecha }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(consultas.count) consultas")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.caritasGris)
                    .textCase(.uppercase)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                if consultas.isEmpty {
                    Text("Este paciente todavía no tiene consultas registradas.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 24)
                } else {
                    ForEach(consultasOrdenadas) { consulta in
                        TarjetaConsultaView(consulta: consulta)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TarjetaConsultaView: View {
    let consulta: Consulta

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Encabezado de la consulta
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(consulta.fecha.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    Text(consulta.lugar)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.caritasAzul)
                }
                Spacer()
                Text(consulta.tipoConsulta.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.caritasPrimario)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.caritasSuave)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider().padding(.leading, 24)

            // Motivo
            filaExpediente(etiqueta: "Motivo",       valor: consulta.motivo)
            Divider().padding(.leading, 24)
            filaExpediente(etiqueta: "Diagnóstico",  valor: consulta.diagnostico)

            if !consulta.notasMedico.isEmpty {
                Divider().padding(.leading, 24)
                filaExpediente(etiqueta: "Notas",    valor: consulta.notasMedico)
            }

            if !consulta.medicamentos.isEmpty {
                Divider().padding(.leading, 24)
                filaExpediente(etiqueta: "Medicamentos", valor: consulta.medicamentos.joined(separator: ", "))
            }

            if !consulta.procedimientos.isEmpty {
                Divider().padding(.leading, 24)
                filaExpediente(etiqueta: "Procedimientos", valor: consulta.procedimientos.joined(separator: ", "))
            }

            Divider().padding(.leading, 24)

            // Médico
            HStack(spacing: 6) {
                Image(systemName: "stethoscope")
                    .font(.caption)
                    .foregroundStyle(Color.caritasPrimario)
                Text(consulta.medico)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.caritasPrimario)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }

        Divider()
            .padding(.top, 4)
    }

    private func filaExpediente(etiqueta: String, valor: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(etiqueta)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
                .frame(width: 100, alignment: .leading)
            Text(valor)
                .font(.subheadline)
                .foregroundStyle(Color.caritasAzul)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

// MARK: - Datos clínicos

struct DatosClinicosPacienteView: View {
    let paciente: Paciente

    private var ultimaConsultaGeneral: Consulta? {
        paciente.consultas
            .filter { $0.tipoConsulta == .consultaGeneral }
            .sorted { $0.fecha > $1.fecha }
            .first
    }

    private var imcTexto: String? {
        guard let c = ultimaConsultaGeneral,
              let peso = c.peso, let talla = c.talla, talla > 0 else { return nil }
        let tallaMts = talla / 100
        let val = peso / (tallaMts * tallaMts)
        let cat: String
        switch val {
        case ..<18.5: cat = "Bajo peso"
        case 18.5..<25: cat = "Normal"
        case 25..<30: cat = "Sobrepeso"
        default: cat = "Obesidad"
        }
        return String(format: "%.1f — %@", val, cat)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Métricas de última consulta general
                seccionHeader("Métricas — última consulta general")

                if let c = ultimaConsultaGeneral {
                    VStack(spacing: 0) {
                        if let v = c.peso {
                            filaClinica(titulo: "Peso", valor: String(format: "%.1f kg", v))
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.talla {
                            filaClinica(titulo: "Talla", valor: String(format: "%.1f cm", v))
                            Divider().padding(.leading, 24)
                        }
                        if let v = imcTexto {
                            filaClinica(titulo: "IMC", valor: v)
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.perimetroAbdominal {
                            filaClinica(titulo: "Perímetro abdominal", valor: String(format: "%.1f cm", v))
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.presionArterial, !v.isEmpty {
                            filaClinica(titulo: "Presión arterial", valor: v)
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.pulso {
                            filaClinica(titulo: "Pulso", valor: "\(v) bpm")
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.frecuenciaCardiaca {
                            filaClinica(titulo: "Frec. cardíaca", valor: "\(v) lpm")
                            Divider().padding(.leading, 24)
                        }
                        if let v = c.frecuenciaRespiratoria {
                            filaClinica(titulo: "Frec. respiratoria", valor: "\(v) rpm")
                        }
                    }
                    Text("Tomados el \(c.fecha.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                } else {
                    Text("Sin consultas generales registradas.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)
                }

                // Datos socioeconómicos
                Divider()
                seccionHeader("Datos socioeconómicos")
                VStack(spacing: 0) {
                    filaClinica(titulo: "IMSS", valor: paciente.tieneIMSS ? "Sí" : "No")
                    if let v = paciente.gradoEstudios, !v.isEmpty {
                        Divider().padding(.leading, 24)
                        filaClinica(titulo: "Grado de estudios", valor: v)
                    }
                    if let v = paciente.ingresosMensuales, !v.isEmpty {
                        Divider().padding(.leading, 24)
                        filaClinica(titulo: "Ingresos mensuales", valor: v)
                    }
                    if let v = paciente.numIntegrantesFamilia {
                        Divider().padding(.leading, 24)
                        filaClinica(titulo: "Integrantes familia", valor: "\(v)")
                    }
                    if let v = paciente.domicilio, !v.isEmpty {
                        Divider().padding(.leading, 24)
                        filaClinica(titulo: "Domicilio", valor: v)
                    }
                    if let v = paciente.colonia, !v.isEmpty {
                        Divider().padding(.leading, 24)
                        filaClinica(titulo: "Colonia", valor: v)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func filaClinica(titulo: String, valor: String) -> some View {
        HStack {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(Color.caritasGris)
            Spacer()
            Text(valor)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.caritasAzul)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

@ViewBuilder
private func seccionHeader(_ titulo: String) -> some View {
    Text(titulo)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(Color.caritasGris)
        .textCase(.uppercase)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: - Medicamentos

struct MedicamentosPacienteView: View {
    let medicamentos: [MedicamentoPaciente]

    var medicamentosActivos: [MedicamentoPaciente] {
        medicamentos.filter { $0.estaActivo }.sorted { $0.fechaInicio > $1.fechaInicio }
    }

    var medicamentosAnteriores: [MedicamentoPaciente] {
        medicamentos.filter { !$0.estaActivo }.sorted { $0.fechaInicio > $1.fechaInicio }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                seccionHeader("Activos")
                medicamentosSection(medicamentosActivos)

                Divider()

                seccionHeader("Anteriores")
                medicamentosSection(medicamentosAnteriores)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func medicamentosSection(_ lista: [MedicamentoPaciente]) -> some View {
        Group {
            if lista.isEmpty {
                Text("Sin medicamentos registrados.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caritasGris)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
            } else {
                VStack(spacing: 0) {
                    ForEach(lista) { med in
                        MedicamentoFilaView(medicamento: med)
                        Divider().padding(.leading, 24)
                    }
                }
            }
        }
    }
}

struct MedicamentoFilaView: View {
    let medicamento: MedicamentoPaciente

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if medicamento.estaActivo {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                    }
                    Text(medicamento.nombre)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.caritasAzul)
                }
                if !medicamento.indicacion.isEmpty {
                    Text(medicamento.indicacion)
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                }
            }
            Spacer()
            Text(rangoFechas)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var rangoFechas: String {
        if let fechaFin = medicamento.fechaFin {
            return "\(formatear(medicamento.fechaInicio)) – \(formatear(fechaFin))"
        } else {
            return "Desde \(formatear(medicamento.fechaInicio))"
        }
    }

    private func formatear(_ fecha: Date) -> String {
        fecha.formatted(.dateTime.month(.abbreviated).year())
    }
}

// MARK: - Línea de tiempo

struct LineaTiempoPacienteView: View {
    let paciente: Paciente

    private var eventos: [EventoLineaTiempo] {
        var lista: [EventoLineaTiempo] = []

        // Consultas ordenadas de más reciente a más antigua
        for consulta in paciente.consultas.sorted(by: { $0.fecha > $1.fecha }) {
            let tipo: TipoEventoLineaTiempo = consulta.tipoConsulta == .consultaGeneral ? .tratamiento : .nota
            let descripcion = [consulta.diagnostico, consulta.motivo]
                .first(where: { !$0.isEmpty }) ?? consulta.tipoConsulta.rawValue
            lista.append(EventoLineaTiempo(
                fecha: consulta.fecha.formatted(date: .abbreviated, time: .omitted),
                titulo: consulta.tipoConsulta.rawValue,
                descripcion: descripcion,
                tipo: tipo
            ))
        }

        // Registro inicial (siempre al final)
        lista.append(EventoLineaTiempo(
            fecha: paciente.fechaRegistro.formatted(date: .abbreviated, time: .omitted),
            titulo: "Registro en el sistema",
            descripcion: "Paciente ingresa al programa Cáritas.",
            tipo: .inicio
        ))

        return lista
    }

    var body: some View {
        ScrollView {
            if eventos.count == 1 {
                // Solo tiene el registro inicial — sin consultas aún
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.caritasGris.opacity(0.4))
                    Text("Sin actividad registrada aún")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(eventos) { evento in
                        EventoLineaTiempoView(evento: evento, esUltimo: evento.id == eventos.last?.id)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct EventoLineaTiempoView: View {
    let evento: EventoLineaTiempo
    var esUltimo: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(evento.tipo.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 3)
                if !esUltimo {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(evento.fecha)
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Text(evento.titulo)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.caritasAzul)
                Text(evento.descripcion)
                    .font(.subheadline)
                    .foregroundStyle(Color.caritasGris)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Preview

#Preview {
    ExpedientePacienteView(
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

// MARK: - Contenido PDF del expediente

struct ExpedientePDFContentView: View {
    let paciente: Paciente

    var consultasOrdenadas: [Consulta] {
        paciente.consultas.sorted { $0.fecha > $1.fecha }
    }

    var medicamentosActivos: [MedicamentoPaciente] {
        paciente.medicamentos.filter { $0.estaActivo }.sorted { $0.fechaInicio > $1.fechaInicio }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PDFHeaderView(
                titulo: "Expediente Clínico",
                subtitulo: "Cáritas — Brigadas de salud"
            )

            // Datos del paciente
            PDFSectionView(titulo: "Datos del paciente") {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(paciente.nombreCompleto)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.caritasAzul)
                        Text("Registrado \(paciente.fechaRegistro.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.caritasGris)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        pdfDatoFila(etiqueta: "Edad",      valor: "\(paciente.edad) años")
                        pdfDatoFila(etiqueta: "Sexo",      valor: paciente.sexoPaciente.rawValue.capitalized)
                        pdfDatoFila(etiqueta: "Municipio", valor: paciente.municipio ?? "—")
                        pdfDatoFila(etiqueta: "Estado",    valor: paciente.estado ?? "—")
                        if let tel = paciente.telefono {
                            pdfDatoFila(etiqueta: "Tel.", valor: tel)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 14)
            }

            // Condiciones crónicas
            if !paciente.condicionesCronicas.isEmpty {
                PDFSectionView(titulo: "Condiciones crónicas") {
                    HStack(spacing: 8) {
                        ForEach(paciente.condicionesCronicas, id: \.self) { condicion in
                            Text(condicion)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.caritasPrimario)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.caritasSuave)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                }
            }

            // Notas importantes
            if let notas = paciente.notas, !notas.isEmpty {
                PDFSectionView(titulo: "Notas importantes") {
                    HStack(alignment: .top, spacing: 8) {
                        Text("⚠")
                            .font(.system(size: 11))
                        Text(notas)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#633806"))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                }
            }

            // Historial de consultas
            PDFSectionView(titulo: "Historial de consultas (\(paciente.consultas.count))") {
                if consultasOrdenadas.isEmpty {
                    Text("Sin consultas registradas.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                } else {
                    VStack(spacing: 0) {
                        ForEach(consultasOrdenadas) { consulta in
                            pdfConsultaFila(consulta)
                        }
                    }
                }
            }

            // Medicamentos activos
            PDFSectionView(titulo: "Medicamentos activos (\(medicamentosActivos.count))") {
                if medicamentosActivos.isEmpty {
                    Text("Sin medicamentos activos.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                } else {
                    VStack(spacing: 0) {
                        ForEach(medicamentosActivos) { med in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.nombre)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.caritasAzul)
                                    if !med.indicacion.isEmpty {
                                        Text(med.indicacion)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.caritasGris)
                                    }
                                }
                                Spacer()
                                Text("Desde \(med.fechaInicio.formatted(.dateTime.month(.abbreviated).year()))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.caritasGris)
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 7)

                            if med.id != medicamentosActivos.last?.id {
                                Rectangle().fill(Color(.systemGray5)).frame(height: 0.5).padding(.leading, 32)
                            }
                        }
                        Spacer().frame(height: 12)
                    }
                }
            }

            // Pie de página
            HStack {
                Text("Expediente generado por la app Cáritas")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.caritasGris)
                Spacer()
                Text(Date().formatted(.dateTime.day().month().year().hour().minute()))
                    .font(.system(size: 9))
                    .foregroundStyle(Color.caritasGris)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .frame(width: 595)
    }

    private func pdfDatoFila(etiqueta: String, valor: String) -> some View {
        HStack(spacing: 6) {
            Text(etiqueta + ":")
                .font(.system(size: 10))
                .foregroundStyle(Color.caritasGris)
            Text(valor)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.caritasAzul)
        }
    }

    @ViewBuilder
    private func pdfConsultaFila(_ consulta: Consulta) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(consulta.fecha.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.caritasAzul)
                Text("·")
                    .foregroundStyle(Color.caritasGris)
                Text(consulta.tipoConsulta.rawValue)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.caritasPrimario)
                if !consulta.lugar.isEmpty {
                    Text("· \(consulta.lugar)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.caritasGris)
                }
                Spacer()
                if !consulta.medico.isEmpty {
                    Text(consulta.medico)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.caritasGris)
                }
            }

            if !consulta.motivo.isEmpty {
                pdfConsultaRenglon(etiqueta: "Motivo",      valor: consulta.motivo)
            }
            if !consulta.diagnostico.isEmpty {
                pdfConsultaRenglon(etiqueta: "Diagnóstico", valor: consulta.diagnostico)
            }
            if !consulta.notasMedico.isEmpty {
                pdfConsultaRenglon(etiqueta: "Notas",       valor: consulta.notasMedico)
            }
            if !consulta.medicamentos.isEmpty {
                pdfConsultaRenglon(etiqueta: "Medicamentos", valor: consulta.medicamentos.joined(separator: ", "))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
        .background(Color.white)

        Rectangle().fill(Color(.systemGray5)).frame(height: 0.5).padding(.leading, 32)
    }

    private func pdfConsultaRenglon(etiqueta: String, valor: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(etiqueta + ":")
                .font(.system(size: 9))
                .foregroundStyle(Color.caritasGris)
                .frame(width: 72, alignment: .leading)
            Text(valor)
                .font(.system(size: 9))
                .foregroundStyle(Color.caritasAzul)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("PDF Expediente") {
    ScrollView {
        ExpedientePDFContentView(
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
}
