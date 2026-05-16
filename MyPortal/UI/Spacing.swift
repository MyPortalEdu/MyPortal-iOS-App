import CoreGraphics

/// Spacing scale on Apple's 4-pt grid. Use these instead of magic numbers
/// so visual rhythm stays consistent as new screens land.
nonisolated enum Spacing {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Corner-radius scale. Picked to look right with the spacing scale; iOS
/// system controls use ~10–14, so this matches.
nonisolated enum CornerRadius {
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 20
}
