import SwiftUI

struct SchoolSetupView: View {
    @Environment(AppSession.self) private var session
    @State private var urlText: String = ""
    @State private var status: Status = .idle
    @FocusState private var fieldFocused: Bool

    private enum Status: Equatable {
        case idle
        case checking
        case found(SchoolConfig)
        case error(String)
    }

    var body: some View {
        ZStack {
            BrandedBackground()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    card
                }
                .padding()
                .padding(.top, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { fieldFocused = true }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("MyPortal")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Connect to your school to get started.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("School portal URL")
                    .font(.headline)
                Text("Ask your school administrator if you're not sure. It usually looks like portal.yourschool.org.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("https://yourschool.example.com", text: $urlText)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .onSubmit(check)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )

            statusContent

            actionButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch status {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 10) {
                ProgressView()
                Text("Checking…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .found(let config):
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(config.name.isEmpty ? "your school" : config.name)
                        .font(.headline)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.12))
            )
        case .error(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
            )
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .found(let config):
            Button("Continue") { session.setSchool(config) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        default:
            Button(action: check) {
                Text("Check")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty || status == .checking)
        }
    }

    // MARK: - Actions

    private func check() {
        guard let url = normaliseURL(urlText) else {
            status = .error(String(localized: "That doesn't look like a valid URL."))
            return
        }
        status = .checking
        Task {
            do {
                let name = try await session.schoolService.name(at: url)
                status = .found(SchoolConfig(baseURL: url, name: name))
            } catch {
                status = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    private func normaliseURL(_ raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
            trimmed = "https://" + trimmed
        }
        if !trimmed.hasSuffix("/") { trimmed += "/" }
        guard let url = URL(string: trimmed), url.host != nil else { return nil }
        return url
    }
}

#if DEBUG
#Preview {
    SchoolSetupView()
        .environment(AppSession.preview(phase: .needsSchool, school: nil))
}
#endif
