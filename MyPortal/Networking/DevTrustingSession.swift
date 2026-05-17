import Foundation

nonisolated extension URLSession {
    /// Cancellation-resistant `data(for:)` for the API layer.
    ///
    /// Two reasons we wrap `dataTask(with:completionHandler:)` in a checked
    /// continuation instead of using the async `data(for:)` directly:
    ///
    /// 1. **Task cancellation.** The async `data(for:)` associates the URL
    ///    task with the calling Swift Task and cancels the URL task whenever
    ///    the Swift Task is cancelled. SwiftUI view churn under iOS 18+ can
    ///    cancel Tasks spuriously (we observed `Task.isCancelled` flipping
    ///    to true mid-load with no user-driven cancellation), which surfaced
    ///    as `URLError.cancelled` for every bulletin fetch. The callback API
    ///    is independent of Swift Concurrency — the URL task runs to
    ///    completion and the continuation resumes regardless of the Swift
    ///    Task's cancellation state.
    ///
    /// 2. **Dev cert handling.** Trust for the ASP.NET self-signed dev cert
    ///    is sourced from the simulator's CA store (one-off install via
    ///    `xcrun simctl keychain booted add-root-cert ~/aspnetdev.cer`).
    ///    No per-request delegate is needed.
    func dataAllowingDevCert(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
}
