import SwiftUI

// MARK: - Liquid Glass, scoped to chrome
//
// The Indie House cut-paper look — flat fills, hard ink outlines, solid offset shadows —
// stays exactly as it is for every content surface. It's the app's identity, and Liquid
// Glass would fight it: a refracting material behind a card that already fakes its own
// depth reads as two competing depth systems stacked on top of each other.
//
// Glass is used only where the system expects it and where the app has no opinion:
//
//     tab bar, navigation bars     — system chrome, users expect the new material
//     floating overlays            — toasts, undo banners, anything over content
//     sheet backing                — system-owned presentation surface
//
// Rule of thumb for anything added later: if the surface holds the app's own content,
// it's paper. If it floats above content or belongs to the system, it's glass.

// MARK: - Tokens

enum GlassChrome {
    /// Floating overlays sit above content, so they get a generous radius — the sharp
    /// 2–3pt cut-paper corner is for things pinned to the page, not hovering over it.
    static let overlayRadius: CGFloat = 22

    /// Tints stay light. Liquid Glass is supposed to carry colour from behind it; a
    /// heavy tint turns it back into a flat fill and defeats the point.
    static let tint: Double = 0.3
}

// MARK: - Floating overlays

extension View {
    /// Glass backing for something floating above content — a toast, an undo banner,
    /// a transient control. Keeps the ink hairline so it still reads as Indie House,
    /// but lets the material supply depth instead of a painted shadow.
    func glassOverlaySurface(
        tint: Color? = nil,
        cornerRadius: CGFloat = GlassChrome.overlayRadius
    ) -> some View {
        glassEffect(
            tint.map { .regular.tint($0.opacity(GlassChrome.tint)) } ?? .regular,
            in: .rect(cornerRadius: cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(IndieHousePalette.ink.opacity(0.5), lineWidth: 1.2)
        }
    }

}
