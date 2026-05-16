import SwiftUI

/// Background + rounded shape used by every card-like surface in the app
/// (home widgets, info panels in the detail view, the school-setup card).
/// Centralised so all of them share the same fill / radius / clipping.
struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.l
    var background: Color = Color(.secondarySystemGroupedBackground)

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
    }
}

extension View {
    /// Applies the shared card visual treatment.
    func cardSurface(cornerRadius: CGFloat = CornerRadius.l,
                     background: Color = Color(.secondarySystemGroupedBackground)) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, background: background))
    }
}
