import Foundation

nonisolated struct PageResult<T: Codable & Sendable>: Codable, Sendable {
    let items: [T]
    let totalItems: Int
}
