import Foundation

/// Response from the anonymous `GET /api/system/identify` endpoint. The client
/// pins on `product == "MyPortal"` so a random 200-returning server can't pass
/// for a MyPortal instance.
nonisolated struct SystemIdentity: Decodable, Sendable, Equatable {
    let product: String
    let version: String?
    let schoolName: String?
}

/// Unauthenticated probe used by `SchoolSetupView` to confirm a URL points at a
/// MyPortal instance and to surface the school's name on the setup screen. The
/// user isn't signed in yet, so this can't go through `APIClient`'s
/// bearer-token path.
protocol ServerIdentityService: Sendable {
    func identify(at baseURL: URL) async throws -> SystemIdentity
}

nonisolated struct LiveServerIdentityService: ServerIdentityService {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func identify(at baseURL: URL) async throws -> SystemIdentity {
        guard let url = URL(string: "api/v1/system/identify", relativeTo: baseURL) else {
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

        let identity: SystemIdentity
        do {
            identity = try JSONDecoder().decode(SystemIdentity.self, from: data)
        } catch {
            // A non-MyPortal server returning a 200 with some unrelated JSON
            // shape lands here. Treat the decode failure as "not a MyPortal
            // server" so the UI shows the friendlier message rather than a
            // raw decoding error.
            throw APIError.notMyPortal
        }

        // Pin on the product identifier. The server always returns "MyPortal";
        // anything else means we hit something that happens to expose
        // `/api/system/identify` with a compatible shape but isn't us.
        guard identity.product == "MyPortal" else {
            throw APIError.notMyPortal
        }

        return identity
    }
}

nonisolated struct MockServerIdentityService: ServerIdentityService {
    var result: Result<SystemIdentity, APIError>

    init(identity: SystemIdentity) { self.result = .success(identity) }
    init(failing error: APIError) { self.result = .failure(error) }

    func identify(at baseURL: URL) async throws -> SystemIdentity {
        try result.get()
    }
}
