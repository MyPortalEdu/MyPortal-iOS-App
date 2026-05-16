import SwiftUI

/// Indigo gradient used as the backdrop for the unauthenticated screens
/// (school setup, login). Defined once so the auth flow has a single visual
/// identity and we don't drift across screens.
struct BrandedBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Brand.indigo500, Brand.indigo700, Brand.indigo900],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            // Soft highlight blob — gives the gradient a touch of depth so
            // it doesn't read as a flat colour fill.
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 120, y: -120)
        }
        .ignoresSafeArea()
    }
}

/// Primary action button styled for placement on the indigo background.
/// White surface with indigo label — high contrast, reads as the obvious
/// next step without competing with the brand mark.
struct BrandedPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Brand.indigo700)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            .opacity(isLoading ? 0.85 : 1)
    }
}

#if DEBUG
#Preview {
    ZStack {
        BrandedBackground()
        VStack(spacing: 16) {
            Text("Welcome to")
                .foregroundStyle(.white.opacity(0.8))
            Text("Acme High School")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Button("Sign in") {}
                .buttonStyle(BrandedPrimaryButtonStyle())
                .padding(.horizontal)
        }
        .padding()
    }
}
#endif
