import SwiftUI
import PDFKit

struct NuevoPacienteView: View {

    @State private var pasoActual = 0

    var pasosDinamicos: [String] {
        var pasos = [
            "identificacion",
            "datos_personales",
            "ubicacion",
            "consulta"
        ]
        if servicioSeleccionado == "Consulta general" {
            pasos.append("signos_vitales")
            pasos.append("socioeconomico")
        }
        pasos.append("privacidad")
        return pasos
    }

    var totalPasos: Int { pasosDinamicos.count }

    // Paso 1
    @State private var curp            = ""
    @State private var nombreBusqueda  = ""
    @State private var tipoPaciente    = ""

    // Paso 2
    @State private var primerNombre    = ""
    @State private var segundoNombre   = ""
    @State private var primerApellido  = ""
    @State private var segundoApellido = ""
    @State private var fechaNacimiento = Date()
    @State private var sexo            = Sexo.noDefinido
    @State private var telefono        = ""

    // Paso 3
    @State private var estadoSeleccionado     = ""
    @State private var municipioSeleccionado  = ""
    @State private var comunidad              = ""

    // Paso 4
    @State private var servicioSeleccionado  = "Consulta general"
    @State private var medicoSeleccionado    = "Dra. Rosa Sánchez"
    @State private var prioridad             = "normal"
    @State private var motivoConsulta        = ""
    @State private var tieneIMSS             = ""
    @State private var doctorDental          = ""

    // Paso 5 - Signos vitales
    @State private var peso                = ""
    @State private var talla               = ""
    @State private var presionArterial     = ""
    @State private var pulso               = ""
    @State private var frecuenciaCardiaca  = ""
    @State private var frecuenciaResp      = ""
    @State private var perimetroAbdominal  = ""

    // Paso socioeconómico
    @State private var numIntegrantes    = ""
    @State private var gradoEstudios     = ""
    @State private var ingresosMensuales = ""

    // Paso privacidad
    @State private var aceptaPrivacidad = false
    @State private var mostrarPDF       = false
    @State private var trazos: [Line]   = []

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            barraProgreso
            Divider()
            contenidoPaso
            Divider()
            navegacion
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Barra de progreso
    var barraProgreso: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            Text("Paso \(pasoActual + 1) de \(totalPasos)")
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Contenido por paso
    var contenidoPaso: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tituloPaso)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.caritasAzul)

                switch pasosDinamicos[pasoActual] {
                case "identificacion":   paso1
                case "datos_personales": paso2
                case "ubicacion":        paso3
                case "consulta":         paso4
                case "signos_vitales":   paso5
                case "socioeconomico":   paso6Socio
                case "privacidad":       paso6
                default:                 EmptyView()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 420)
    }

    var tituloPaso: String {
        switch pasosDinamicos[pasoActual] {
        case "identificacion":   return "¿El paciente ya ha sido atendido?"
        case "datos_personales": return "Datos personales"
        case "ubicacion":        return "Ubicación"
        case "consulta":         return "Motivo de consulta"
        case "signos_vitales":   return "Signos vitales"
        case "socioeconomico":   return "Datos adicionales"
        case "privacidad":       return "Aviso de privacidad"
        default:                 return ""
        }
    }

    // MARK: - Navegación
    var navegacion: some View {
        HStack(spacing: 12) {
            if pasoActual > 0 {
                Button("← Atrás") {
                    pasoActual -= 1
                }
                .foregroundStyle(Color.caritasGris)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(pasoActual < totalPasos - 1 ? "Continuar →" : "Registrar paciente") {
                pasoActual += 1
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                pasosDinamicos[pasoActual] == "privacidad" && !aceptaPrivacidad
                    ? Color.caritasGris
                    : (pasoActual < totalPasos - 1 ? Color.caritasPrimario : Color.caritasAcento)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(pasosDinamicos[pasoActual] == "privacidad" && !aceptaPrivacidad)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Paso 1
    var paso1: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("CURP (opcional)")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Si no tienes el CURP busca por nombre o continúa sin él", text: $curp)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Buscar por nombre")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Escribe el nombre del paciente", text: $nombreBusqueda)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            if nombreBusqueda.lowercased().hasPrefix("tor") {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.caritasAcento)
                        .font(.subheadline)
                    Text("Posible paciente existente — **María E. Torres · C-047 · Última visita: nov 2025**")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#633806"))
                }
                .padding(10)
                .background(Color(hex: "#FAEEDA"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
                Text("continúa con nuevo registro")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                    .fixedSize()
                Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
            }

            HStack(spacing: 10) {
                tarjetaTipo(titulo: "Paciente nuevo", subtitulo: "Primera vez en Cáritas", tipo: "nuevo")
                tarjetaTipo(titulo: "Paciente que regresa", subtitulo: "Ya tiene expediente", tipo: "regresa")
            }
        }
    }

    // MARK: - Tarjeta tipo paciente
    func tarjetaTipo(titulo: String, subtitulo: String, tipo: String) -> some View {
        Button {
            tipoPaciente = tipo
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(tipoPaciente == tipo ? Color.caritasPrimario : Color.caritasAzul)
                Text(subtitulo)
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(tipoPaciente == tipo ? Color.caritasSuave : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tipoPaciente == tipo ? Color.caritasPrimario : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Paso 2
    var paso2: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Primer nombre")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Primer nombre", text: $primerNombre)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Segundo nombre (opcional)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Segundo nombre", text: $segundoNombre)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apellido paterno")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Apellido paterno", text: $primerApellido)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apellido materno (opcional)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Apellido materno", text: $segundoApellido)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fecha de nacimiento")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    DatePicker("", selection: $fechaNacimiento, displayedComponents: .date)
                        .labelsHidden()
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edad")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    Text(calcularEdad(desde: fechaNacimiento))
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Sexo")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 10) {
                    botonSexo(etiqueta: "Femenino", valor: .femenino)
                    botonSexo(etiqueta: "Masculino", valor: .masculino)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Teléfono de contacto (opcional)")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("10 dígitos", text: $telefono)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
                    .keyboardType(.phonePad)
            }
        }
    }

    func botonSexo(etiqueta: String, valor: Sexo) -> some View {
        Button {
            sexo = valor
        } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(sexo == valor ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(sexo == valor ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(sexo == valor ? Color.caritasPrimario : Color.clear, lineWidth: 1)
                )
        }
    }

    func calcularEdad(desde fecha: Date) -> String {
        let calendario = Calendar.current
        let componentes = calendario.dateComponents([.year], from: fecha, to: Date())
        guard let años = componentes.year, años >= 0 else { return "" }
        return "\(años) años"
    }

    // MARK: - Paso 3
    var paso3: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Estado")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Estado", selection: $estadoSeleccionado) {
                    Text("Selecciona un estado").tag("")
                    ForEach(estadosYMunicipios.keys.sorted(), id: \.self) { estado in
                        Text(estado).tag(estado)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: estadoSeleccionado) {
                    municipioSeleccionado = ""
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Municipio")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Municipio", selection: $municipioSeleccionado) {
                    Text("Selecciona primero un estado").tag("")
                    ForEach(estadosYMunicipios[estadoSeleccionado] ?? [], id: \.self) { mun in
                        Text(mun).tag(mun)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(estadoSeleccionado.isEmpty)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Comunidad")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Nombre de la comunidad", text: $comunidad)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }
        }
    }

    let estadosYMunicipios: [String: [String]] = [
        "Chihuahua": ["Chihuahua", "Juárez", "Delicias", "Cuauhtémoc"],
        "Durango":   ["Durango", "Gómez Palacio", "Lerdo", "Guadalupe Victoria"],
        "Sonora":    ["Hermosillo", "Navojoa", "Cajeme", "Nogales"],
        "Sinaloa":   ["Culiacán", "Mazatlán", "Los Mochis", "Guasave"],
        "Coahuila":  ["Saltillo", "Torreón", "Monclova", "Piedras Negras"],
        "Nuevo León":["Monterrey", "Guadalupe", "San Nicolás", "Apodaca"],
    ]

    // MARK: - Paso 4
    var paso4: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Servicio solicitado")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Servicio", selection: $servicioSeleccionado) {
                    ForEach(servicios, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if servicioSeleccionado == "Entrega de medicamentos" {
                VStack(alignment: .leading, spacing: 4) {
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

            if servicioSeleccionado == "Consulta dental" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doctor que atiende")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Nombre del doctor", text: $doctorDental)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Motivo principal")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Describe brevemente el motivo de consulta", text: $motivoConsulta, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Prioridad")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                HStack(spacing: 10) {
                    botonPrioridad(etiqueta: "Normal", valor: "normal")
                    botonPrioridad(etiqueta: "Urgente", valor: "urgente")
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Médico asignado")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                Picker("Médico", selection: $medicoSeleccionado) {
                    ForEach(medicos, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: servicioSeleccionado)
    }

    func botonOpcion(etiqueta: String, valor: String, seleccionado: Binding<String>) -> some View {
        Button {
            seleccionado.wrappedValue = valor
        } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(seleccionado.wrappedValue == valor ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(seleccionado.wrappedValue == valor ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(seleccionado.wrappedValue == valor ? Color.caritasPrimario : Color.clear, lineWidth: 1)
                )
        }
    }

    func botonPrioridad(etiqueta: String, valor: String) -> some View {
        Button {
            prioridad = valor
        } label: {
            Text(etiqueta)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    prioridad == valor
                        ? (valor == "urgente" ? Color(hex: "#FCEBEB") : Color.caritasSuave)
                        : Color(.systemGray6)
                )
                .foregroundStyle(
                    prioridad == valor
                        ? (valor == "urgente" ? Color(hex: "#A32D2D") : Color.caritasPrimario)
                        : Color.caritasGris
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            prioridad == valor
                                ? (valor == "urgente" ? Color(hex: "#E24B4A") : Color.caritasPrimario)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
    }

    let servicios = [
        "Consulta general",
        "Consulta dental",
        "Optometrista",
        "Entrega de medicamentos",
    ]

    let medicos = [
        "Dra. Rosa Sánchez",
        "Dr. Jorge Ramírez",
        "Mtro. Mario López",
    ]

    // MARK: - Paso 5 - Signos vitales
    var paso5: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peso (kg)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 65.5", text: $peso)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .keyboardType(.decimalPad)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Talla (cm)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 165", text: $talla)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .keyboardType(.decimalPad)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presión arterial")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 120/80", text: $presionArterial)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pulso (lpm)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 72", text: $pulso)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .keyboardType(.numberPad)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frecuencia cardiaca (lpm)")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 75", text: $frecuenciaCardiaca)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .keyboardType(.numberPad)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frecuencia respiratoria")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    TextField("Ej. 16", text: $frecuenciaResp)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                        .keyboardType(.numberPad)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Perímetro abdominal (cm)")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Ej. 85", text: $perimetroAbdominal)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
                    .keyboardType(.decimalPad)
            }
        }
    }

    // MARK: - Paso socioeconómico
    var paso6Socio: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Número de integrantes de la familia")
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField("Ej. 4", text: $numIntegrantes)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.subheadline)
                    .keyboardType(.numberPad)
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
                .padding(10)
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
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    let gradosEstudios = [
        "Sin estudios",
        "Primaria incompleta",
        "Primaria completa",
        "Secundaria incompleta",
        "Secundaria completa",
        "Preparatoria incompleta",
        "Preparatoria completa",
        "Universidad incompleta",
        "Universidad completa",
        "Posgrado",
    ]

    let rangosIngresos = [
        "Sin ingresos",
        "Menos de $2,000",
        "$2,000 - $5,000",
        "$5,000 - $10,000",
        "$10,000 - $20,000",
        "Más de $20,000",
    ]

    // MARK: - Paso 6 - Privacidad
    var paso6: some View {
        VStack(alignment: .leading, spacing: 14) {

            if let url = Bundle.main.url(forResource: "AVISO DE PRIVACIDAD 2025", withExtension: "pdf") {
                Button {
                    mostrarPDF = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color.caritasPrimario)
                        Text("Ver aviso de privacidad completo")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasPrimario)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                    }
                    .padding(12)
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
                                    Button("Cerrar") {
                                        mostrarPDF = false
                                    }
                                    .foregroundStyle(Color.caritasPrimario)
                                }
                            }
                    }
                }
            }

            Button {
                aceptaPrivacidad.toggle()
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(aceptaPrivacidad ? Color.caritasPrimario : Color(.systemGray5))
                        if aceptaPrivacidad {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    Text("Acepto el aviso de privacidad y autorizo el uso de mis datos")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasAzul)
                        .multilineTextAlignment(.leading)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Firma del paciente")
                        .font(.caption)
                        .foregroundStyle(Color.caritasGris)
                    Spacer()
                    if !trazos.isEmpty {
                        Button("Limpiar") {
                            trazos = []
                        }
                        .font(.caption)
                        .foregroundStyle(Color.caritasAcento)
                    }
                }
                VistaFirma(trazos: $trazos)
                    .frame(height: 120)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .overlay(
                        Group {
                            if trazos.isEmpty {
                                Text("Firme aquí con el dedo o Apple Pencil")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasGris)
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

} // ← cierra NuevoPacienteView

struct Line {
    var puntos: [CGPoint] = []
}

struct VistaFirma: View {
    @Binding var trazos: [Line]
    @State private var trazoActual = Line()

    var body: some View {
        Canvas { context, size in
            for trazo in trazos {
                var path = Path()
                guard let primero = trazo.puntos.first else { continue }
                path.move(to: primero)
                for punto in trazo.puntos.dropFirst() {
                    path.addLine(to: punto)
                }
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
        .padding()
        .background(Color(.systemGroupedBackground))
}
