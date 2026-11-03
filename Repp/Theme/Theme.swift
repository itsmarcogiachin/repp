import SwiftUI

/// Colori e stili del brand Repp: nero, rosa per le azioni, argento metallico al centro.
enum Theme {
    static let background = Color(hex: 0x0A0A0B)
    static let surface = Color(hex: 0x161618)
    static let surface2 = Color(hex: 0x232327)
    static let line = Color(hex: 0x3A3A40)
    static let text = Color(hex: 0xF5F3F4)
    static let textSecondary = Color(hex: 0xA8A8B0)
    /// Rosa: lavoro e azioni principali.
    static let pink = Color(hex: 0xFF4F9A)
    static let pinkText = Color(hex: 0xFF7AB3)
    /// Argento: riposo, dettagli, titoli.
    static let silver = Color(hex: 0xC9CCD3)

    /// Argento spazzolato, usato per logo, titoli, timer e numeri chiave.
    static let metal = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xF4F5F7), location: 0),
            .init(color: Color(hex: 0xA9ADB5), location: 0.40),
            .init(color: Color(hex: 0xE6E8EC), location: 0.62),
            .init(color: Color(hex: 0x8E929A), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension View {
    /// Testo in argento metallico.
    func metallic() -> some View {
        foregroundStyle(Theme.metal)
    }
}

extension Font {
    /// Titoli e numeri: per ora il font di sistema; Archivo e Inter si aggiungono più avanti.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
