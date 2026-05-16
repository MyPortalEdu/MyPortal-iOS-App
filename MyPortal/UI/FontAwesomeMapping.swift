import Foundation

/// Best-effort mapping from the FontAwesome class strings the server stores
/// (e.g. `"fa-solid fa-bell"`) to SF Symbols. Anything we don't recognise
/// falls back to a default — categories are still distinguishable by colour
/// and name, so missing icons aren't catastrophic.
enum FontAwesomeMapping {
    static let fallback = "bell.fill"

    static func sfSymbol(for faClass: String) -> String {
        let token = stripPrefix(faClass)
        return map[token] ?? fallback
    }

    private static func stripPrefix(_ raw: String) -> String {
        let parts = raw.split(separator: " ").map(String.init)
        if let icon = parts.first(where: { $0.hasPrefix("fa-") && $0 != "fa-solid" && $0 != "fa-regular" && $0 != "fa-light" && $0 != "fa-thin" && $0 != "fa-brands" }) {
            return String(icon.dropFirst(3))
        }
        return raw
    }

    private static let map: [String: String] = [
        "bell":              "bell.fill",
        "bullhorn":          "megaphone.fill",
        "calendar":          "calendar",
        "calendar-day":      "calendar",
        "calendar-check":    "calendar.badge.checkmark",
        "circle-info":       "info.circle.fill",
        "info":              "info.circle.fill",
        "triangle-exclamation": "exclamationmark.triangle.fill",
        "exclamation":       "exclamationmark.circle.fill",
        "graduation-cap":    "graduationcap.fill",
        "book":              "book.fill",
        "book-open":         "book.fill",
        "chalkboard":        "person.bust",
        "chalkboard-user":   "person.bust",
        "user":              "person.fill",
        "users":             "person.2.fill",
        "user-group":        "person.3.fill",
        "school":            "building.columns.fill",
        "building":          "building.fill",
        "trophy":            "trophy.fill",
        "medal":             "medal.fill",
        "star":              "star.fill",
        "heart":             "heart.fill",
        "envelope":          "envelope.fill",
        "paperclip":         "paperclip",
        "clipboard":         "list.clipboard.fill",
        "clipboard-list":    "list.clipboard.fill",
        "file":              "doc.fill",
        "file-lines":        "doc.text.fill",
        "comment":           "bubble.left.fill",
        "comments":          "bubble.left.and.bubble.right.fill",
        "lightbulb":         "lightbulb.fill",
        "circle-check":      "checkmark.circle.fill",
        "check":             "checkmark",
        "xmark":             "xmark",
        "bookmark":          "bookmark.fill",
        "thumbtack":         "pin.fill",
        "flag":              "flag.fill",
        "music":             "music.note",
        "futbol":            "soccerball",
        "running":           "figure.run",
        "person-running":    "figure.run",
        "utensils":          "fork.knife",
        "bus":               "bus.fill",
        "car":               "car.fill"
    ]
}
