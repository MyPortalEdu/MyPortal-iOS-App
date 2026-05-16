import Foundation

actor LiveAPIClient: APIClient {
    /// Process-wide singleton. MainActor-isolated so its initializer runs in
    /// a known isolation context — callers reach it via the default arg on
    /// `AppSession.init`, which is also MainActor.
    @MainActor static let shared = LiveAPIClient(session: .shared)

    private let session: URLSession
    private let decoder: JSONDecoder
    private var refreshTask: Task<AuthTokens, Error>?

    init(session: URLSession) {
        self.session = session
        let d = JSONDecoder()
        d.dateDecodingStrategy = FlexibleDate.decodingStrategy
        self.decoder = d
    }

    func get<T: Decodable & Sendable>(_ path: String, authenticated: Bool) async throws -> T {
        try await send(path: path, method: "GET", body: nil, authenticated: authenticated)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: Data?, contentType: String, authenticated: Bool) async throws -> T {
        try await send(path: path, method: "POST", body: body, contentType: contentType, authenticated: authenticated)
    }

    func put<T: Decodable & Sendable>(_ path: String, body: Data?, contentType: String, authenticated: Bool) async throws -> T {
        try await send(path: path, method: "PUT", body: body, contentType: contentType, authenticated: authenticated)
    }

    func delete<T: Decodable & Sendable>(_ path: String, authenticated: Bool) async throws -> T {
        try await send(path: path, method: "DELETE", body: nil, authenticated: authenticated)
    }

    private func send<T: Decodable & Sendable>(
        path: String,
        method: String,
        body: Data?,
        contentType: String = "application/json",
        authenticated: Bool
    ) async throws -> T {
        let request = try buildRequest(path: path, method: method, body: body, contentType: contentType, authenticated: authenticated)
        let (data, response) = try await perform(request: request, authenticated: authenticated)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func buildRequest(
        path: String,
        method: String,
        body: Data?,
        contentType: String,
        authenticated: Bool
    ) throws -> URLRequest {
        guard let config = SchoolConfigStore.load() else { throw APIError.missingSchoolConfig }
        guard let url = URL(string: path, relativeTo: config.baseURL)?.absoluteURL else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = body
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if authenticated {
            guard let tokens = TokenStore.load() else { throw APIError.notAuthenticated }
            req.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func perform(request: URLRequest, authenticated: Bool) async throws -> (Data, URLResponse) {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard authenticated, let http = response as? HTTPURLResponse, http.statusCode == 401 else {
            return (data, response)
        }

        // Try a refresh + retry once.
        do {
            _ = try await refreshTokensIfPossible()
        } catch {
            throw APIError.notAuthenticated
        }
        guard let tokens = TokenStore.load() else { throw APIError.notAuthenticated }
        var retry = request
        retry.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        do {
            return try await session.data(for: retry)
        } catch {
            throw APIError.transport(error)
        }
    }

    private func refreshTokensIfPossible() async throws -> AuthTokens {
        if let existing = refreshTask {
            return try await existing.value
        }
        let task = Task<AuthTokens, Error> { [self] in
            // `Task { … }` inherits actor isolation under the project's
            // approachable-concurrency mode, so `clearRefreshTask()` is a
            // direct (non-async) call back into self.
            defer { Task { self.clearRefreshTask() } }
            guard let current = TokenStore.load(), let refresh = current.refreshToken else {
                throw APIError.notAuthenticated
            }
            let tokens = try await OAuthService.shared.refresh(refreshToken: refresh)
            try TokenStore.save(tokens)
            return tokens
        }
        refreshTask = task
        return try await task.value
    }

    private func clearRefreshTask() {
        refreshTask = nil
    }
}
