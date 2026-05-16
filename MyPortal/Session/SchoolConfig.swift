import Foundation

nonisolated struct SchoolConfig: Codable, Equatable, Sendable {
    var baseURL: URL
    var name: String
}

#if DEBUG
nonisolated extension SchoolConfig {
    static let preview = SchoolConfig(
        baseURL: URL(string: "https://demo.myportal.example/")!,
        name: "Acme High School"
    )
}
#endif

nonisolated enum SchoolConfigStore {
    private static let key = "school.config"

    static func save(_ config: SchoolConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> SchoolConfig? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SchoolConfig.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
