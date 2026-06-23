import SwiftUI

// Campo de texto que muestra sugerencias del historial mientras el médico escribe.
// El caller pasa `sugerencias` ya ordenadas por frecuencia; este componente solo filtra y muestra.
struct CampoAutocomplete: View {
    let titulo: String
    @Binding var texto: String
    let sugerencias: [String]

    @FocusState private var enfocado: Bool
    @State private var seleccionando = false

    // Búsqueda por subcadena, sin tildes ni mayúsculas. Máximo 5 resultados. Excluye match exacto.
    private var filtradas: [String] {
        guard !texto.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = texto
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        return sugerencias
            .filter {
                let s = $0.folding(options: .diacriticInsensitive, locale: .current).lowercased()
                return s.contains(q) && s != q
            }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(Color.caritasGris)
                TextField(titulo, text: $texto, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($enfocado)
            }

            // Lista flotante — solo mientras el campo está activo y hay coincidencias
            if enfocado && !filtradas.isEmpty {
                VStack(spacing: 0) {
                    ForEach(filtradas, id: \.self) { sug in
                        Button {
                            seleccionando = true
                            texto = sug
                            enfocado = false
                            seleccionando = false
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                    .foregroundStyle(Color.caritasGris)
                                Text(sug)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.caritasAzul)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if sug != filtradas.last {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.caritasPrimario.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.15), value: filtradas.count)
            }
        }
    }
}
