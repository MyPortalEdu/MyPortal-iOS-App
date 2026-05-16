import Foundation

/// In-memory `APIClient` for SwiftUI previews and tests. Seed canned responses
/// by path; calls for unseeded paths throw a 404 so previews surface what they're
/// missing instead of silently spinning.
nonisolated struct MockAPIClient: APIClient {
    private var getResponses: [String: Data] = [:]
    private var postResponses: [String: Data] = [:]
    private let latency: Duration

    init(latency: Duration = .zero) {
        self.latency = latency
    }

    /// Returns a new mock with a canned GET response for `path`.
    func stubbingGet<E: Encodable>(_ path: String, with value: E) -> MockAPIClient {
        var copy = self
        copy.getResponses[path] = (try? Self.encoder.encode(value)) ?? Data()
        return copy
    }

    /// Returns a new mock with a canned POST response for `path`.
    func stubbingPost<E: Encodable>(_ path: String, with value: E) -> MockAPIClient {
        var copy = self
        copy.postResponses[path] = (try? Self.encoder.encode(value)) ?? Data()
        return copy
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = FlexibleDate.decodingStrategy
        return d
    }()

    func get<T: Decodable & Sendable>(_ path: String, authenticated: Bool) async throws -> T {
        try await waitIfNeeded()
        guard let data = getResponses[path] else {
            throw APIError.http(status: 404, body: "MockAPIClient: no GET stub for \(path)")
        }
        return try decode(data)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: Data?, contentType: String, authenticated: Bool) async throws -> T {
        try await waitIfNeeded()
        guard let data = postResponses[path] else {
            throw APIError.http(status: 404, body: "MockAPIClient: no POST stub for \(path)")
        }
        return try decode(data)
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func waitIfNeeded() async throws {
        if latency > .zero {
            try await Task.sleep(for: latency)
        }
    }
}
