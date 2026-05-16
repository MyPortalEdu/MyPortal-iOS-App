import SwiftUI

extension Color {
    init(hex: String, fallback: Color = .accentColor) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard let value = UInt32(trimmed, radix: 16) else {
            self = fallback
            return
        }

        let r, g, b, a: Double
        switch trimmed.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double( value & 0x0000FF)        / 255
            a = 1
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8)  / 255
            a = Double( value & 0x000000FF)        / 255
        default:
            self = fallback
            return
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
