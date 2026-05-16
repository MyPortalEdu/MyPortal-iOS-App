import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case missingSchoolConfig
    case notAuthenticated
    case http(status: Int, body: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL is not valid."
        case .missingSchoolConfig: return "No school is configured."
        case .notAuthenticated: return "You're signed out."
        case .http(let status, let body):
            if let body, !body.isEmpty { return "Server error \(status): \(body)" }
            return "Server error \(status)."
        case .decoding(let err): return "Couldn't read the response (\(err.localizedDescription))."
        case .transport(let err): return err.localizedDescription
        }
    }
}
