import Foundation

/// Genera un identificador único propio de Cáritas con el formato:
/// [2 letras nombre][2 letras segundo nombre o XX][YYMMDD][3 letras municipio][M/F/X]
/// Ejemplo: LUXX920312DURF
func generarCaritasId(
    primerNombre: String,
    segundoNombre: String?,
    fechaNacimiento: Date,
    municipio: String,
    sexo: Sexo
) -> String {
    let n1 = segmento(primerNombre, longitud: 2)
    let n2: String
    if let seg = segundoNombre, !seg.trimmingCharacters(in: .whitespaces).isEmpty {
        n2 = segmento(seg, longitud: 2)
    } else {
        n2 = "XX"
    }

    let comps = Calendar.current.dateComponents([.year, .month, .day], from: fechaNacimiento)
    let yy = String(format: "%02d", (comps.year  ?? 0) % 100)
    let mm = String(format: "%02d",  comps.month ?? 0)
    let dd = String(format: "%02d",  comps.day   ?? 0)

    let lugar = segmento(municipio, longitud: 3)

    let s: String
    switch sexo {
    case .masculino:  s = "M"
    case .femenino:   s = "F"
    case .noDefinido: s = "X"
    }

    return "\(n1)\(n2)\(yy)\(mm)\(dd)\(lugar)\(s)"
}

// Normaliza texto (sin tildes, solo letras, mayúsculas) y toma los primeros `longitud` chars.
// Si hay menos chars que `longitud`, rellena con "X".
private func segmento(_ texto: String, longitud: Int) -> String {
    let limpio = texto
        .folding(options: .diacriticInsensitive, locale: .current)
        .uppercased()
        .filter { $0.isLetter }
    let resultado = String(limpio.prefix(longitud))
    return resultado.padding(toLength: longitud, withPad: "X", startingAt: 0)
}
