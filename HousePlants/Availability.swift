import SwiftUI

// MARK: - Forward-compatible API adoption
//
// The app deploys to iOS 26, which is the Liquid Glass release — so `glassEffect` and
// everything built on it is available unconditionally and doesn't appear here.
//
// A handful of WWDC26 (iOS 27) APIs remove long-standing limitations that this app runs
// into directly, most importantly that swipe actions and drag-to-reorder used to require
// `List`. This screen can't use `List` — the cut-paper cards need to size themselves —
// so those interactions were simply impossible before.
//
// Rather than wait for the deployment target to move, each one is adopted behind an
// availability check and paired with a real iOS 26 fallback. Every wrapper here follows
// the same shape: enhanced behaviour on 27, unchanged view on 26.

enum PlatformCapability {
    /// Whether `swipeActionsContainer` and `reorderable` are usable.
    ///
    /// Both gate on the same OS version, and both concern interactions inside a
    /// non-`List` container, so the app treats them as one capability rather than
    /// checking two versions that will always agree.
    static var hasContainerInteractions: Bool {
        #if compiler(>=6.4)
        if #available(iOS 27, *) { return true }
        #endif
        return false
    }
}

// MARK: - Swipe actions outside List

extension View {
    /// Enables `swipeActions` on a non-`List` container where supported.
    ///
    /// On iOS 26 this is a no-op and the row's swipe actions never activate, which is
    /// why callers pair it with a context menu carrying the same commands.
    @ViewBuilder
    func swipeActionsContainerIfAvailable() -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            swipeActionsContainer()
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Drag to reorder outside List

extension View {
    /// Marks items as draggable for reordering where supported.
    @ViewBuilder
    func reorderableIfAvailable(isEnabled: Bool) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            reorderable(isEnabled: isEnabled)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Receives reorder drops and reports the resulting order.
    ///
    /// The difference is resolved inside the availability branch so its type stays
    /// inferred — naming it at the signature would drag an iOS 27-only type into an
    /// iOS 26 declaration.
    ///
    /// - Parameters:
    ///   - visibleOrder: The plants currently on screen, in display order. Read at drop
    ///     time rather than captured, because filtering and sorting can change it
    ///     between the drag starting and finishing.
    ///   - onReorder: Called with the new display order once a drop lands.
    @ViewBuilder
    func plantReorderContainerIfAvailable(
        visibleOrder: @escaping () -> [Plant],
        onReorder: @escaping ([Plant]) -> Void
    ) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            reorderContainer(for: Plant.self) { difference in
                var ordered = visibleOrder()
                difference.apply(to: &ordered)
                onReorder(ordered)
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Presentation transitions

extension View {
    /// Cross-fades a sheet in where supported, instead of sliding it up.
    ///
    /// For sheets that aren't a continuation of a tapped element there's no source
    /// rectangle to grow from, so a dissolve reads better. On iOS 26 the standard
    /// slide is used, which is correct — just less considered.
    @ViewBuilder
    func crossFadeTransitionIfAvailable() -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            navigationTransition(.crossFade)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Tab roles

@available(iOS 18.0, *)
extension TabRole {
    /// `.prominent` where supported, `nil` otherwise.
    ///
    /// Returned as an optional and passed to `Tab`'s `role:` parameter rather than
    /// branching inside the `TabView` builder — a conditional there would change the
    /// static structure of the tab content, which the builder isn't designed for.
    static var prominentIfAvailable: TabRole? {
        #if compiler(>=6.4)
        if #available(iOS 27, *) { return .prominent }
        #endif
        return nil
    }
}
