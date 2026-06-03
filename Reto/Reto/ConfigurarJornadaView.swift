import SwiftUI
import SwiftData

struct ConfigurarJornadaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Personal.nombrePersonal) private var todoElPersonal: [Personal]

    // Ubicación
    @State private var municipioSel = ""
    @State private var comunidad    = ""

    // Servicios
    @State private var serviciosSel: Set<String> = []

    // Personal
    @State private var personalSeleccionado: Set<UUID> = []

    private let todosServicios: [(nombre: String, icono: String)] = [
        ("Consulta general",        "stethoscope"),
        ("Consulta dental",         "mouth.fill"),
        ("Optometrista",            "eye.fill"),
        ("Entrega de medicamentos", "pills.fill"),
    ]

    private let municipiosAMM: [String] = [
        "Apodaca", "Cadereyta Jiménez", "Ciénega de Flores", "El Carmen",
        "García", "General Escobedo", "General Zuazua", "Guadalupe",
        "Juárez", "Monterrey", "Pesquería", "Salinas Victoria",
        "San Nicolás de los Garza", "San Pedro Garza García",
        "Santa Catarina", "Santiago",
    ]

    private var puedeIniciar: Bool {
        !municipioSel.isEmpty && !serviciosSel.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {

            // Encabezado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nueva jornada")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.caritasAzul)
                    Text(Date().formatted(.dateTime.day().month(.wide).year()))
                        .font(.subheadline)
                        .foregroundStyle(Color.caritasGris)
                }
                Spacer()
                Button { iniciarJornada() } label: {
                    Text("Iniciar jornada")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(puedeIniciar ? Color.caritasPrimario : Color.caritasGris)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!puedeIniciar)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.caritasSuave)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Ubicación
                    seccionHeader("Ubicación de la jornada")

                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Municipio")
                                .font(.caption).foregroundStyle(Color.caritasGris)
                            Picker("Municipio", selection: $municipioSel) {
                                Text("Selecciona un municipio").tag("")
                                ForEach(municipiosAMM, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comunidad / Localidad")
                                .font(.caption).foregroundStyle(Color.caritasGris)
                            TextField("Nombre de la comunidad o colonia", text: $comunidad)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    Divider()

                    // MARK: Servicios
                    seccionHeader("Servicios disponibles hoy")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(todosServicios, id: \.nombre) { servicio in
                            botonServicio(nombre: servicio.nombre, icono: servicio.icono)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    Divider()

                    // MARK: Personal
                    seccionHeader("Personal en turno")

                    if todoElPersonal.filter({ $0.esActivo }).isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(Color.caritasGris)
                            Text("No hay personal registrado. Ve a 'Personal medico' para dar de alta al equipo.")
                                .font(.subheadline)
                                .foregroundStyle(Color.caritasGris)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(todoElPersonal.filter { $0.esActivo }) { persona in
                                let seleccionado = personalSeleccionado.contains(persona.idPersonal)
                                Button {
                                    if seleccionado { personalSeleccionado.remove(persona.idPersonal) }
                                    else            { personalSeleccionado.insert(persona.idPersonal) }
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(seleccionado ? Color.caritasPrimario : Color(.systemGray4))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(persona.nombreCompleto)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.caritasAzul)
                                            Text(persona.curpPersonal)
                                                .font(.caption)
                                                .foregroundStyle(Color.caritasGris)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(seleccionado ? Color.caritasSuave : Color(.systemBackground))
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.leading, 62)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground))
        .colorScheme(.light)
    }

    // MARK: - Helpers

    private func seccionHeader(_ titulo: String) -> some View {
        Text(titulo.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.caritasGris)
            .kerning(0.5)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func botonServicio(nombre: String, icono: String) -> some View {
        let seleccionado = serviciosSel.contains(nombre)
        return Button {
            if seleccionado { serviciosSel.remove(nombre) }
            else            { serviciosSel.insert(nombre) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icono)
                    .font(.title3)
                    .foregroundStyle(seleccionado ? Color.caritasPrimario : Color.caritasGris)
                    .frame(width: 28)
                Text(nombre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(seleccionado ? Color.caritasPrimario : Color.caritasAzul)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(seleccionado ? Color.caritasPrimario : Color(.systemGray4))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(seleccionado ? Color.caritasSuave : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(seleccionado ? Color.caritasPrimario : Color.clear, lineWidth: 1)
            )
        }
    }

    private func iniciarJornada() {
        let seleccionados = todoElPersonal.filter { personalSeleccionado.contains($0.idPersonal) }

        let locacion = Locacion(
            estado:    "Nuevo León",
            municipio: municipioSel,
            comunidad: comunidad.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comunidad
        )
        modelContext.insert(locacion)

        let jornada = Jornada(
            locacion:             locacion,
            fecha:                Date(),
            serviciosDisponibles: Array(serviciosSel),
            personalNombres:      seleccionados.map { $0.nombreCompleto }
        )
        jornada.personal = seleccionados
        modelContext.insert(jornada)
        try? modelContext.save()

        dismiss()
    }
}

#Preview {
    ConfigurarJornadaView()
        .modelContainer(
            for: [Jornada.self, Locacion.self, Personal.self],
            inMemory: true
        )
}
