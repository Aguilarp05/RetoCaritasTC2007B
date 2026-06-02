import SwiftUI
import UIKit

extension Color {
    // Acentos de marca — funcionan igual en claro y oscuro
    static let caritasPrimario  = Color(hex: "#009CA6")
    static let caritasAcento    = Color(hex: "#FF7F32")

    // Tokens adaptativos (claro / oscuro)
    // caritasAzul se usa como color de TEXTO principal: navy en claro, casi-blanco en oscuro
    static let caritasAzul      = Color(light: "#003B5C", dark: "#E8EEF2")
    // Texto secundario
    static let caritasGris      = Color(light: "#888B8D", dark: "#9DA2A6")
    // Superficie suave (franjas de encabezado, tarjetas seleccionadas)
    static let caritasSuave     = Color(light: "#D1E0D7", dark: "#15323A")
    // Texto de notas importantes
    static let caritasNota      = Color(light: "#633806", dark: "#E6A85C")

    // Variantes fijas para el sidebar, que siempre es un panel navy oscuro
    static let caritasAzulFijo  = Color(hex: "#003B5C")
    static let caritasSuaveFijo = Color(hex: "#D1E0D7")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Crea un color que se adapta automáticamente al modo claro u oscuro.
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
