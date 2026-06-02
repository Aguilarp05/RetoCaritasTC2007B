import SwiftUI
import SwiftData

// MARK: - Vista principal (split)

struct PersonalView: View {
    @Environment(\.toggleSidebar)  private var toggleSidebar
    @Environment(\.modelContext)   private var modelContext
    @Query(sort: \Personal.nombrePersonal) private var todoElPersonal: [Personal]

    @State private var seleccionado: Personal?
    @State private var mostrarFormulario = false
    @State private var personalAEditar: Personal?

    var body: some View {
        HStack(spacing: 0) {

            // — Panel izquierdo: lista —
            VStack(spacing: 0) {
                encabezado
                Divider()
                if todoElPersonal.isEmpty {
                    estadoVacio
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(todoElPersonal) { persona in
                                filaPersonal(persona)
                                Divider().padding(.leading, 90)
                            }
                        }
                    }
                }
            }
            .frame(width: 360)
            .background(Color(.systemBackground))

            Divider()

            // — Panel derecho: perfil o placeholder —
            Group {
                if let p = seleccionado {
                    PerfilPersonalView(
                        personal: p,
                        onEditar: {
                            personalAEditar = p
                            mostrarFormulario = true
                        }
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.caritasGris.opacity(0.3))
                        Text("Selecciona un médico")
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasGris)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarFormulario) {
            FormularioPersonalView(personal: personalAEditar)
        }
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        HStack {
            Button { toggleSidebar() } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3).foregroundStyle(Color.caritasAzul)
            }
            .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Personal médico")
                    .font(.title2).fontWeight(.bold).foregroundStyle(Color.caritasAzul)
                Text("\(todoElPersonal.count) registrados")
                    .font(.subheadline).foregroundStyle(Color.caritasGris)
            }

            Spacer()

            Button {
                personalAEditar = nil
                mostrarFormulario = true
            } label: {
                Label("Registrar", systemImage: "person.badge.plus")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.caritasAcento)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.caritasSuave)
    }

    // MARK: - Fila

    private func filaPersonal(_ persona: Personal) -> some View {
        let sel = seleccionado?.idPersonal == persona.idPersonal
        return Button { seleccionado = persona } label: {
            HStack(spacing: 14) {
                avatarCirculo(persona, size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(persona.nombreCompleto)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(persona.esActivo ? Color.caritasAzul : Color.caritasGris)
                        if !persona.esActivo {
                            Text("Inactivo")
                                .font(.caption2).fontWeight(.medium)
                                .foregroundStyle(Color.caritasGris)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    Text(persona.especialidad)
                        .font(.caption).foregroundStyle(Color.caritasPrimario)
                    if !persona.areasDeServicio.isEmpty {
                        Text(persona.areasDeServicio.joined(separator: " · "))
                            .font(.caption2).foregroundStyle(Color.caritasGris)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Menu {
                    Button { personalAEditar = persona; mostrarFormulario = true } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button { persona.esActivo.toggle() } label: {
                        Label(
                            persona.esActivo ? "Marcar como inactivo" : "Marcar como activo",
                            systemImage: persona.esActivo ? "person.slash" : "person.badge.checkmark"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        if seleccionado?.idPersonal == persona.idPersonal { seleccionado = nil }
                        modelContext.delete(persona)
                    } label: { Label("Eliminar", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3).foregroundStyle(Color.caritasGris)
                }
                .onTapGesture {}
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(sel ? Color.caritasSuave : Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }

    private var estadoVacio: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 52)).foregroundStyle(Color.caritasGris.opacity(0.3))
            Text("Sin personal registrado")
                .font(.title3).fontWeight(.medium).foregroundStyle(Color.caritasAzul)
            Text("Registra al equipo médico para asignarlo a jornadas y consultas.")
                .font(.subheadline).foregroundStyle(Color.caritasGris)
                .multilineTextAlignment(.center).frame(maxWidth: 280)
            Button { personalAEditar = nil; mostrarFormulario = true } label: {
                Label("Registrar personal", systemImage: "person.badge.plus")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Color.caritasAcento)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(40)
    }
}

// MARK: - Perfil

struct PerfilPersonalView: View {
    @Bindable var personal: Personal
    let onEditar: () -> Void

    private let servicios = TipoConsulta.allCases.map { $0.rawValue }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Encabezado del perfil
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        avatarCirculo(personal, size: 64)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(personal.nombreCompleto)
                                .font(.title3).fontWeight(.bold).foregroundStyle(Color.caritasAzul)
                            Text(personal.especialidad)
                                .font(.subheadline).foregroundStyle(Color.caritasPrimario)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(personal.esActivo ? Color.green : Color.caritasGris)
                                    .frame(width: 8, height: 8)
                                Text(personal.esActivo ? "Activo" : "Inactivo")
                                    .font(.caption).foregroundStyle(Color.caritasGris)
                            }
                        }

                        Spacer()

                        Button(action: onEditar) {
                            Label("Editar", systemImage: "pencil")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(Color.caritasPrimario)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.caritasSuave)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.caritasSuave.opacity(0.5))

                Divider()

                // Datos personales
                seccionHeader("Datos personales")
                VStack(spacing: 0) {
                    filaDato("CURP",         valor: personal.curpPersonal, mono: true)
                    Divider().padding(.leading, 24)
                    filaDato("Sexo",         valor: personal.sexoPersonal.rawValue.capitalized)
                    if let mat = personal.matricula {
                        Divider().padding(.leading, 24)
                        filaDato("Cédula / Matrícula", valor: mat)
                    }
                    Divider().padding(.leading, 24)
                    filaDato("Alta en sistema", valor: personal.fechaCreacionPersonal.formatted(date: .abbreviated, time: .omitted))
                }

                // Áreas de servicio
                Divider()
                seccionHeader("Áreas de servicio")
                if personal.areasDeServicio.isEmpty {
                    Text("Sin áreas asignadas — puede atender cualquier servicio")
                        .font(.subheadline).foregroundStyle(Color.caritasGris)
                        .padding(.horizontal, 24).padding(.bottom, 16)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(personal.areasDeServicio, id: \.self) { area in
                            HStack(spacing: 6) {
                                Image(systemName: iconoServicio(area))
                                    .font(.caption).foregroundStyle(Color.caritasPrimario)
                                Text(area)
                                    .font(.subheadline).foregroundStyle(Color.caritasAzul)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Color.caritasSuave)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 16)
                }

                // Estadísticas
                Divider()
                seccionHeader("Actividad")
                HStack(spacing: 0) {
                    statBloque(titulo: "Consultas", valor: "\(personal.consultas.count)")
                    Divider()
                    statBloque(titulo: "Jornadas", valor: "\(personal.jornadas.count)")
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func seccionHeader(_ titulo: String) -> some View {
        Text(titulo)
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(Color.caritasGris).textCase(.uppercase)
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filaDato(_ titulo: String, valor: String, mono: Bool = false) -> some View {
        HStack {
            Text(titulo).font(.subheadline).foregroundStyle(Color.caritasGris)
            Spacer()
            Text(valor)
                .font(mono ? .subheadline.monospaced() : .subheadline)
                .fontWeight(.medium).foregroundStyle(Color.caritasAzul)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private func statBloque(titulo: String, valor: String) -> some View {
        VStack(spacing: 4) {
            Text(valor)
                .font(.system(size: 32, weight: .bold)).foregroundStyle(Color.caritasPrimario)
            Text(titulo)
                .font(.caption).foregroundStyle(Color.caritasGris)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
        .background(Color(.systemBackground))
    }

    private func iconoServicio(_ servicio: String) -> String {
        switch servicio {
        case "Consulta general":        return "stethoscope"
        case "Consulta dental":         return "mouth"
        case "Optometrista":            return "eye"
        case "Entrega de medicamentos": return "pill"
        default:                        return "cross.case"
        }
    }
}

// MARK: - Avatar helper compartido

func avatarCirculo(_ persona: Personal, size: CGFloat) -> some View {
    let iniciales = "\(persona.nombrePersonal) \(persona.apellidosPersonal)"
        .split(separator: " ").prefix(2)
        .compactMap { $0.first }.map(String.init).joined().uppercased()

    return ZStack {
        Circle()
            .fill(persona.esActivo ? Color.caritasSuave : Color(.systemGray5))
            .frame(width: size, height: size)
        Text(iniciales)
            .font(.system(size: size * 0.32, weight: .bold))
            .foregroundStyle(persona.esActivo ? Color.caritasPrimario : Color.caritasGris)
    }
}

// MARK: - Formulario

struct FormularioPersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let personal: Personal?

    @State private var nombre       = ""
    @State private var apellidos    = ""
    @State private var fechaNacimiento: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sexo         = Sexo.noDefinido
    @State private var estadoNacimiento = "Nuevo León"
    @State private var curp         = ""
    @State private var especialidad = ""
    @State private var areasDeServicio: Set<String> = []
    @State private var matricula    = ""
    @State private var esActivo     = true

    @FocusState private var foco: CampoPersonal?
    private enum CampoPersonal: Hashable { case nombre, apellidos, curp, matricula }

    private let titulosProfesionales = [
        "Médico general", "Odontólogo/a", "Optometrista", "Enfermero/a",
        "Farmacéutico/a", "Nutriólogo/a", "Estudiante de medicina",
        "Estudiante de odontología", "Practicante", "Otro",
    ]
    private let serviciosDisponibles = TipoConsulta.allCases.map { $0.rawValue }

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

    private var esEdicion: Bool { personal != nil }

    private var puedeGuardar: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
        !apellidos.trimmingCharacters(in: .whitespaces).isEmpty &&
        curp.trimmingCharacters(in: .whitespaces).count == 18 &&
        sexo != .noDefinido &&
        !especialidad.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    campoTexto("Nombre(s) *", text: $nombre, foco: .nombre, siguiente: .apellidos)
                        .onChange(of: nombre)    { _, _ in if !esEdicion { actualizarCURP() } }

                    campoTexto("Apellidos *", text: $apellidos, foco: .apellidos, siguiente: .matricula)
                        .onChange(of: apellidos) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha de nacimiento").font(.caption).foregroundStyle(Color.caritasGris)
                        DatePicker("", selection: $fechaNacimiento, in: ...Date(), displayedComponents: .date)
                            .labelsHidden().padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .onChange(of: fechaNacimiento) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sexo *").font(.caption).foregroundStyle(Color.caritasGris)
                        HStack(spacing: 10) {
                            botonSexo("Femenino", valor: .femenino)
                            botonSexo("Masculino", valor: .masculino)
                        }
                    }
                    .onChange(of: sexo) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estado de nacimiento").font(.caption).foregroundStyle(Color.caritasGris)
                        Picker("Estado", selection: $estadoNacimiento) {
                            ForEach(estadosCodes, id: \.nombre) { Text($0.nombre).tag($0.nombre) }
                        }
                        .pickerStyle(.menu).padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .onChange(of: estadoNacimiento) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("CURP *").font(.caption).foregroundStyle(Color.caritasGris)
                            Spacer()
                            Button { actualizarCURP() } label: {
                                Label("Regenerar", systemImage: "wand.and.stars")
                                    .font(.caption).foregroundStyle(Color.caritasPrimario)
                            }
                        }
                        TextField("CURP", text: $curp)
                            .padding(12).background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.subheadline.monospaced())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($foco, equals: .curp)
                            .submitLabel(.next).onSubmit { foco = .matricula }
                            .onChange(of: curp) { _, nuevo in curp = String(nuevo.uppercased().prefix(18)) }
                        if !curp.isEmpty && curp.count != 18 {
                            Text("\(curp.count)/18 caracteres")
                                .font(.caption2).foregroundStyle(Color.caritasAcento)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Título / Rol profesional *").font(.caption).foregroundStyle(Color.caritasGris)
                        Picker("Especialidad", selection: $especialidad) {
                            Text("Selecciona un título").tag("")
                            ForEach(titulosProfesionales, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu).padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Áreas de servicio")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                        Text("Servicios que puede cubrir en brigada (puede rotarse)")
                            .font(.caption2).foregroundStyle(Color.caritasGris)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(serviciosDisponibles, id: \.self) { servicio in
                                let activo = areasDeServicio.contains(servicio)
                                Button {
                                    if activo { areasDeServicio.remove(servicio) }
                                    else      { areasDeServicio.insert(servicio) }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: activo ? "checkmark.circle.fill" : "circle")
                                            .font(.caption)
                                            .foregroundStyle(activo ? Color.caritasPrimario : Color.caritasGris)
                                        Text(servicio)
                                            .font(.subheadline)
                                            .foregroundStyle(activo ? Color.caritasPrimario : Color.caritasAzul)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12).padding(.vertical, 10)
                                    .background(activo ? Color.caritasSuave : Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(activo ? Color.caritasPrimario : Color.clear, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    campoTexto("Cédula / Matrícula (opcional)", text: $matricula, foco: .matricula, siguiente: nil)

                    if esEdicion {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Estado").font(.caption).foregroundStyle(Color.caritasGris)
                            HStack(spacing: 10) {
                                botonEstado("Activo",   activo: true)
                                botonEstado("Inactivo", activo: false)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationTitle(esEdicion ? "Editar personal" : "Registrar personal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(Color.caritasGris)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .foregroundStyle(puedeGuardar ? Color.caritasPrimario : Color.caritasGris)
                        .fontWeight(.semibold).disabled(!puedeGuardar)
                }
            }
        }
        .onAppear { cargarDatos() }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func campoTexto(_ etiqueta: String, placeholder: String = "", text: Binding<String>, foco f: CampoPersonal, siguiente: CampoPersonal?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta).font(.caption).foregroundStyle(Color.caritasGris)
            TextField(placeholder.isEmpty ? etiqueta : placeholder, text: text)
                .padding(12).background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .font(.subheadline)
                .focused($foco, equals: f)
                .submitLabel(siguiente != nil ? .next : .done)
                .onSubmit { foco = siguiente }
        }
    }

    private func botonSexo(_ etiqueta: String, valor: Sexo) -> some View {
        let sel = sexo == valor
        return Button { sexo = valor } label: {
            Text(etiqueta).font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(sel ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(sel ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(sel ? Color.caritasPrimario : Color.clear, lineWidth: 1))
        }
    }

    private func botonEstado(_ etiqueta: String, activo: Bool) -> some View {
        let sel = esActivo == activo
        return Button { esActivo = activo } label: {
            Text(etiqueta).font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(sel ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(sel ? Color.caritasPrimario : Color.caritasGris)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(sel ? Color.caritasPrimario : Color.clear, lineWidth: 1))
        }
    }

    // MARK: - CURP

    private func actualizarCURP() { curp = calcularCURP() }

    private func calcularCURP() -> String {
        let vowels     = CharacterSet(charactersIn: "AEIOU")
        let consonants = CharacterSet(charactersIn: "BCDFGHJKLMNPQRSTVWXYZ")

        func limpiar(_ s: String) -> String {
            s.uppercased().folding(options: .diacriticInsensitive, locale: .current).filter { $0.isLetter }
        }

        let pals = apellidos.split(separator: " ").map { limpiar(String($0)) }
        let pa = pals.count > 0 ? pals[0] : "X"
        let sa = pals.count > 1 ? pals[1] : ""
        let nm = limpiar(nombre.split(separator: " ").first.map(String.init) ?? nombre)

        let l1 = pa.isEmpty ? "X" : String(pa.prefix(1))
        let l2 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: vowels) != nil }).map(String.init) ?? "X"
        let l3 = sa.isEmpty ? "X" : String(sa.prefix(1))
        let l4 = nm.isEmpty ? "X" : String(nm.prefix(1))

        let cal = Calendar.current
        let yy = String(format: "%02d", cal.component(.year,  from: fechaNacimiento) % 100)
        let mm = String(format: "%02d", cal.component(.month, from: fechaNacimiento))
        let dd = String(format: "%02d", cal.component(.day,   from: fechaNacimiento))
        let sx = (sexo == .masculino) ? "H" : "M"
        let st = estadosCodes.first(where: { $0.nombre == estadoNacimiento })?.codigo ?? "NL"
        let c1 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        let c2 = sa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        let c3 = nm.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil }).map(String.init) ?? "X"
        let hcv = curp.count == 18 ? String(curp.suffix(2)) : "00"

        return "\(l1)\(l2)\(l3)\(l4)\(yy)\(mm)\(dd)\(sx)\(st)\(c1)\(c2)\(c3)\(hcv)"
    }

    // MARK: - Persistencia

    private func cargarDatos() {
        guard let p = personal else { return }
        nombre      = p.nombrePersonal
        apellidos   = p.apellidosPersonal
        curp        = p.curpPersonal
        sexo        = p.sexoPersonal
        especialidad = p.especialidad
        areasDeServicio = Set(p.areasDeServicio)
        matricula   = p.matricula ?? ""
        esActivo    = p.esActivo
        parsearFechaYEstadoDeCURP(p.curpPersonal)
    }

    private func parsearFechaYEstadoDeCURP(_ c: String) {
        let upper = c.uppercased()
        guard upper.count == 18 else { return }
        let chars = Array(upper)
        if let yy = Int(String(chars[4...5])), let mm = Int(String(chars[6...7])),
           let dd = Int(String(chars[8...9])), mm >= 1, mm <= 12, dd >= 1, dd <= 31 {
            let currentYY = Calendar.current.component(.year, from: Date()) % 100
            let fullYear  = yy > currentYY ? 1900 + yy : 2000 + yy
            var comps = DateComponents(); comps.year = fullYear; comps.month = mm; comps.day = dd
            if let date = Calendar.current.date(from: comps) { fechaNacimiento = date }
        }
        let stateCode = String(chars[11...12])
        if let estado = estadosCodes.first(where: { $0.codigo == stateCode })?.nombre { estadoNacimiento = estado }
    }

    private func guardar() {
        let matFinal = matricula.trimmingCharacters(in: .whitespaces).isEmpty ? nil : matricula
        let areas    = areasDeServicio.sorted()
        if let p = personal {
            p.nombrePersonal    = nombre.trimmingCharacters(in: .whitespaces)
            p.apellidosPersonal = apellidos.trimmingCharacters(in: .whitespaces)
            p.curpPersonal      = curp.uppercased().trimmingCharacters(in: .whitespaces)
            p.sexoPersonal      = sexo
            p.especialidad      = especialidad
            p.areasDeServicio   = areas
            p.matricula         = matFinal
            p.esActivo          = esActivo
        } else {
            modelContext.insert(Personal(
                curpPersonal:      curp,
                nombrePersonal:    nombre.trimmingCharacters(in: .whitespaces),
                apellidosPersonal: apellidos.trimmingCharacters(in: .whitespaces),
                sexoPersonal:      sexo,
                especialidad:      especialidad,
                areasDeServicio:   areas,
                matricula:         matFinal
            ))
        }
        dismiss()
    }
}

#Preview {
    PersonalView()
        .modelContainer(for: [Personal.self, Jornada.self, Consulta.self], inMemory: true)
}
