import SwiftUI
import SwiftData

struct PersonalView: View {
    @Environment(\.toggleSidebar) private var toggleSidebar
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Personal.nombrePersonal) private var todoElPersonal: [Personal]

    @State private var mostrarFormulario = false
    @State private var personalAEditar: Personal? = nil

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Button { toggleSidebar() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(Color.caritasAzul)
                }
                .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Personal médico")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasAzul)
                    Text("Equipo registrado en el sistema")
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                }

                Spacer()

                Button {
                    personalAEditar = nil
                    mostrarFormulario = true
                } label: {
                    Label("Registrar", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.caritasAcento)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.caritasSuave)

            Divider()

            if todoElPersonal.isEmpty {
                estadoVacio
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(todoElPersonal) { persona in
                            filaPersonal(persona)
                            Divider()
                                .padding(.leading, 90)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .colorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarFormulario) {
            FormularioPersonalView(personal: personalAEditar)
        }
    }

    private func filaPersonal(_ persona: Personal) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(persona.esActivo ? Color.caritasSuave : Color(.systemGray5))
                    .frame(width: 54, height: 54)
                Text(iniciales(de: persona))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(persona.esActivo ? Color.caritasPrimario : Color.caritasGris)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(persona.nombreCompleto)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(persona.esActivo ? Color.caritasAzul : Color.caritasGris)
                    if !persona.esActivo {
                        Text("Inactivo")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.caritasGris)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
                Text(persona.especialidad)
                    .font(.caption)
                    .foregroundStyle(Color.caritasPrimario)
                Text(persona.curpPersonal)
                    .font(.caption2)
                    .foregroundStyle(Color.caritasGris)
                    .monospaced()
            }

            Spacer()

            if let mat = persona.matricula {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cédula")
                        .font(.caption2)
                        .foregroundStyle(Color.caritasGris)
                    Text(mat)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.caritasAzul)
                }
            }

            Menu {
                Button {
                    personalAEditar = persona
                    mostrarFormulario = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                Button {
                    persona.esActivo.toggle()
                } label: {
                    Label(
                        persona.esActivo ? "Marcar como inactivo" : "Marcar como activo",
                        systemImage: persona.esActivo ? "person.slash" : "person.badge.checkmark"
                    )
                }
                Divider()
                Button(role: .destructive) {
                    modelContext.delete(persona)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Color.caritasGris)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var estadoVacio: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundStyle(Color.caritasGris.opacity(0.35))
            Text("Sin personal registrado")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.caritasAzul)
            Text("Registra al equipo médico para asignarlo a jornadas y consultas.")
                .font(.subheadline)
                .foregroundStyle(Color.caritasGris)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button {
                personalAEditar = nil
                mostrarFormulario = true
            } label: {
                Label("Registrar personal", systemImage: "person.badge.plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.caritasAcento)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func iniciales(de persona: Personal) -> String {
        "\(persona.nombrePersonal) \(persona.apellidosPersonal)"
            .split(separator: " ").prefix(2)
            .compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

// MARK: - Formulario de alta / edición

struct FormularioPersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let personal: Personal?

    @State private var nombre = ""
    @State private var apellidos = ""
    @State private var fechaNacimiento: Date = Calendar.current.date(
        byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sexo = Sexo.noDefinido
    @State private var estadoNacimiento = "Nuevo León"
    @State private var curp = ""
    @State private var especialidad = ""
    @State private var matricula = ""
    @State private var esActivo = true

    @FocusState private var foco: CampoPersonal?

    private enum CampoPersonal: Hashable { case nombre, apellidos, curp, matricula }

    private let especialidades = [
        "Consulta general", "Consulta dental", "Optometrista", "Entrega de medicamentos",
    ]

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
                        .onChange(of: nombre) { _, _ in if !esEdicion { actualizarCURP() } }

                    campoTexto("Apellidos *", text: $apellidos, foco: .apellidos, siguiente: .matricula)
                        .onChange(of: apellidos) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha de nacimiento")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                        DatePicker("", selection: $fechaNacimiento, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .onChange(of: fechaNacimiento) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sexo *")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                        HStack(spacing: 10) {
                            botonSexo("Femenino", valor: .femenino)
                            botonSexo("Masculino", valor: .masculino)
                        }
                    }
                    .onChange(of: sexo) { _, _ in if !esEdicion { actualizarCURP() } }

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
                    .onChange(of: estadoNacimiento) { _, _ in if !esEdicion { actualizarCURP() } }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("CURP *")
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                            Spacer()
                            Button {
                                actualizarCURP()
                            } label: {
                                Label("Regenerar", systemImage: "wand.and.stars")
                                    .font(.caption)
                                    .foregroundStyle(Color.caritasPrimario)
                            }
                        }
                        TextField("CURP", text: $curp)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.subheadline.monospaced())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($foco, equals: .curp)
                            .submitLabel(.next)
                            .onSubmit { foco = .matricula }
                            .onChange(of: curp) { _, nuevo in curp = String(nuevo.uppercased().prefix(18)) }
                        if !curp.isEmpty && curp.count != 18 {
                            Text("\(curp.count)/18 caracteres")
                                .font(.caption2)
                                .foregroundStyle(Color.caritasAcento)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Especialidad / Rol *")
                            .font(.caption)
                            .foregroundStyle(Color.caritasGris)
                        Picker("Especialidad", selection: $especialidad) {
                            Text("Selecciona una especialidad").tag("")
                            ForEach(especialidades, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    campoTexto("Cédula / matrícula (opcional)",
                               text: $matricula, foco: .matricula, siguiente: nil)

                    if esEdicion {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Estado")
                                .font(.caption)
                                .foregroundStyle(Color.caritasGris)
                            HStack(spacing: 10) {
                                botonEstado("Activo", activo: true)
                                botonEstado("Inactivo", activo: false)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .colorScheme(.light)
            .navigationTitle(esEdicion ? "Editar personal" : "Registrar personal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Color.caritasGris)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .foregroundStyle(puedeGuardar ? Color.caritasPrimario : Color.caritasGris)
                        .fontWeight(.semibold)
                        .disabled(!puedeGuardar)
                }
            }
        }
        .onAppear { cargarDatos() }
    }

    // MARK: - Helpers de layout

    @ViewBuilder
    private func campoTexto(
        _ etiqueta: String, placeholder: String = "",
        text: Binding<String>, foco f: CampoPersonal, siguiente: CampoPersonal?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etiqueta)
                .font(.caption)
                .foregroundStyle(Color.caritasGris)
            TextField(placeholder.isEmpty ? etiqueta : placeholder, text: text)
                .padding(12)
                .background(Color(.systemGray6))
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

    private func botonEstado(_ etiqueta: String, activo: Bool) -> some View {
        let sel = esActivo == activo
        return Button { esActivo = activo } label: {
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

    // MARK: - CURP

    private func actualizarCURP() {
        curp = calcularCURP()
    }

    private func calcularCURP() -> String {
        let vowels    = CharacterSet(charactersIn: "AEIOU")
        let consonants = CharacterSet(charactersIn: "BCDFGHJKLMNPQRSTVWXYZ")

        func limpiar(_ s: String) -> String {
            s.uppercased()
             .folding(options: .diacriticInsensitive, locale: .current)
             .filter { $0.isLetter }
        }

        let palabrasApellidos = apellidos.split(separator: " ").map { limpiar(String($0)) }
        let pa = palabrasApellidos.count > 0 ? palabrasApellidos[0] : "X"
        let sa = palabrasApellidos.count > 1 ? palabrasApellidos[1] : ""
        let nm = limpiar(nombre.split(separator: " ").first.map(String.init) ?? nombre)

        let l1 = pa.isEmpty ? "X" : String(pa.prefix(1))
        let l2 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: vowels) != nil })
                   .map(String.init) ?? "X"
        let l3 = sa.isEmpty ? "X" : String(sa.prefix(1))
        let l4 = nm.isEmpty ? "X" : String(nm.prefix(1))

        let cal = Calendar.current
        let yy  = String(format: "%02d", cal.component(.year,  from: fechaNacimiento) % 100)
        let mm  = String(format: "%02d", cal.component(.month, from: fechaNacimiento))
        let dd  = String(format: "%02d", cal.component(.day,   from: fechaNacimiento))

        let sx = (sexo == .masculino) ? "H" : "M"
        let st = estadosCodes.first(where: { $0.nombre == estadoNacimiento })?.codigo ?? "NL"

        let c1 = pa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil })
                   .map(String.init) ?? "X"
        let c2 = sa.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil })
                   .map(String.init) ?? "X"
        let c3 = nm.dropFirst().first(where: { String($0).rangeOfCharacter(from: consonants) != nil })
                   .map(String.init) ?? "X"

        // Preserve last 2 chars (homoclave) if CURP was already 18 chars, else use "00"
        let hcv = curp.count == 18 ? String(curp.suffix(2)) : "00"

        return "\(l1)\(l2)\(l3)\(l4)\(yy)\(mm)\(dd)\(sx)\(st)\(c1)\(c2)\(c3)\(hcv)"
    }

    // MARK: - Persistencia

    private func cargarDatos() {
        guard let p = personal else { return }
        nombre = p.nombrePersonal
        apellidos = p.apellidosPersonal
        curp = p.curpPersonal
        sexo = p.sexoPersonal
        especialidad = p.especialidad
        matricula = p.matricula ?? ""
        esActivo = p.esActivo
        parsearFechaYEstadoDeCURP(p.curpPersonal)
    }

    private func parsearFechaYEstadoDeCURP(_ c: String) {
        let upper = c.uppercased()
        guard upper.count == 18 else { return }
        let chars = Array(upper)

        if let yy = Int(String(chars[4...5])),
           let mm = Int(String(chars[6...7])),
           let dd = Int(String(chars[8...9])),
           mm >= 1, mm <= 12, dd >= 1, dd <= 31 {
            let currentYY = Calendar.current.component(.year, from: Date()) % 100
            let fullYear  = yy > currentYY ? 1900 + yy : 2000 + yy
            var comps = DateComponents()
            comps.year = fullYear; comps.month = mm; comps.day = dd
            if let date = Calendar.current.date(from: comps) { fechaNacimiento = date }
        }

        let stateCode = String(chars[11...12])
        if let estado = estadosCodes.first(where: { $0.codigo == stateCode })?.nombre {
            estadoNacimiento = estado
        }
    }

    private func guardar() {
        let matFinal: String? = matricula.trimmingCharacters(in: .whitespaces).isEmpty ? nil : matricula
        if let p = personal {
            p.nombrePersonal    = nombre.trimmingCharacters(in: .whitespaces)
            p.apellidosPersonal = apellidos.trimmingCharacters(in: .whitespaces)
            p.curpPersonal      = curp.uppercased().trimmingCharacters(in: .whitespaces)
            p.sexoPersonal      = sexo
            p.especialidad      = especialidad
            p.matricula         = matFinal
            p.esActivo          = esActivo
        } else {
            let nuevo = Personal(
                curpPersonal:      curp,
                nombrePersonal:    nombre.trimmingCharacters(in: .whitespaces),
                apellidosPersonal: apellidos.trimmingCharacters(in: .whitespaces),
                sexoPersonal:      sexo,
                especialidad:      especialidad,
                matricula:         matFinal
            )
            modelContext.insert(nuevo)
        }
        dismiss()
    }
}

#Preview {
    PersonalView()
        .modelContainer(for: [Personal.self], inMemory: true)
}
