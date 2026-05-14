import SwiftUI

extension Color {
    static let caritasPrimario  = Color(hex: "#009CA6")
    static let caritasAcento    = Color(hex: "#FF7F32")
    static let caritasAzul      = Color(hex: "#003B5C")
    static let caritasGris      = Color(hex: "#888B8D")
    static let caritasSuave     = Color(hex: "#D1E0D7")
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
}
