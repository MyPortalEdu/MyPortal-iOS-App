import SwiftUI

/// Indigo brand palette mirroring Tailwind's `indigo-*` scale used by the SPA.
/// Prefer `Color.accentColor` (driven by the AccentColor asset) for tint;
/// reach for these constants only when a specific shade is needed (gradients,
/// branded surfaces, illustrations).
enum Brand {
    static let indigo50  = Color(hex: "#EEF2FF")
    static let indigo100 = Color(hex: "#E0E7FF")
    static let indigo200 = Color(hex: "#C7D2FE")
    static let indigo300 = Color(hex: "#A5B4FC")
    static let indigo400 = Color(hex: "#818CF8")
    static let indigo500 = Color(hex: "#6366F1")
    static let indigo600 = Color(hex: "#4F46E5")
    static let indigo700 = Color(hex: "#4338CA")
    static let indigo800 = Color(hex: "#3730A3")
    static let indigo900 = Color(hex: "#312E81")
    static let indigo950 = Color(hex: "#1E1B4B")

    /// The same value the AccentColor asset uses for light mode. Useful when a
    /// gradient or illustration must show the brand colour even if the user
    /// has overridden the system tint.
    static let primary = indigo500
}
