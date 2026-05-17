import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case missingSchoolConfig
    case notAuthenticated
    /// Server responded but didn't identify as MyPortal — typically because the
    /// URL points at an unrelated web service that happens to return a 200.
    case notMyPortal
    case http(status: Int, body: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "The URL is not valid.")
        case .missingSchoolConfig:
            return String(localized: "No school is configured.")
        case .notAuthenticated:
            return String(localized: "You're signed out.")
        case .notMyPortal:
            return String(localized: "That URL responded, but it doesn't look like a MyPortal server.")
        case .http(let status, let body):
            if let body, !body.isEmpty {
                return String(localized: "Server error \(status): \(body)")
            }
            return String(localized: "Server error \(status).")
        case .decoding(let err):
            return String(localized: "Couldn't read the response (\(err.localizedDescription)).")
        case .transport(let err):
            return err.localizedDescription
        }
    }
}
