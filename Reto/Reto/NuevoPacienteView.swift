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
        if servicioSeleccionado != "Entrega de medicamentos" { pasos.append("recetas") }
        pasos.append("privacidad")
        return pasos
    }

    var totalPasos: Int { pasosDinamicos.count }

    var etiquetaBotonContinuar: String {
        if tipoPaciente == "regresa" { return "Abrir expediente →" }
        return pasoActual < totalPasos - 1 ? "Continuar →" : "Registrar paciente"
    }
    @State private var pacienteRegistrado = false
    @State private var mostrarToast = false
    @State private var mostrarAlertaDescartar = false
    @State private var pacienteParaConsulta: Paciente? = nil
    @State private var mostrarNuevaConsultaRegresa = false
    @State private var fechaBusqueda = Date()
    @State private var usarFechaBusqueda = false
    @State private var idDuplicadoDescartado: UUID? = nil

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
    @State private var sexo: Sexo?     = nil
    @State private var telefono        = ""
    @State private var estadoNacimiento       = "Nuevo León"
    @State private var homoclave              = ""
    @State private var estadoSeleccionado     = "Nuevo León"
    @State private var municipioSeleccionado  = ""
    @State private var comunidad              = ""

    // Paso 3 — Consulta
    @State private var servicioSeleccionado  = "Consulta general"
    @State private var medicoSeleccionado    = ""
    @State private var motivoConsulta        = ""
    @State private var diagnosticoWizard    = ""
    @State private var notasMedico           = ""
    @State private var tieneIMSS             = ""
    @State private var esOperacionBucal: Bool? = nil
    @State private var riesgosOperacion      = ""
    @State private var pronosticoOperacion   = ""
    @State private var tipoActoOperacion     = ""

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

    // Receta médica
    @State private var recetasWizard: [RecetaWizard] = [RecetaWizard()]

    // Privacidad
    @State private var aceptaPrivacidad = false
    @State private var mostrarPDF                  = false
    @State private var mostrarConsentimientoOdonto = false
    @State private var consentimientoDentalPath: String? = nil
    @State private var mostrarReferencia = false
    @State private var referenciaPath: String? = nil
    @State private var requiereReferencia: Bool? = nil
    @State private var institucionReferencia = ""
    @State private var trazos: [Line]   = []

    // MARK: - ID interno
    var caritasIdGenerado: String {
        generarCaritasId(
            primerNombre: primerNombre,
            segundoNombre: segundoNombre.isEmpty ? nil : segundoNombre,
            fechaNacimiento: fechaNacimiento,
            municipio: estadoNacimiento,
            sexo: sexo ?? .noDefinido
        )
    }

    // MARK: - CURP
    private let estadosCodes: [(nombre: String, codigo: String)] = [
        ("Aguascalientes", "AS"), ("Baja California", "BC"), ("Baja California Sur", "BS"),
        ("Campeche", "CC"), ("Chiapas", "CS"), ("Chihuahua", "CH"),
        ("Ciudad de México", "DF"), ("Coahuila", "CL"), ("Colima", "CM"),
        ("Durango", "DG"), ("Estado de México", "MC"), ("Guanajuato", "GT"),
        ("Guerrero", "GR"), ("Hidalgo", "HG"), ("Jalisco", "JC"),
        ("Michoacán", "MN"), ("Morelos", "MS"), ("Nayarit", "NT"),
        ("Nuevo León", "NL"), ("Oaxaca", "OC"), ("Puebla", "PL"),
        ("Querétaro", "QT"), ("Quintana Roo", "QR"), ("San Luis Potosí", "SP"),
        ("Sinaloa", "SL"), ("Sonora", "SR"), ("Tabasco", "TC"),
        ("Tamaulipas", "TS"), ("Tlaxcala", "TL"), ("Veracruz", "VZ"),
        ("Yucatán", "YN"), ("Zacatecas", "ZS"), ("Nacido en el extranjero", "NE"),
    ]

    var curpBase: String {
        let vowels     = CharacterSet(charactersIn: "AEIOU")
        let consonants = CharacterSet(charactersIn: "BCDFGHJKLMNPQRSTVWXYZ")
        func limpiar(_ s: String) -> String {
            s.uppercased().folding(options: .diacriticInsensitive, locale: .current).filter { $0.isLetter }
        }
        let pa = limpiar(primerApellido)
        let sa = limpiar(segundoApellido)
        let nm = limpiar(primerNombre.split(separator: " ").first.map(String.init) ?? primerNombre)
        let l1 = pa.isEmpty ? "X" : String(pa.prefix(1))
        let l2 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: vowels) != nil }).map(String.init) ?? "X"
        let l3 = sa.isEmpty ? "X" : String(sa.prefix(1))
        let l4 = nm.isEmpty ? "X" : String(nm.prefix(1))
        let cal = Calendar.current
        let yy = String(format: "%02d", cal.component(.year,  from: fechaNacimiento) % 100)
        let mm = String(format: "%02d", cal.component(.month, from: fechaNacimiento))
        let dd = String(format: "%02d", cal.component(.day,   from: fechaNacimiento))
        let sx: String
        switch sexo {
        case .masculino:  sx = "H"
        case .femenino:   sx = "M"
        default:          sx = "X"
        }
        let st = estadosCodes.first(where: { $0.nombre == estadoNacimiento })?.codigo ?? "NL"
        let c1 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        let c2 = sa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        let c3 = nm.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        return "\(l1)\(l2)\(l3)\(l4)\(yy)\(mm)\(dd)\(sx)\(st)\(c1)\(c2)\(c3)"
    }

    // CURP completa solo si el usuario ingresó la homoclave (2 chars); nil = sin CURP
    var curpCompleto: String? {
        let hcv = homoclave.codigoNormalizado
        guard hcv.count == 2 else { return nil }
        return curpBase + hcv
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
                   sexo != nil &&
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
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                barraProgreso
                Divider()
                contenidoPaso
                Divider()
                navegacion
            }
            .background(Color(.systemBackground))

            if mostrarToast {
                toastRegistrado
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
                    .zIndex(1)
            }
        }
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pasoActual) { foco = nil }
        .alert("¿Descartar el registro?", isPresented: $mostrarAlertaDescartar) {
            Button("Descartar", role: .destructive) { reiniciarFormulario() }
            Button("Continuar", role: .cancel) { }
        } message: {
            Text("Se perderán todos los datos ingresados.")
        }
    }

    var toastRegistrado: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.caritasPrimario)
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Paciente registrado")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(nombreGuardado)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.caritasAzul)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 24)
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
                Button {
                    if tipoPaciente.isEmpty {
                        reiniciarFormulario()
                    } else {
                        mostrarAlertaDescartar = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(Color.caritasGris)
                        .frame(width: 28, height: 28)
                }
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
                case "recetas":          pasoRecetas
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
        case "recetas":          return "Receta médica"
        case "privacidad":
            let tieneExtra = (servicioSeleccionado == "Consulta dental" && esOperacionBucal == true) || requiereReferencia == true
            return tieneExtra ? "Aviso(s) de privacidad" : "Aviso de privacidad"
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
        let hint = placeholder
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
                    Text("Ya tiene expediente")
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
                    titulo: "Ya tiene expediente",
                    subtitulo: "Paciente que ya ha sido atendido en Cáritas",
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

    // MARK: - Detección de duplicados (nuevo paciente)

    // Puntuación proporcional: caracteres que coinciden posicionalmente / longitud máxima × maxPts.
    // Maneja exactos (ratio 1.0 → maxPts), typos de un dedo y prefijos cortos de forma continua.
    private func puntajeNombre(_ a: String, _ b: String, maxPts: Int = 30) -> Int {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        var freqA = [Character: Int]()
        var freqB = [Character: Int]()
        a.forEach { freqA[$0, default: 0] += 1 }
        b.forEach { freqB[$0, default: 0] += 1 }
        let comunes = freqA.reduce(0) { $0 + min($1.value, freqB[$1.key, default: 0]) }
        return Int(Double(comunes) / Double(max(a.count, b.count)) * Double(maxPts))
    }

    // Retorna el paciente más similar al formulario en curso, su similitud en % relativo al máximo
    // alcanzable con los campos disponibles, y los campos que coincidieron.
    // Solo corre cuando ya hay nombre + apellido con al menos 2 caracteres.
    private var candidatoDuplicado: (paciente: Paciente, score: Int, campos: [String])? {
        let n1 = primerNombre.trimmingCharacters(in: .whitespaces)
        let a1 = primerApellido.trimmingCharacters(in: .whitespaces)
        guard n1.count >= 2, a1.count >= 2 else { return nil }

        let clean: (String) -> String = {
            $0.lowercased()
              .folding(options: .diacriticInsensitive, locale: .current)
              .trimmingCharacters(in: .whitespaces)
        }
        let cn1 = clean(n1), ca1 = clean(a1), ca2 = clean(segundoApellido)
        let cal = Calendar.current

        // Máximo alcanzable según los campos que el usuario ya rellenó
        var maxPosible = 85  // nombre (30) + apellido (30) + fecha (25) — siempre presentes
        if !ca2.isEmpty            { maxPosible += 10 }
        if !municipioSeleccionado.isEmpty { maxPosible += 5 }
        let umbral = maxPosible * 70 / 100

        var mejor: (Paciente, Int, [String])? = nil

        // Solo busca duplicados en el municipio de la jornada activa; si no hay jornada, busca en todos
        let pool: [Paciente]
        if let munJornada = jornadaActiva?.locacion?.municipio, !munJornada.isEmpty {
            pool = pacientes.filter { clean($0.municipio ?? "") == clean(munJornada) }
        } else {
            pool = pacientes
        }

        for p in pool {
            var score = 0
            var campos: [String] = []

            // Primer nombre — proporcional (30 pts = coincidencia total)
            let pn1 = clean(p.primerNombre)
            let ptsnombre = puntajeNombre(pn1, cn1)
            score += ptsnombre
            if ptsnombre >= 20 { campos.append("Nombre") }

            // Primer apellido — proporcional (30 pts = coincidencia total)
            let pa1 = clean(p.primerApellido)
            let ptsapellido = puntajeNombre(pa1, ca1)
            score += ptsapellido
            if ptsapellido >= 20 { campos.append("Primer apellido") }

            // Fecha de nacimiento — 25 pts mismo día, 10 pts mismo año
            if cal.isDate(p.fechaNacimiento, inSameDayAs: fechaNacimiento) {
                score += 25
                campos.append("Fecha de nacimiento")
            } else if cal.component(.year, from: p.fechaNacimiento) ==
                      cal.component(.year, from: fechaNacimiento) {
                score += 10
                campos.append("Año de nacimiento")
            }

            // Segundo apellido — 10 pts exacto
            if !ca2.isEmpty && clean(p.segundoApellido ?? "") == ca2 {
                score += 10
                campos.append("Segundo apellido")
            }

            // Municipio — 5 pts
            if !municipioSeleccionado.isEmpty,
               let mun = p.municipio,
               clean(mun) == clean(municipioSeleccionado) {
                score += 5
                campos.append("Municipio")
            }

            if score >= umbral, mejor == nil || score > mejor!.1 { mejor = (p, score, campos) }
        }
        // El score devuelto es % relativo al máximo alcanzable (0–100)
        return mejor.map { (paciente: $0.0, score: $0.1 * 100 / maxPosible, campos: $0.2) }
    }

    @ViewBuilder
    private var bannerDuplicado: some View {
        if let (candidato, score, campos) = candidatoDuplicado,
           idDuplicadoDescartado != candidato.idPaciente {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.caritasAcento)
                    .font(.subheadline)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("¿Este paciente ya tiene expediente?")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color.caritasAzul)
                    Text("\(candidato.nombreCompleto) · \(candidato.edad) años\(candidato.municipio.map { " · \($0)" } ?? "")")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    if !campos.isEmpty {
                        Text("Similitud en: \(campos.joined(separator: " · "))")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                    }
                    Button {
                        pasoActual = 0
                        pacienteParaConsulta = candidato
                        tipoPaciente = "regresa"
                    } label: {
                        Text("Ver expediente →")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Color.caritasPrimario)
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        idDuplicadoDescartado = candidato.idPaciente
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2).foregroundStyle(Color.caritasGris)
                        .padding(4)
                }
            }
            .padding(12)
            .background(Color.caritasAcento.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.caritasAcento.opacity(0.35), lineWidth: 1))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
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

            bannerDuplicado
                .animation(.spring(response: 0.35), value: candidatoDuplicado?.paciente.idPaciente)

            campo("Primer nombre *",
                  text: $primerNombre,
                  campoFoco: .primerNombre,
                  siguiente: .segundoNombre)

            campo("Segundo nombre",
                  placeholder: "Opcional",
                  text: $segundoNombre,
                  campoFoco: .segundoNombre,
                  siguiente: .primerApellido)

            campo("Apellido paterno *",
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
                  text: $telefono,
                  keyboard: .phonePad,
                  campoFoco: .telefono,
                  siguiente: .comunidad)
            .onChange(of: telefono) { _, nuevo in
                let soloDigitos = nuevo.filter(\.isNumber)
                telefono = String(soloDigitos.prefix(10))
            }

            separador("Lugar de nacimiento")

            VStack(alignment: .leading, spacing: 4) {
                Text("Estado de nacimiento")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Estado", selection: $estadoNacimiento) {
                    ForEach(estadosCodes, id: \.nombre) { Text($0.nombre).tag($0.nombre) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CURP")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 0) {
                    Text(curpBase)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    TextField("AA", text: $homoclave)
                        .font(.system(.subheadline, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .frame(width: 52)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.leading, 6)
                        .onChange(of: homoclave) { _, nuevo in
                            homoclave = String(nuevo.uppercased()
                                .folding(options: .diacriticInsensitive, locale: .current)
                                .filter { $0.isLetter || $0.isNumber }
                                .prefix(2))
                        }
                }
                Text(homoclave.count == 2 ? "CURP completa: \(curpCompleto ?? "")" : "Ingresa la homoclave (2 letras) para guardar la CURP")
                    .font(.caption2)
                    .foregroundStyle(homoclave.count == 2 ? Color.caritasPrimario : Color.caritasGris)
                    .padding(.top, 2)
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
                  placeholder: "Opcional",
                  text: $comunidad,
                  campoFoco: .comunidad,
                  siguiente: nil)
        }
    }

    func botonSexo(etiqueta: String, valor: Sexo) -> some View {
        let sel = sexo == .some(valor)
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
        let serviciosDisponibles: [String] = {
            guard let j = jornadaActiva, !j.serviciosDisponibles.isEmpty else { return servicios }
            let filtrados = servicios.filter { j.serviciosDisponibles.contains($0) }
            return filtrados.isEmpty ? servicios : filtrados
        }()

        return VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Servicio solicitado")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Servicio", selection: $servicioSeleccionado) {
                    ForEach(serviciosDisponibles, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear {
                    if !serviciosDisponibles.contains(servicioSeleccionado) {
                        servicioSeleccionado = serviciosDisponibles.first ?? "Consulta general"
                    }
                }
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
                Text("Motivo de consulta *")
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
                Text("Diagnóstico *")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Diagnóstico o impresión diagnóstica", text: $diagnosticoWizard, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            if servicioSeleccionado == "Consulta dental" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿Incluye operación / procedimiento invasivo?")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion(etiqueta: "Sí", valor: "si",
                                    seleccionado: Binding(
                                        get: { esOperacionBucal == true ? "si" : "" },
                                        set: { if $0 == "si" { esOperacionBucal = true } }))
                        botonOpcion(etiqueta: "No", valor: "no",
                                    seleccionado: Binding(
                                        get: { esOperacionBucal == false ? "no" : "" },
                                        set: { if $0 == "no" { esOperacionBucal = false } }))
                    }
                }

                Group {
                    if esOperacionBucal == true {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Riesgos del procedimiento (opcional)")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                                TextField("Describe los riesgos", text: $riesgosOperacion, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .font(.subheadline)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pronóstico")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                                HStack(spacing: 8) {
                                    botonOpcion(etiqueta: "Bueno",     valor: "Bueno",     seleccionado: $pronosticoOperacion)
                                    botonOpcion(etiqueta: "Malo",      valor: "Malo",      seleccionado: $pronosticoOperacion)
                                    botonOpcion(etiqueta: "Reservado", valor: "Reservado", seleccionado: $pronosticoOperacion)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tipo de acto odontológico")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                                HStack(spacing: 8) {
                                    botonOpcion(etiqueta: "Urgente",    valor: "Urgente",    seleccionado: $tipoActoOperacion)
                                    botonOpcion(etiqueta: "De riesgo",  valor: "De riesgo",  seleccionado: $tipoActoOperacion)
                                    botonOpcion(etiqueta: "No urgente", valor: "No urgente", seleccionado: $tipoActoOperacion)
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: esOperacionBucal)
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

                let personalDeJornada = jornadaActiva?.personal ?? []
                let base = personalDeJornada.isEmpty
                    ? todoElPersonal.filter { $0.esActivo }
                    : personalDeJornada.filter { $0.esActivo }
                let activos = base.filter { p in
                    p.areasDeServicio.isEmpty ||
                    p.areasDeServicio.contains(servicioSeleccionado)
                }

                if activos.isEmpty {
                    Text("Sin personal registrado — ve a 'Personal medico' para dar de alta al equipo")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if activos.count == 1 {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.caritasPrimario)
                        Text("\(activos[0].nombreCompleto) · \(activos[0].especialidad)")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasAzul)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.caritasSuave)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Picker("Personal", selection: $medicoSeleccionado) {
                        Text("Selecciona quién atiende").tag("")
                        ForEach(activos) { p in
                            Text("\(p.nombreCompleto) · \(p.especialidad)")
                                .tag(p.nombreCompleto)
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
        .onChange(of: servicioSeleccionado) { _, _ in autoSeleccionarMedico() }
        .onAppear { autoSeleccionarMedico() }
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

            campo("Peso (kg)", text: $peso,
                  keyboard: .decimalPad, campoFoco: .peso, siguiente: .talla)

            campo("Talla (cm)", text: $talla,
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

            campo("Pulso (lpm)", text: $pulso,
                  keyboard: .numberPad, campoFoco: .pulso, siguiente: .frecuenciaCardiaca)
            .onChange(of: pulso) { anterior, nuevo in
                // Sincroniza si el campo estaba vacío o el usuario no lo editó manualmente
                if frecuenciaCardiaca.isEmpty || frecuenciaCardiaca == anterior {
                    frecuenciaCardiaca = nuevo
                }
            }

            campo("Frec. cardiaca (lpm)", text: $frecuenciaCardiaca,
                  keyboard: .numberPad, campoFoco: .frecuenciaCardiaca, siguiente: .frecuenciaResp)

            campo("Frec. respiratoria", text: $frecuenciaResp,
                  keyboard: .numberPad, campoFoco: .frecuenciaResp, siguiente: .perimetroAbdominal)

            campo("Perímetro abdominal (cm)", text: $perimetroAbdominal,
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

    // MARK: - Paso Recetas

    var pasoRecetas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Indica los medicamentos recetados. Puedes dejar este apartado vacío si no aplica.")
                .font(.subheadline)
                .foregroundStyle(Color.caritasGris)

            // Encabezados
            HStack(spacing: 6) {
                Text("Medicamento").frame(maxWidth: .infinity, alignment: .leading)
                Text("Cant.").frame(width: 50, alignment: .leading)
                Text("Unidad").frame(width: 76, alignment: .leading)
                Text("Frecuencia").frame(maxWidth: .infinity, alignment: .leading)
                Text("Días").frame(width: 86, alignment: .leading)
                Spacer().frame(width: 28)
            }
            .font(.caption)
            .foregroundStyle(Color.caritasGris)
            .padding(.horizontal, 4)

            ForEach($recetasWizard) { $receta in
                HStack(spacing: 6) {
                    // Nombre
                    TextField("Medicamento", text: $receta.nombre)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)

                    // Cantidad
                    TextField("0", text: $receta.dosisAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6).padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .frame(width: 50)

                    // Unidad
                    Picker("", selection: $receta.dosisUnidad) {
                        ForEach(unidadesDosis, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(.vertical, 6).padding(.horizontal, 4)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 76)

                    // Frecuencia
                    TextField("Cada 8 hrs, 1 vez/día…", text: $receta.frecuencia)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)

                    // Días: picker numérico + label
                    HStack(spacing: 4) {
                        Picker("", selection: $receta.duracionDias) {
                            ForEach(1..<61) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 6).padding(.horizontal, 4)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 56)

                        Text("días")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                    }
                    .frame(width: 86)

                    // Eliminar
                    Button {
                        recetasWizard.removeAll { $0.id == receta.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(recetasWizard.count > 1 ? Color.caritasGris : Color.clear)
                            .font(.title3)
                    }
                    .disabled(recetasWizard.count <= 1)
                    .frame(width: 28)
                }
            }

            Button {
                recetasWizard.append(RecetaWizard())
            } label: {
                Label("Agregar medicamento", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.caritasPrimario)
            }
            .padding(.top, 4)

            Divider().padding(.vertical, 4)

            // Referencia al final, después de decidir medicamentos
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿El paciente requiere referencia a otro médico/especialista?")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion(etiqueta: "Sí", valor: "si",
                                    seleccionado: Binding(
                                        get: { requiereReferencia == true ? "si" : "" },
                                        set: { if $0 == "si" { requiereReferencia = true } }))
                        botonOpcion(etiqueta: "No", valor: "no",
                                    seleccionado: Binding(
                                        get: { requiereReferencia == false ? "no" : "" },
                                        set: { if $0 == "no" { requiereReferencia = false } }))
                    }
                }

                if requiereReferencia == true {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Institución / Especialidad a referir")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                        TextField("Ej: Hospital General, Cardiología...", text: $institucionReferencia)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.subheadline)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: requiereReferencia)
        }
    }

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

            if servicioSeleccionado == "Consulta dental" && esOperacionBucal == true {
                Button { mostrarConsentimientoOdonto = true } label: {
                    HStack {
                        Image(systemName: "doc.text.fill").foregroundStyle(Color.caritasPrimario)
                        Text("Ver consentimiento informado (Odontología)")
                            .font(.subheadline).foregroundStyle(Color.caritasPrimario)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                    }
                    .padding(14)
                    .background(Color.caritasSuave)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $mostrarConsentimientoOdonto) {
                    let nombre = [primerNombre, segundoNombre, primerApellido, segundoApellido]
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        .map { $0.nombrePropio }
                        .joined(separator: " ")
                    ConsentimientoOdontoView(
                        nombrePaciente:      nombre,
                        fechaNacimiento:     fechaNacimiento,
                        medico:              medicoSeleccionado,
                        municipio:           municipioSeleccionado,
                        diagnosticoInicial:  diagnosticoWizard,
                        esOperacionInicial:  esOperacionBucal,
                        riesgosInicial:      riesgosOperacion,
                        pronosticoInicial:   pronosticoOperacion,
                        tipoActoInicial:     tipoActoOperacion,
                        omitirFormulario:    true,
                        onPDFGuardado: { ruta in consentimientoDentalPath = ruta }
                    )
                }
            }

            if requiereReferencia == true {
                Button { mostrarReferencia = true } label: {
                    HStack {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundStyle(Color.caritasPrimario)
                        Text("Ver carta de referencia")
                            .font(.subheadline).foregroundStyle(Color.caritasPrimario)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                    }
                    .padding(14)
                    .background(Color.caritasSuave)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $mostrarReferencia) {
                    let nombre = [primerNombre, segundoNombre, primerApellido, segundoApellido]
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        .map { $0.nombrePropio }
                        .joined(separator: " ")
                    ReferenciaView(
                        nombrePaciente:    nombre,
                        fechaNacimiento:   fechaNacimiento,
                        medico:            medicoSeleccionado,
                        motivoInicial:     motivoConsulta,
                        institucionInicial: institucionReferencia,
                        omitirFormulario:  !institucionReferencia.trimmingCharacters(in: .whitespaces).isEmpty,
                        onPDFGuardado: { ruta in referenciaPath = ruta }
                    )
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

            // Tarjeta resumen
            let sexoTexto: String = sexo.map { s in
                switch s {
                case .femenino:   return "Femenino"
                case .masculino:  return "Masculino"
                case .noDefinido: return "Prefiero no decir"
                }
            } ?? "—"
            let filas: [(String, String)] = [
                ("Nombre",    "\(primerNombre.nombrePropio) \(primerApellido.nombrePropio)"),
                ("Municipio", municipioSeleccionado),
                ("Servicio",  servicioSeleccionado),
                ("Médico",    medicoSeleccionado),
                ("Sexo",      sexoTexto),
            ].filter { !$0.1.isEmpty && $0.1 != "—" }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundStyle(Color.caritasPrimario)
                    Text("Resumen del registro")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color.caritasAzul)
                }
                .padding(.bottom, 12)

                ForEach(Array(filas.enumerated()), id: \.offset) { idx, fila in
                    if idx > 0 { Divider() }
                    HStack {
                        Text(fila.0)
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                            .frame(width: 80, alignment: .leading)
                        Text(fila.1)
                            .font(.caption).fontWeight(.medium)
                            .foregroundStyle(Color.caritasAzul)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(16)
            .background(Color.caritasSuave)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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

        let nombreN    = primerNombre.nombrePropio
        let nombre2N   = segundoNombre.nombrePropio
        let apellido1N = primerApellido.nombrePropio
        let apellido2N = segundoApellido.nombrePropio
        let comunidadN = comunidad.nombrePropio
        let municipioN = municipioSeleccionado.nombrePropio

        let nuevoPaciente = Paciente(
            primerNombre:          nombreN,
            segundoNombre:         nombre2N.isEmpty ? nil : nombre2N,
            primerApellido:        apellido1N,
            segundoApellido:       apellido2N.isEmpty ? nil : apellido2N,
            curpPaciente:          curpCompleto,
            notas:                 nil,
            fechaNacimiento:       fechaNacimiento,
            lugarNacimiento:       estadoNacimiento,
            caritasId:             caritasIdGenerado,
            sexoPaciente:          sexo ?? .noDefinido,
            telefono:              telefono.limpio.isEmpty ? nil : telefono.limpio,
            estado:                estadoSeleccionado.isEmpty ? nil : estadoSeleccionado,
            municipio:             municipioN.isEmpty ? nil : municipioN,
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
            lugar:                  comunidadN,
            motivo:                 motivoConsulta.textoLibre,
            diagnostico:            diagnosticoWizard.textoLibre,
            notasMedico:            notasMedico.textoLibre,
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
        consulta.consentimientoDentalPath = consentimientoDentalPath
        consulta.referenciaPath = referenciaPath
        let recetasValidas = recetasWizard.filter { !$0.nombre.trimmingCharacters(in: .whitespaces).isEmpty }
        if !recetasValidas.isEmpty {
            let locales = recetasValidas.map { RecetaLocal(nombre: $0.nombre, dosis: $0.dosisCompleta, duracion: $0.duracion, frecuencia: $0.frecuencia.isEmpty ? nil : $0.frecuencia, notas: nil) }
            consulta.recetasJSON = (try? JSONEncoder().encode(locales)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            consulta.medicamentos = recetasValidas.map { $0.nombre }
        }
        nuevoPaciente.consultas.append(consulta)
        consulta.jornada = jornadaActiva
        consulta.personalMedico = jornadaActiva?.personal.first { $0.nombreCompleto == medicoSeleccionado }
            ?? todoElPersonal.first { $0.nombreCompleto == medicoSeleccionado }

        let consentimiento = ConsentimientoPrivacidad(
            paciente:       nuevoPaciente,
            nombreFirmante: "\(primerNombre) \(primerApellido)",
            acepta:         aceptaPrivacidad
        )
        nuevoPaciente.consentimientos.append(consentimiento)

        nombreGuardado = "\(nombreN) \(apellido1N)"
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            mostrarToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.easeOut(duration: 0.3)) { mostrarToast = false }
            try? await Task.sleep(nanoseconds: 350_000_000)
            reiniciarFormulario()
        }
    }

    private func autoSeleccionarMedico() {
        let base = jornadaActiva?.personal.filter { $0.esActivo } ?? todoElPersonal.filter { $0.esActivo }
        let activos = base.filter { p in
            p.areasDeServicio.isEmpty || p.areasDeServicio.contains(servicioSeleccionado)
        }
        if activos.count == 1 { medicoSeleccionado = activos[0].nombreCompleto }
    }

    private func reiniciarFormulario() {
        idDuplicadoDescartado = nil
        pasoActual = 0; curp = ""; nombreBusqueda = ""; tipoPaciente = ""
        pacienteParaConsulta = nil; mostrarNuevaConsultaRegresa = false
        fechaBusqueda = Date(); usarFechaBusqueda = false
        primerNombre = ""; segundoNombre = ""; primerApellido = ""; segundoApellido = ""
        fechaNacimiento = Date(); sexo = nil; telefono = ""
        estadoNacimiento = "Nuevo León"; homoclave = ""
        estadoSeleccionado = "Nuevo León"; municipioSeleccionado = ""; comunidad = ""
        servicioSeleccionado = "Consulta general"; medicoSeleccionado = ""
        motivoConsulta = ""; diagnosticoWizard = ""; notasMedico = ""; tieneIMSS = ""
        esOperacionBucal = nil; riesgosOperacion = ""; pronosticoOperacion = ""; tipoActoOperacion = ""
        requiereReferencia = nil; institucionReferencia = ""
        peso = ""; talla = ""; presionSistolica = ""; presionDiastolica = ""; pulso = ""
        frecuenciaCardiaca = ""; frecuenciaResp = ""; perimetroAbdominal = ""
        numIntegrantes = 0; gradoEstudios = ""; ingresosMensuales = ""
        recetasWizard = [RecetaWizard()]
        consentimientoDentalPath = nil; referenciaPath = nil
        aceptaPrivacidad = false; mostrarPDF = false; trazos = []
    }

} // ← cierra NuevoPacienteView

struct RecetaWizard: Identifiable {
    let id = UUID()
    var nombre: String = ""
    var dosisAmount: String = ""
    var dosisUnidad: String = "mg"
    var duracionDias: Int = 7
    var frecuencia: String = ""

    var dosisCompleta: String {
        dosisAmount.isEmpty ? "" : "\(dosisAmount) \(dosisUnidad)"
    }
    var duracion: String { duracionDias > 0 ? "\(duracionDias) días" : "" }
}

let unidadesDosis = ["mg", "g", "ml", "tab.", "cáp.", "gotas", "sobre", "amp."]

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
        .modelContainer(
            for: [Paciente.self, Consulta.self, MedicamentoPaciente.self,
                  Jornada.self, Locacion.self, ConsentimientoPrivacidad.self],
            inMemory: true
        )
        .frame(width: 768, height: 1024)
}
