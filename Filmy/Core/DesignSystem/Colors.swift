import SwiftUI

extension Color {
    static let filmyBackground = Color(red: 0.047, green: 0.043, blue: 0.063)
    static let filmySurface = Color(red: 0.102, green: 0.098, blue: 0.129)
    static let filmySurfaceRaised = Color(red: 0.145, green: 0.141, blue: 0.18)
    /// Saffron. Also set as the asset catalog AccentColor.
    static let filmyAccent = Color(red: 1.0, green: 0.541, blue: 0.239)
    static let filmySecondaryText = Color.white.opacity(0.62)
    static let filmyTertiaryText = Color.white.opacity(0.4)

    static let ratingHigh = Color(red: 0.298, green: 0.851, blue: 0.392)
    static let ratingMid = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let ratingLow = Color(red: 1.0, green: 0.42, blue: 0.36)
}

/// Gradients for demo-mode posters, picked by movie id so each title keeps its look.
enum PosterPalette {
    static let gradients: [[Color]] = [
        [Color(red: 0.98, green: 0.45, blue: 0.24), Color(red: 0.42, green: 0.09, blue: 0.27)],
        [Color(red: 0.16, green: 0.55, blue: 0.82), Color(red: 0.07, green: 0.13, blue: 0.33)],
        [Color(red: 0.55, green: 0.32, blue: 0.91), Color(red: 0.16, green: 0.06, blue: 0.33)],
        [Color(red: 0.13, green: 0.72, blue: 0.58), Color(red: 0.03, green: 0.21, blue: 0.24)],
        [Color(red: 0.95, green: 0.76, blue: 0.25), Color(red: 0.55, green: 0.2, blue: 0.08)],
        [Color(red: 0.91, green: 0.3, blue: 0.48), Color(red: 0.24, green: 0.05, blue: 0.2)],
        [Color(red: 0.36, green: 0.42, blue: 0.53), Color(red: 0.08, green: 0.09, blue: 0.14)],
    ]

    static let symbols = ["film", "moon.stars.fill", "sparkles", "flame.fill", "wind", "bolt.fill", "leaf.fill", "airplane", "music.note", "star.fill", "theatermasks.fill"]

    static func colors(for id: Int) -> [Color] {
        gradients[abs(id) % gradients.count]
    }

    static func symbol(for id: Int) -> String {
        symbols[abs(id / 3) % symbols.count]
    }
}
