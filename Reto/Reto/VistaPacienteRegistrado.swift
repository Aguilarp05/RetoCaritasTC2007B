import SwiftUI
import SwiftData

enum SeccionExpediente: String, CaseIterable, Identifiable {
    case datosClinicos = "Datos clínicos"
    case medicamentos  = "Medicamentos"
    case lineaTiempo   = "Consultas"

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
                            .foregroundStyle(Color(hex: "#633806"))
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
    @State private var seccionSeleccionada: SeccionExpediente = .datosClinicos
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

                HStack(spacing: 0) {
                    ForEach(SeccionExpediente.allCases) { seccion in
                        let seleccionada = seccionSeleccionada == seccion
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                seccionSeleccionada = seccion
                            }
                        } label: {
                            Text(seccion.rawValue)
                                .font(.subheadline)
                                .fontWeight(seleccionada ? .semibold : .regular)
                                .foregroundStyle(seleccionada ? Color.caritasPrimario : Color.caritasGris)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(seleccionada ? Color.caritasSuave : Color(.systemBackground))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(seleccionada ? Color.caritasPrimario : Color(.systemGray5))
                                        .frame(height: seleccionada ? 2 : 0.5)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(.systemBackground))

                Divider()

                contenidoDeSeccion
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground))
        }
        .colorScheme(.light)
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
            case .datosClinicos: DatosClinicosPacienteView(paciente: paciente)
            case .medicamentos:  HistorialMedicamentosPacienteView(consultas: paciente.consultas)
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

            let recetas = RecetaLocal.decode(consulta.recetasJSON)
            if !recetas.isEmpty {
                Divider().padding(.leading, 24)
                let resumen = recetas.map { r in
                    [r.nombre, r.dosis, r.duracion].filter { !$0.isEmpty }.joined(separator: " ")
                }.joined(separator: " · ")
                filaExpediente(etiqueta: "Recetas", valor: resumen)
            } else if !consulta.medicamentos.isEmpty {
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

// MARK: - Medicamentos (historial de recetas por consulta)

struct HistorialMedicamentosPacienteView: View {
    let consultas: [Consulta]

    private struct ConsultaConRecetas: Identifiable {
        let id: UUID
        let fecha: Date
        let tipoConsulta: String
        let medico: String
        let recetas: [RecetaLocal]
    }

    private var consultasConRecetas: [ConsultaConRecetas] {
        consultas
            .sorted { $0.fecha > $1.fecha }
            .compactMap { consulta in
                let recetas = RecetaLocal.decode(consulta.recetasJSON)
                guard !recetas.isEmpty else { return nil }
                return ConsultaConRecetas(
                    id: consulta.idConsulta,
                    fecha: consulta.fecha,
                    tipoConsulta: consulta.tipoConsulta.rawValue,
                    medico: consulta.medico,
                    recetas: recetas
                )
            }
    }

    var body: some View {
        ScrollView {
            if consultasConRecetas.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pills")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.caritasSuave)
                    Text("Sin medicamentos recetados")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(Color.caritasAzul)
                    Text("Los medicamentos recetados en cada consulta aparecerán aquí.")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                        .multilineTextAlignment(.center).frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity).padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(consultasConRecetas) { entrada in
                        VStack(alignment: .leading, spacing: 0) {
                            // Encabezado de la consulta
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entrada.fecha.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption).foregroundStyle(Color.caritasGris)
                                    Text(entrada.tipoConsulta)
                                        .font(.caption).fontWeight(.semibold)
                                        .foregroundStyle(Color.caritasPrimario)
                                    if !entrada.medico.isEmpty {
                                        Text(entrada.medico)
                                            .font(.caption).foregroundStyle(Color.caritasGris)
                                    }
                                }
                                Spacer()
                                Text("\(entrada.recetas.count) med.")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.caritasSuave.opacity(0.5))

                            // Recetas de esa consulta
                            ForEach(Array(entrada.recetas.enumerated()), id: \.offset) { _, receta in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.caritasPrimario.opacity(0.25))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 5)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(receta.nombre)
                                            .font(.subheadline).fontWeight(.medium)
                                            .foregroundStyle(Color.caritasAzul)
                                        let detalle = [receta.dosis, receta.duracion]
                                            .filter { !$0.isEmpty }.joined(separator: " · ")
                                        if !detalle.isEmpty {
                                            Text(detalle)
                                                .font(.caption).foregroundStyle(Color.caritasGris)
                                        }
                                        if let notas = receta.notas, !notas.isEmpty {
                                            Text(notas)
                                                .font(.caption).foregroundStyle(Color.caritasGris)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                Divider().padding(.leading, 44)
                            }
                        }
                        Divider()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                if let dur = medicamento.duracion, !dur.isEmpty {
                    Text(dur)
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

// MARK: - Línea de tiempo (expandible)

struct LineaTiempoPacienteView: View {
    let paciente: Paciente
    @State private var expandidos: Set<UUID> = []

    private var consultas: [Consulta] {
        paciente.consultas.sorted { $0.fecha > $1.fecha }
    }

    var body: some View {
        ScrollView {
            if consultas.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.caritasSuave)
                    Text("Sin consultas registradas aún")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(consultas.enumerated()), id: \.element.idConsulta) { idx, consulta in
                        EntradaConsultaView(
                            consulta: consulta,
                            esUltima: idx == consultas.count - 1,
                            expandida: expandidos.contains(consulta.idConsulta)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandidos.contains(consulta.idConsulta) {
                                    expandidos.remove(consulta.idConsulta)
                                } else {
                                    expandidos.insert(consulta.idConsulta)
                                }
                            }
                        }
                    }

                    // Entrada de registro inicial
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.caritasAzul)
                            .frame(width: 12, height: 12)
                            .padding(.top, 3)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(paciente.fechaRegistro.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(Color.caritasGris)
                            Text("Registro en el sistema")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Color.caritasAzul)
                            Text("Paciente ingresa al programa Cáritas.")
                                .font(.caption).foregroundStyle(Color.caritasGris)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct EntradaConsultaView: View {
    let consulta: Consulta
    let esUltima: Bool
    let expandida: Bool
    let onTap: () -> Void

    private var colorTipo: Color {
        switch consulta.tipoConsulta {
        case .consultaGeneral:       return Color.caritasPrimario
        case .dental:                return Color.caritasAcento
        case .optometrista:          return .purple
        case .entregaMedicamentos:   return .green
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Línea vertical + círculo
            VStack(spacing: 0) {
                Circle()
                    .fill(colorTipo)
                    .frame(width: 12, height: 12)
                    .padding(.top, 3)
                if !esUltima || expandida {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 16)

            // Contenido
            VStack(alignment: .leading, spacing: 0) {
                // Encabezado — siempre visible, tappable
                Button(action: onTap) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(consulta.fecha.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(Color.caritasGris)
                            Text(consulta.tipoConsulta.rawValue)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Color.caritasAzul)
                            if !consulta.medico.isEmpty {
                                Text(consulta.medico)
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                            }
                        }
                        Spacer()
                        Image(systemName: expandida ? "chevron.up" : "chevron.down")
                            .font(.caption).fontWeight(.medium)
                            .foregroundStyle(Color.caritasGris)
                    }
                }
                .buttonStyle(.plain)

                // Detalle expandible
                if expandida {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider().padding(.vertical, 6)

                        if !consulta.motivo.isEmpty {
                            detalleRow("Motivo", valor: consulta.motivo)
                        }
                        if !consulta.diagnostico.isEmpty {
                            detalleRow("Diagnóstico", valor: consulta.diagnostico)
                        }
                        if !consulta.notasMedico.isEmpty {
                            detalleRow("Notas", valor: consulta.notasMedico)
                        }
                        if !consulta.lugar.isEmpty {
                            detalleRow("Lugar", valor: consulta.lugar)
                        }

                        let recetas = RecetaLocal.decode(consulta.recetasJSON)
                        if !recetas.isEmpty {
                            detalleRow("Recetas", valor: recetas.map {
                                [$0.nombre, $0.dosis, $0.duracion].filter { !$0.isEmpty }.joined(separator: " ")
                            }.joined(separator: "\n"))
                        } else if !consulta.medicamentos.isEmpty {
                            detalleRow("Medicamentos", valor: consulta.medicamentos.joined(separator: ", "))
                        }

                        if let pa = consulta.presionArterial, !pa.isEmpty {
                            detalleRow("Presión arterial", valor: pa)
                        }
                        if let peso = consulta.peso {
                            detalleRow("Peso / Talla", valor: "\(peso) kg\(consulta.talla.map { " · \($0) cm" } ?? "")")
                        }
                        if !consulta.procedimientos.isEmpty {
                            detalleRow("Procedimientos", valor: consulta.procedimientos.joined(separator: ", "))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, expandida ? 16 : 28)
        }
    }

    private func detalleRow(_ etiqueta: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(etiqueta)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(Color.caritasGris)
            Text(valor)
                .font(.caption)
                .foregroundStyle(Color.caritasAzul)
                .fixedSize(horizontal: false, vertical: true)
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
