import Foundation

/// Abstraction over the school's HTTP API. Implementations:
/// - `LiveAPIClient` — real bearer-authenticated calls with refresh-on-401.
/// - `MockAPIClient` — canned responses for previews and tests.
protocol APIClient: Sendable {
    func get<T: Decodable & Sendable>(_ path: String, authenticated: Bool) async throws -> T
    func post<T: Decodable & Sendable>(_ path: String, body: Data?, contentType: String, authenticated: Bool) async throws -> T
}

extension APIClient {
    func get<T: Decodable & Sendable>(_ path: String) async throws -> T {
        try await get(path, authenticated: true)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: Data?, contentType: String = "application/json") async throws -> T {
        try await post(path, body: body, contentType: contentType, authenticated: true)
    }
}

nonisolated struct EmptyResponse: Decodable, Sendable {}
