import Foundation

extension String {
    /// Quita espacios al inicio/fin y colapsa espacios internos múltiples.
    var limpio: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Nombre propio: primera letra de cada palabra en mayúscula, resto minúscula.
    /// "JUAN   DE LA ROSA " → "Juan de la Rosa"
    var nombrePropio: String {
        let preposiciones: Set<String> = ["de", "del", "la", "las", "los", "y", "e", "el"]
        return limpio
            .lowercased()
            .components(separatedBy: " ")
            .enumerated()
            .map { idx, palabra in
                (idx == 0 || !preposiciones.contains(palabra))
                    ? palabra.prefix(1).uppercased() + palabra.dropFirst()
                    : palabra
            }
            .joined(separator: " ")
    }

    /// CURP / clave: todo mayúsculas, sin espacios.
    var codigoNormalizado: String {
        limpio.uppercased()
    }

    /// Texto libre (diagnóstico, motivo, notas): solo trim + primera letra mayúscula.
    var textoLibre: String {
        let t = limpio
        guard let primera = t.first else { return t }
        return primera.uppercased() + t.dropFirst()
    }
}
