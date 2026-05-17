import Foundation

/// Unauthenticated lookups against a school's API. Used by `SchoolSetupView`
/// to validate the URL the user entered and read back the school's name —
/// the user isn't signed in yet, so this can't go through `APIClient`'s
/// bearer-token path.
protocol SchoolService: Sendable {
    func name(at baseURL: URL) async throws -> String
}

nonisolated struct LiveSchoolService: SchoolService {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func name(at baseURL: URL) async throws -> String {
        guard let url = URL(string: "api/schools/local/name", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.dataAllowingDevCert(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        // Endpoint returns a JSON-encoded string ("Acme School") or an empty body
        // when no school is configured yet — accept both.
        if let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

nonisolated struct MockSchoolService: SchoolService {
    var result: Result<String, APIError>

    init(name: String) { self.result = .success(name) }
    init(failing error: APIError) { self.result = .failure(error) }

    func name(at baseURL: URL) async throws -> String {
        try result.get()
    }
}
