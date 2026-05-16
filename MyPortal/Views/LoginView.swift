import AuthenticationServices
import SwiftUI
import UIKit

struct LoginView: View {
    @Environment(AppSession.self) private var session
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BrandedBackground()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    brandMark
                    if let name = session.school?.name, !name.isEmpty {
                        Text("Welcome to")
                            .foregroundStyle(Color.white.opacity(0.8))
                        Text(name)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("MyPortal")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red.opacity(0.85))
                        )
                        .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: signIn) {
                        HStack {
                            if isSigningIn {
                                ProgressView().tint(Brand.indigo700)
                            }
                            Text(isSigningIn ? "Opening sign in…" : "Sign in")
                        }
                    }
                    .buttonStyle(BrandedPrimaryButtonStyle(isLoading: isSigningIn))
                    .disabled(isSigningIn)

                    Button("Use a different school") {
                        session.forgetSchool()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .disabled(isSigningIn)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
        }
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.15))
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func signIn() {
        errorMessage = nil
        isSigningIn = true
        Task {
            defer { isSigningIn = false }
            do {
                guard let anchor = Self.keyWindow() else {
                    errorMessage = "Couldn't find a window to present sign in."
                    return
                }
                try await session.signIn(presentationAnchor: anchor)
            } catch OAuthError.userCancelled {
                // Silent — user dismissed the sheet.
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

#if DEBUG
#Preview {
    LoginView()
        .environment(AppSession.preview(phase: .needsLogin))
}
#endif
