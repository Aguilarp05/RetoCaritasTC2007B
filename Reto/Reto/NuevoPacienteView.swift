import SwiftUI
import PDFKit
import SwiftData

// MARK: - Focus-field identifiers

private enum Campo: Hashable {
    case curp, busqueda
    case primerNombre, segundoNombre, primerApellido, segundoApellido, telefono, comunidad
    case peso, talla, presionSistolica, presionDiastolica, pulso, frecuenciaCardiaca, frecuenciaResp, perimetroAbdominal
}

struct NuevoPacienteView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Query(sort: \Personal.nombrePersonal) private var todoElPersonal: [Personal]
    @Query(sort: \Jornada.fecha, order: .reverse) private var jornadas: [Jornada]
    @Query(sort: \Paciente.fechaRegistro, order: .reverse) private var pacientes: [Paciente]
    @FocusState private var foco: Campo?

    private var jornadaActiva: Jornada? {
        jornadas.first { Calendar.current.isDateInToday($0.fecha) && $0.horaFin == nil }
    }

    @State private var pasoActual = 0
    @State private var nombreGuardado = ""

    var pasosDinamicos: [String] {
        if tipoPaciente == "regresa" { return ["identificacion"] }
        var pasos = ["identificacion", "datos_personales", "consulta"]
        if servicioSeleccionado == "Consulta general" { pasos.append("signos_vitales") }
        pasos.append("privacidad")
        return pasos
    }

    var totalPasos: Int { pasosDinamicos.count }

    var etiquetaBotonContinuar: String {
        if tipoPaciente == "regresa" { return "Abrir expediente →" }
        return pasoActual < totalPasos - 1 ? "Continuar →" : "Registrar paciente"
    }
    @State private var pacienteRegistrado = false
    @State private var pacienteParaConsulta: Paciente? = nil
    @State private var mostrarNuevaConsultaRegresa = false
    @State private var fechaBusqueda = Date()
    @State private var usarFechaBusqueda = false

    // Paso 1 — Identificación
    @State private var curp            = ""
    @State private var nombreBusqueda  = ""
    @State private var tipoPaciente    = ""

    // Paso 2 — Datos personales + residencia
    @State private var primerNombre    = ""
    @State private var segundoNombre   = ""
    @State private var primerApellido  = ""
    @State private var segundoApellido = ""
    @State private var fechaNacimiento = Date()
    @State private var sexo            = Sexo.noDefinido
    @State private var telefono        = ""
    @State private var estadoSeleccionado     = "Nuevo León"
    @State private var municipioSeleccionado  = ""
    @State private var comunidad              = ""

    // Paso 3 — Consulta
    @State private var servicioSeleccionado  = "Consulta general"
    @State private var medicoSeleccionado    = ""
    @State private var motivoConsulta        = ""
    @State private var notasMedico           = ""
    @State private var tieneIMSS             = ""

    // Paso 4 — Signos vitales + socioeconómico
    @State private var peso               = ""
    @State private var talla              = ""
    @State private var presionSistolica   = ""
    @State private var presionDiastolica  = ""
    @State private var pulso              = ""
    @State private var frecuenciaCardiaca = ""
    @State private var frecuenciaResp     = ""
    @State private var perimetroAbdominal = ""
    @State private var numIntegrantes     = 0
    @State private var gradoEstudios      = ""
    @State private var ingresosMensuales  = ""

    // Privacidad
    @State private var aceptaPrivacidad = false
    @State private var mostrarPDF       = false
    @State private var trazos: [Line]   = []

    // MARK: - ID interno
    var caritasIdGenerado: String {
        generarCaritasId(
            primerNombre: primerNombre,
            segundoNombre: segundoNombre.isEmpty ? nil : segundoNombre,
            fechaNacimiento: fechaNacimiento,
            municipio: municipioSeleccionado,
            sexo: sexo
        )
    }

    // MARK: - Validación por paso
    var pasoValido: Bool {
        switch pasosDinamicos[pasoActual] {
        case "identificacion":
            if tipoPaciente == "regresa" { return pacienteParaConsulta != nil }
            return !tipoPaciente.isEmpty
        case "datos_personales":
            let telefonoOk = telefono.isEmpty || telefono.count == 10
            return !primerNombre.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !primerApellido.trimmingCharacters(in: .whitespaces).isEmpty &&
                   sexo != .noDefinido &&
                   !municipioSeleccionado.isEmpty &&
                   telefonoOk
        case "consulta":
            return !motivoConsulta.trimmingCharacters(in: .whitespaces).isEmpty && !medicoSeleccionado.isEmpty
        case "signos_vitales":
            return !peso.isEmpty && !talla.isEmpty &&
                   !presionSistolica.isEmpty && !presionDiastolica.isEmpty &&
                   !pulso.isEmpty &&
                   !frecuenciaCardiaca.isEmpty && !frecuenciaResp.isEmpty &&
                   !perimetroAbdominal.isEmpty
        case "privacidad":
            return aceptaPrivacidad
        default:
            return true
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            barraProgreso
            Divider()
            contenidoPaso
            Divider()
            navegacion
        }
        .background(Color(.systemBackground))
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pasoActual) { foco = nil }
    }

    // MARK: - Barra de progreso
    var barraProgreso: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { toggleSidebar() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(Color.caritasAzul)
                }
                Spacer()
                Text("Nuevo paciente")
                    .font(.headline)
                    .foregroundStyle(Color.caritasAzul)
                Spacer()
                Image(systemName: "line.3.horizontal").opacity(0)
            }

            HStack(spacing: 6) {
                ForEach(0..<totalPasos, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(
                            i < pasoActual  ? Color.caritasPrimario :
                            i == pasoActual ? Color.caritasAcento :
                                             Color(.systemGray5)
                        )
                }
            }

            HStack {
                Text(tituloPaso)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.caritasAzul)
                Spacer()
                Text("Paso \(pasoActual + 1) de \(totalPasos)")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.caritasSuave)
    }

    // MARK: - Contenido por paso
    var contenidoPaso: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch pasosDinamicos[pasoActual] {
                case "identificacion":   paso1
                case "datos_personales": paso2
                case "consulta":         paso3
                case "signos_vitales":   paso4
                case "privacidad":       paso5
                default:                 EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    var tituloPaso: String {
        switch pasosDinamicos[pasoActual] {
        case "identificacion":   return "Identificación del paciente"
        case "datos_personales": return "Datos personales y residencia"
        case "consulta":         return "Motivo de consulta"
        case "signos_vitales":   return "Signos vitales"
        case "privacidad":       return "Aviso de privacidad"
        default:                 return ""
        }
    }

    // MARK: - Navegación
    var navegacion: some View {
        Group {
            // Paso 1 sin botón — las tarjetas son la navegación
            if pasoActual == 0 && tipoPaciente != "regresa" {
                Color.clear.frame(height: 0)
            } else {
                HStack(spacing: 12) {
                    if pasoActual > 0 {
                        Button("← Atrás") { pasoActual -= 1 }
                            .foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 28).padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button(etiquetaBotonContinuar) {
                        if tipoPaciente == "regresa" && pasoActual == 0 {
                            mostrarNuevaConsultaRegresa = true
                        } else if pasoActual == totalPasos - 1 {
                            guardarPaciente()
                        } else {
                            pasoActual += 1
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(!pasoValido ? Color.caritasGris :
                                (tipoPaciente == "regresa" || pasoActual == totalPasos - 1) ? Color.caritasAcento : Color.caritasPrimario)
                    .foregroundStyle(.white).fontWeight(.semibold).font(.subheadline)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(!pasoValido)
                    .fullScreenCover(isPresented: $mostrarNuevaConsultaRegresa) {
                        if let p = pacienteParaConsulta { NuevaConsultaView(paciente: p) }
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 16)
            }
        }
        .alert("Paciente registrado", isPresented: $pacienteRegistrado) {
            Button("Nuevo paciente") { reiniciarFormulario() }
        } message: {
            Text("\(nombreGuardado) ha sido registrado exitosamente.")
        }
    }

    // MARK: - Helpers de layout

    // campo() supports optional focus navigation: pressing Return advances to `siguiente`
    @ViewBuilder
    private func campo(
        _ etiqueta: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        campoFoco: Campo? = nil,
        siguiente: Campo? = nil
    ) -> some View {
        let hint = placeholder.isEmpty ? etiqueta : placeholder
        VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            if let f = campoFoco {
                TextField(hint, text: text)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
                    .keyboardType(keyboard)
                    .focused($foco, equals: f)
                    .submitLabel(siguiente != nil ? .next : .done)
                    .onSubmit { foco = siguiente }
            } else {
                TextField(hint, text: text)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
                    .keyboardType(keyboard)
            }
        }
    }

    private func separador(_ titulo: String) -> some View {
        HStack(spacing: 10) {
            Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
            Text(titulo.uppercased())
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Color.caritasGris)
                .kerning(0.5).fixedSize()
            Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
        }
        .padding(.vertical, 6)
    }

    // MARK: - Paso 1 — Identificación

    var paso1: some View {
        VStack(alignment: .leading, spacing: 16) {
            if tipoPaciente == "regresa" {
                // Chip compacto del tipo seleccionado
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.clock").foregroundStyle(Color.caritasPrimario)
                    Text("Visita de seguimiento")
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.caritasPrimario)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            tipoPaciente = ""
                            pacienteParaConsulta = nil
                            nombreBusqueda = ""
                            curp = ""
                        }
                    } label: {
                        Text("Cambiar").font(.caption).foregroundStyle(Color.caritasGris)
                    }
                }
                .padding(12)
                .background(Color.caritasSuave)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity)

                // Campos de búsqueda con animación
                VStack(alignment: .leading, spacing: 14) {
                    campo("CURP (opcional)", placeholder: "Escribe o escanea el CURP",
                          text: $curp, campoFoco: .curp, siguiente: .busqueda)

                    campo("Nombre del paciente", placeholder: "Nombre para buscar",
                          text: $nombreBusqueda, campoFoco: .busqueda, siguiente: nil)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Fecha de nacimiento").font(.caption).foregroundStyle(Color.caritasGris)
                            Spacer()
                            Toggle("", isOn: $usarFechaBusqueda)
                                .labelsHidden().tint(Color.caritasPrimario)
                                .scaleEffect(0.85)
                        }
                        if usarFechaBusqueda {
                            DatePicker("", selection: $fechaBusqueda, in: ...Date(), displayedComponents: .date)
                                .labelsHidden().padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3), value: usarFechaBusqueda)

                    listaResultadosBusqueda
                        .animation(.spring(response: 0.35), value: pacientesFiltrados.count)
                }
                .transition(.move(edge: .top).combined(with: .opacity))

            } else {
                // Dos tarjetas grandes
                tarjetaGrande(
                    titulo: "Primera visita",
                    subtitulo: "Paciente nuevo, sin expediente en Cáritas",
                    icono: "person.badge.plus",
                    color: Color.caritasPrimario
                ) {
                    withAnimation(.spring(response: 0.3)) { tipoPaciente = "nuevo" }
                    pasoActual += 1
                }

                tarjetaGrande(
                    titulo: "Visita de seguimiento",
                    subtitulo: "Ya cuenta con expediente previo en Cáritas",
                    icono: "person.badge.clock",
                    color: Color.caritasAcento
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        tipoPaciente = "regresa"
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: tipoPaciente)
    }

    func tarjetaGrande(titulo: String, subtitulo: String, icono: String, color: Color, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 56, height: 56)
                    Image(systemName: icono).font(.title2).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(titulo).font(.headline).fontWeight(.semibold).foregroundStyle(Color.caritasAzul)
                    Text(subtitulo).font(.subheadline).foregroundStyle(Color.caritasGris)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(Color.caritasGris)
            }
            .padding(20)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Búsqueda y similitud

    private func similaridad(_ p: Paciente, busqueda: String) -> Double {
        let clean = { (s: String) in s.lowercased().folding(options: .diacriticInsensitive, locale: .current) }
        let terminos = clean(busqueda).split(separator: " ").map(String.init).filter { $0.count > 1 }
        guard !terminos.isEmpty else { return 0 }

        let nombre = clean(p.nombreCompleto)
        let matched = terminos.filter { nombre.contains($0) }.count
        var score = Double(matched) / Double(terminos.count)

        // Bonus: mismo municipio que jornada activa
        if let mJornada = jornadaActiva?.locacion?.municipio,
           clean(p.municipio ?? "") == clean(mJornada) {
            score = min(1.0, score + 0.15)
        }

        // Bonus: fecha de nacimiento coincide
        if usarFechaBusqueda {
            let cal = Calendar.current
            if cal.isDate(p.fechaNacimiento, inSameDayAs: fechaBusqueda) {
                score = min(1.0, score + 0.4)
            } else if cal.component(.year, from: p.fechaNacimiento) == cal.component(.year, from: fechaBusqueda) {
                score = min(1.0, score + 0.1)
            }
        }
        return score
    }

    private var pacientesFiltrados: [Paciente] {
        let curpQ = curp.trimmingCharacters(in: .whitespaces).uppercased()
        if curpQ.count >= 6 {
            return pacientes.filter { $0.curpPaciente?.uppercased().hasPrefix(curpQ) == true }
        }
        let busq = nombreBusqueda.trimmingCharacters(in: .whitespaces)
        guard busq.count >= 2 else { return [] }
        return pacientes
            .map { ($0, similaridad($0, busqueda: busq)) }
            .filter { $0.1 >= 0.3 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private var mejorCandidato: Paciente? {
        let busq = nombreBusqueda.trimmingCharacters(in: .whitespaces)
        guard busq.count >= 2, let top = pacientesFiltrados.first else { return nil }
        return similaridad(top, busqueda: busq) >= 0.7 ? top : nil
    }

    private var listaResultadosBusqueda: some View {
        VStack(spacing: 8) {
            if nombreBusqueda.count < 2 && curp.count < 6 {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Color.caritasGris)
                    Text("Escribe el nombre o al menos 6 caracteres del CURP")
                        .font(.subheadline).foregroundStyle(Color.caritasGris)
                }
                .padding(12).background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if pacientesFiltrados.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.slash").foregroundStyle(Color.caritasGris)
                    Text("Sin resultados. Si es nuevo, regresa y elige \"Primera visita\"")
                        .font(.subheadline).foregroundStyle(Color.caritasGris)
                }
                .padding(12).background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(pacientesFiltrados.prefix(5)) { p in
                    filaPacienteResultado(p)
                }
            }
        }
    }

    private func filaPacienteResultado(_ p: Paciente) -> some View {
        let sel = pacienteParaConsulta?.idPaciente == p.idPaciente
        let iniciales = p.nombreCompleto.split(separator: " ").prefix(2)
            .compactMap { $0.first }.map(String.init).joined().uppercased()
        let ultimaConsulta = p.consultas.sorted { $0.fecha > $1.fecha }.first

        return Button {
            withAnimation(.spring(response: 0.3)) { pacienteParaConsulta = p }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(sel ? Color.caritasPrimario : Color.caritasSuave).frame(width: 42, height: 42)
                    Text(iniciales).font(.caption).fontWeight(.bold)
                        .foregroundStyle(sel ? .white : Color.caritasPrimario)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.nombreCompleto)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.caritasAzul)
                    HStack(spacing: 4) {
                        Text("\(p.edad) años")
                        if let mun = p.municipio { Text("· \(mun)") }
                        if let ult = ultimaConsulta {
                            Text("· Últ. visita: \(ult.fecha.formatted(date: .abbreviated, time: .omitted))")
                        }
                    }
                    .font(.caption).foregroundStyle(Color.caritasGris)
                }
                Spacer()
                if sel {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.caritasPrimario).font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(sel ? Color.caritasSuave : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(sel ? Color.caritasPrimario : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    func tarjetaTipo(titulo: String, subtitulo: String, icono: String, tipo: String) -> some View {
        let sel = tipoPaciente == tipo
        return Button { tipoPaciente = tipo } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundStyle(sel ? Color.caritasPrimario : Color.caritasGris)
                VStack(alignment: .leading, spacing: 3) {
                    Text(titulo)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(sel ? Color.caritasPrimario : Color.caritasAzul)
                    Text(subtitulo)
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(sel ? Color.caritasSuave : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(sel ? Color.caritasPrimario : Color.clear, lineWidth: 1.5))
        }
    }

    // MARK: - Paso 2 — Datos personales + residencia

    var paso2: some View {
        VStack(alignment: .leading, spacing: 14) {

            campo("Primer nombre *",
                  placeholder: "Primer nombre",
                  text: $primerNombre,
                  campoFoco: .primerNombre,
                  siguiente: .segundoNombre)

            campo("Segundo nombre",
                  placeholder: "Opcional",
                  text: $segundoNombre,
                  campoFoco: .segundoNombre,
                  siguiente: .primerApellido)

            campo("Apellido paterno *",
                  placeholder: "Apellido paterno",
                  text: $primerApellido,
                  campoFoco: .primerApellido,
                  siguiente: .segundoApellido)

            campo("Apellido materno",
                  placeholder: "Opcional",
                  text: $segundoApellido,
                  campoFoco: .segundoApellido,
                  siguiente: .telefono)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fecha de nacimiento")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 12) {
                    DatePicker("", selection: $fechaNacimiento, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(calcularEdad(desde: fechaNacimiento))
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(Color.caritasPrimario)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.caritasSuave)
                        .clipShape(Capsule())
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sexo *")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 10) {
                    botonSexo(etiqueta: "Femenino", valor: .femenino)
                    botonSexo(etiqueta: "Masculino", valor: .masculino)
                    botonSexo(etiqueta: "Prefiero no decir", valor: .noDefinido)
                }
            }

            campo("Teléfono (opcional)",
                  placeholder: "10 dígitos",
                  text: $telefono,
                  keyboard: .phonePad,
                  campoFoco: .telefono,
                  siguiente: .comunidad)
            .onChange(of: telefono) { _, nuevo in
                let soloDigitos = nuevo.filter(\.isNumber)
                telefono = String(soloDigitos.prefix(10))
            }

            separador("Lugar de residencia")

            VStack(alignment: .leading, spacing: 4) {
                Text("Municipio *")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Municipio", selection: $municipioSeleccionado) {
                    Text("Selecciona un municipio").tag("")
                    ForEach(municipiosAMM, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            campo("Comunidad / Colonia",
                  placeholder: "Opcional — nombre de la colonia",
                  text: $comunidad,
                  campoFoco: .comunidad,
                  siguiente: nil)
        }
    }

    func botonSexo(etiqueta: String, valor: Sexo) -> some View {
        let sel = sexo == valor
        return Button { sexo = valor } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(sel ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(sel ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(sel ? Color.caritasPrimario : Color.clear, lineWidth: 1))
        }
    }

    func calcularEdad(desde fecha: Date) -> String {
        let componentes = Calendar.current.dateComponents([.year], from: fecha, to: Date())
        guard let años = componentes.year, años >= 0 else { return "" }
        return "\(años) años"
    }

    let municipiosAMM: [String] = [
        "Apodaca", "Cadereyta Jiménez", "Ciénega de Flores", "El Carmen",
        "García", "General Escobedo", "General Zuazua", "Guadalupe",
        "Juárez", "Monterrey", "Pesquería", "Salinas Victoria",
        "San Nicolás de los Garza", "San Pedro Garza García",
        "Santa Catarina", "Santiago",
    ]

    // MARK: - Paso 3 — Consulta

    var paso3: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Servicio solicitado")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Servicio", selection: $servicioSeleccionado) {
                    ForEach(servicios, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if servicioSeleccionado == "Entrega de medicamentos" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("¿El paciente tiene IMSS?")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion(etiqueta: "Sí", valor: "si", seleccionado: $tieneIMSS)
                        botonOpcion(etiqueta: "No", valor: "no", seleccionado: $tieneIMSS)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Motivo principal *")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Describe brevemente el motivo de consulta", text: $motivoConsulta, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notas del médico")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Observaciones adicionales (opcional)", text: $notasMedico, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Médico / Personal asignado *")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                let base = jornadaActiva.map { $0.personal } ?? todoElPersonal.filter { $0.esActivo }
                let activos = base.filter { p in
                    p.areasDeServicio.isEmpty || p.areasDeServicio.contains(servicioSeleccionado)
                }
                if activos.isEmpty {
                    Text("Sin personal registrado — ve a 'Personal medico' para dar de alta al equipo")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Picker("Personal", selection: $medicoSeleccionado) {
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
        .animation(.easeInOut(duration: 0.2), value: servicioSeleccionado)
    }

    func botonOpcion(etiqueta: String, valor: String, seleccionado: Binding<String>) -> some View {
        let activo = seleccionado.wrappedValue == valor
        return Button { seleccionado.wrappedValue = valor } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(activo ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(activo ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(activo ? Color.caritasPrimario : Color.clear, lineWidth: 1))
        }
    }

    let servicios = [
        "Consulta general", "Consulta dental",
        "Optometrista", "Entrega de medicamentos",
    ]

    // MARK: - Paso 4 — Signos vitales + datos socioeconómicos

    var paso4: some View {
        VStack(alignment: .leading, spacing: 14) {

            campo("Peso (kg)", placeholder: "Ej. 65.5", text: $peso,
                  keyboard: .decimalPad, campoFoco: .peso, siguiente: .talla)

            campo("Talla (cm)", placeholder: "Ej. 165", text: $talla,
                  keyboard: .decimalPad, campoFoco: .talla, siguiente: .presionSistolica)

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
                        .focused($foco, equals: .presionSistolica)
                        .onSubmit { foco = .presionDiastolica }
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
                        .focused($foco, equals: .presionDiastolica)
                        .onSubmit { foco = .pulso }
                }
            }

            campo("Pulso (lpm)", placeholder: "Ej. 72", text: $pulso,
                  keyboard: .numberPad, campoFoco: .pulso, siguiente: .frecuenciaCardiaca)

            campo("Frec. cardiaca (lpm)", placeholder: "Ej. 75", text: $frecuenciaCardiaca,
                  keyboard: .numberPad, campoFoco: .frecuenciaCardiaca, siguiente: .frecuenciaResp)

            campo("Frec. respiratoria", placeholder: "Ej. 16", text: $frecuenciaResp,
                  keyboard: .numberPad, campoFoco: .frecuenciaResp, siguiente: .perimetroAbdominal)

            campo("Perímetro abdominal (cm)", placeholder: "Ej. 85", text: $perimetroAbdominal,
                  keyboard: .decimalPad, campoFoco: .perimetroAbdominal, siguiente: nil)

            separador("Datos socioeconómicos")

            VStack(alignment: .leading, spacing: 4) {
                Text("Integrantes de la familia")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 12) {
                    Button { if numIntegrantes > 0 { numIntegrantes -= 1 } } label: {
                        Image(systemName: "minus")
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.caritasAzul)
                    }
                    Text("\(numIntegrantes)")
                        .font(.subheadline).fontWeight(.medium)
                        .frame(minWidth: 32)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.caritasAzul)
                    Button { numIntegrantes += 1 } label: {
                        Image(systemName: "plus")
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.caritasAzul)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Grado de estudios")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Grado de estudios", selection: $gradoEstudios) {
                    Text("Selecciona").tag("")
                    ForEach(gradosEstudios, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ingresos mensuales")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Ingresos", selection: $ingresosMensuales) {
                    Text("Selecciona").tag("")
                    ForEach(rangosIngresos, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    let gradosEstudios = [
        "Sin estudios", "Primaria incompleta", "Primaria completa",
        "Secundaria incompleta", "Secundaria completa",
        "Preparatoria incompleta", "Preparatoria completa",
        "Universidad incompleta", "Universidad completa", "Posgrado",
    ]

    let rangosIngresos = [
        "Sin ingresos", "Menos de $2,000", "$2,000 - $5,000",
        "$5,000 - $10,000", "$10,000 - $20,000", "Más de $20,000",
    ]

    // MARK: - Paso 5 — Privacidad

    var paso5: some View {
        VStack(alignment: .leading, spacing: 16) {

            if let url = Bundle.main.url(forResource: "AVISO DE PRIVACIDAD 2025", withExtension: "pdf") {
                Button { mostrarPDF = true } label: {
                    HStack {
                        Image(systemName: "doc.text.fill").foregroundStyle(Color.caritasPrimario)
                        Text("Ver aviso de privacidad completo")
                            .font(.subheadline).foregroundStyle(Color.caritasPrimario)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                    }
                    .padding(14)
                    .background(Color.caritasSuave)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $mostrarPDF) {
                    NavigationStack {
                        PDFKitView(url: url)
                            .ignoresSafeArea(edges: .bottom)
                            .navigationTitle("Aviso de privacidad")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Cerrar") { mostrarPDF = false }
                                        .foregroundStyle(Color.caritasPrimario)
                                }
                            }
                    }
                }
            }

            Button { aceptaPrivacidad.toggle() } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 22, height: 22)
                            .foregroundStyle(aceptaPrivacidad ? Color.caritasPrimario : Color(.systemGray5))
                        if aceptaPrivacidad {
                            Image(systemName: "checkmark")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    Text("Acepto el aviso de privacidad y autorizo el uso de mis datos con fines médicos")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasAzul)
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Firma del paciente")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    Spacer()
                    if !trazos.isEmpty {
                        Button("Limpiar") { trazos = [] }
                            .font(.caption).foregroundStyle(Color.caritasAcento)
                    }
                }
                VistaFirma(trazos: $trazos)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 0.5))
                    .overlay(
                        Group {
                            if trazos.isEmpty {
                                Text("Firme aquí con el dedo o Apple Pencil")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                            }
                        }
                    )
            }
        }
    }

    struct PDFKitView: UIViewRepresentable {
        let url: URL
        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = PDFDocument(url: url)
            pdfView.autoScales = true
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            return pdfView
        }
        func updateUIView(_ uiView: PDFView, context: Context) {}
    }

    // MARK: - Persistencia

    private func guardarPaciente() {
        let tipoServicioMap: TipoConsulta
        switch servicioSeleccionado {
        case "Consulta dental":           tipoServicioMap = .dental
        case "Optometrista":              tipoServicioMap = .optometrista
        case "Entrega de medicamentos":   tipoServicioMap = .entregaMedicamentos
        default:                          tipoServicioMap = .consultaGeneral
        }

        let tipoRegistro: TipoPaciente = (tipoPaciente == "regresa") ? .subsecuente : .inicial

        let nuevoPaciente = Paciente(
            primerNombre:          primerNombre,
            segundoNombre:         segundoNombre.isEmpty ? nil : segundoNombre,
            primerApellido:        primerApellido,
            segundoApellido:       segundoApellido.isEmpty ? nil : segundoApellido,
            curpPaciente:          curp.isEmpty ? nil : curp,
            notas:                 nil,
            fechaNacimiento:       fechaNacimiento,
            lugarNacimiento:       municipioSeleccionado.isEmpty ? comunidad : municipioSeleccionado,
            caritasId:             caritasIdGenerado,
            sexoPaciente:          sexo,
            telefono:              telefono.isEmpty ? nil : telefono,
            estado:                estadoSeleccionado.isEmpty ? nil : estadoSeleccionado,
            municipio:             municipioSeleccionado.isEmpty ? nil : municipioSeleccionado,
            condicionesCronicas:   [],
            numIntegrantesFamilia: numIntegrantes == 0 ? nil : numIntegrantes,
            ingresosMensuales:     ingresosMensuales.isEmpty ? nil : ingresosMensuales,
            gradoEstudios:         gradoEstudios.isEmpty ? nil : gradoEstudios,
            tieneIMSS:             tieneIMSS == "si"
        )
        modelContext.insert(nuevoPaciente)

        let consulta = Consulta(
            tipoConsulta:           tipoServicioMap,
            fecha:                  Date(),
            lugar:                  comunidad,
            motivo:                 motivoConsulta,
            diagnostico:            "",
            notasMedico:            notasMedico,
            medico:                 medicoSeleccionado,
            tipoPaciente:           tipoRegistro,
            peso:                   Double(peso),
            talla:                  Double(talla),
            perimetroAbdominal:     Double(perimetroAbdominal),
            presionArterial:        (presionSistolica.isEmpty || presionDiastolica.isEmpty) ? nil : "\(presionSistolica)/\(presionDiastolica)",
            pulso:                  Int(pulso),
            frecuenciaCardiaca:     Int(frecuenciaCardiaca),
            frecuenciaRespiratoria: Int(frecuenciaResp)
        )
        nuevoPaciente.consultas.append(consulta)

        let consentimiento = ConsentimientoPrivacidad(
            paciente:       nuevoPaciente,
            nombreFirmante: "\(primerNombre) \(primerApellido)",
            acepta:         aceptaPrivacidad
        )
        nuevoPaciente.consentimientos.append(consentimiento)

        nombreGuardado = "\(primerNombre) \(primerApellido)"
        pacienteRegistrado = true
    }

    private func reiniciarFormulario() {
        pasoActual = 0; curp = ""; nombreBusqueda = ""; tipoPaciente = ""
        pacienteParaConsulta = nil; mostrarNuevaConsultaRegresa = false
        fechaBusqueda = Date(); usarFechaBusqueda = false
        primerNombre = ""; segundoNombre = ""; primerApellido = ""; segundoApellido = ""
        fechaNacimiento = Date(); sexo = .noDefinido; telefono = ""
        estadoSeleccionado = "Nuevo León"; municipioSeleccionado = ""; comunidad = ""
        servicioSeleccionado = "Consulta general"; medicoSeleccionado = ""
        motivoConsulta = ""; notasMedico = ""; tieneIMSS = ""
        peso = ""; talla = ""; presionSistolica = ""; presionDiastolica = ""; pulso = ""
        frecuenciaCardiaca = ""; frecuenciaResp = ""; perimetroAbdominal = ""
        numIntegrantes = 0; gradoEstudios = ""; ingresosMensuales = ""
        aceptaPrivacidad = false; mostrarPDF = false; trazos = []
    }

} // ← cierra NuevoPacienteView

struct Line {
    var puntos: [CGPoint] = []
}

struct VistaFirma: View {
    @Binding var trazos: [Line]
    @State private var trazoActual = Line()

    var body: some View {
        Canvas { context, _ in
            for trazo in trazos {
                var path = Path()
                guard let primero = trazo.puntos.first else { continue }
                path.move(to: primero)
                for punto in trazo.puntos.dropFirst() { path.addLine(to: punto) }
                context.stroke(path, with: .color(.black), lineWidth: 2)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    trazoActual.puntos.append(value.location)
                    trazos = trazos.dropLast().map { $0 } + [trazoActual]
                    if trazos.isEmpty || trazos.last?.puntos.count == 1 {
                        trazos.append(trazoActual)
                    }
                }
                .onEnded { _ in
                    trazos.append(trazoActual)
                    trazoActual = Line()
                }
        )
    }
}

#Preview {
    NuevoPacienteView()
<<<<<<< Updated upstream
        .modelContainer(
            for: [Paciente.self, Consulta.self, MedicamentoPaciente.self,
                  Jornada.self, Locacion.self, ConsentimientoPrivacidad.self],
            inMemory: true
        )
=======
        .frame(width: 768, height: 1024)
>>>>>>> Stashed changes
}
