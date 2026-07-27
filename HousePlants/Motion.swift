import SwiftUI

// MARK: - Motion System
//
// A single home for every animation curve in the app.
//
// Before this file existed the codebase had ~60 hand-written springs, many of them
// a bare `.spring()` (which is slow and floaty) and most of them ignoring the user's
// Reduce Motion setting. `Motion` fixes both problems at once:
//
//   * Named, reusable curves tuned for the Indie House cut-paper personality —
//     springs are a touch bouncier than Apple defaults so cards feel like physical
//     paper being flicked around, without ever overshooting far enough to look sloppy.
//   * Every entry point degrades automatically when Reduce Motion is on: transforms
//     collapse to a short cross-fade instead of being cancelled outright, so state
//     changes stay legible rather than snapping.
//
// Usage:
//     withMotion(.playful) { isExpanded.toggle() }        // imperative
//     view.motion(.snappy, value: selection)              // declarative
//     card.staggeredAppear(index: i)                      // list entrance
//
enum Motion {

    // MARK: Curves

    /// Micro-interactions: toggles, checkmarks, icon swaps. Fast enough to feel instant.
    static let quick = Animation.spring(response: 0.22, dampingFraction: 0.82)

    /// The default for most UI state changes — filters, selection, disclosure.
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.80)

    /// Noticeable bounce. Cards appearing, pills sliding, things the eye should follow.
    static let bouncy = Animation.spring(response: 0.40, dampingFraction: 0.68)

    /// Maximum personality — reserved for reward moments (watering, streaks, unlocks).
    static let playful = Animation.spring(response: 0.46, dampingFraction: 0.58)

    /// Large surfaces: sheets, full-screen reveals, hero images. Calm, no overshoot.
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.86)

    /// Cut-paper slide — used when a panel should feel like a sheet of card stock
    /// being pushed across a desk.
    static let paper = Animation.spring(response: 0.38, dampingFraction: 0.75)

    /// Non-spring fade for content that shouldn't move, only change.
    static let fade = Animation.easeInOut(duration: 0.22)

    /// What every curve collapses to when Reduce Motion is enabled. A short ease
    /// rather than `nil`, so changes still read as changes instead of hard cuts.
    static let reduced = Animation.easeOut(duration: 0.18)

    // MARK: Idle loops

    /// Slow breathing scale for "alive" elements (a thirsty plant, a pulsing badge).
    static let breathe = Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)

    /// Faster attention loop for things that need action now.
    static let nudge = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)

    // MARK: Stagger

    /// Delay between successive items in a staggered entrance.
    static let staggerStep: Double = 0.045

    /// Items past this index share the last delay, so a long list never waits seconds
    /// for its final row.
    static let staggerCap: Int = 10

    static func staggerDelay(_ index: Int, step: Double = staggerStep, cap: Int = staggerCap) -> Double {
        Double(min(max(index, 0), cap)) * step
    }

    // MARK: Reduce Motion

    /// Imperative check for use outside a `View` body (inside `Task`s, stores, etc.).
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Swaps a curve for the reduced-motion equivalent when needed.
    static func resolve(_ animation: Animation?) -> Animation? {
        prefersReducedMotion ? reduced : animation
    }
}

// MARK: - Imperative entry point

/// Reduce-Motion-aware replacement for `withAnimation`.
///
/// Prefer this over `withAnimation` everywhere: it guarantees the accessibility
/// setting is honoured without every call site having to read the environment.
@discardableResult
func withMotion<Result>(
    _ animation: Animation? = Motion.snappy,
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(Motion.resolve(animation), body)
}

/// Same as `withMotion` but runs after a delay — handy for two-beat reward
/// animations (pop, then settle).
func withMotion(
    _ animation: Animation? = Motion.snappy,
    after delay: Double,
    _ body: @escaping () -> Void
) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(Motion.resolve(animation), body)
    }
}

// MARK: - Declarative modifiers

private struct MotionAnimation<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.reduced : animation, value: value)
    }
}

extension View {
    /// `.animation(_:value:)` that automatically respects Reduce Motion.
    func motion<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }
}

// MARK: - Staggered entrance

/// Fades, lifts and un-tilts an item into place, offset by its position in a list.
///
/// Each card starts slightly small, nudged down, and rotated a degree or two — so a
/// grid settles like a handful of paper cards being dealt onto a table rather than
/// all snapping in together.
struct StaggeredAppear: ViewModifier {
    let index: Int
    var step: Double = Motion.staggerStep
    var cap: Int = Motion.staggerCap
    var animation: Animation = Motion.bouncy
    /// Vertical distance travelled on entry.
    var offset: CGFloat = 14
    /// Starting tilt, alternating direction per item for a hand-placed feel.
    var tilt: Double = 1.5

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var startTilt: Double {
        index.isMultiple(of: 2) ? -tilt : tilt
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
            .offset(y: appeared || reduceMotion ? 0 : offset)
            .rotationEffect(.degrees(appeared || reduceMotion ? 0 : startTilt))
            .onAppear {
                guard !appeared else { return }
                let delay = Motion.staggerDelay(index, step: step, cap: cap)
                withAnimation((reduceMotion ? Motion.reduced : animation).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Deal this view into place as part of a staggered group.
    func staggeredAppear(
        index: Int,
        step: Double = Motion.staggerStep,
        cap: Int = Motion.staggerCap,
        animation: Animation = Motion.bouncy,
        offset: CGFloat = 14,
        tilt: Double = 1.5
    ) -> some View {
        modifier(StaggeredAppear(
            index: index,
            step: step,
            cap: cap,
            animation: animation,
            offset: offset,
            tilt: tilt
        ))
    }

    /// Single-element version of `staggeredAppear` for headers and hero content.
    func appearsIn(delay: Double = 0, animation: Animation = Motion.gentle, offset: CGFloat = 16) -> some View {
        modifier(StaggeredAppear(
            index: 0,
            step: 0,
            cap: 0,
            animation: animation.delay(delay),
            offset: offset,
            tilt: 0
        ))
    }
}

// MARK: - Pop on change

/// Briefly scales a view up when a tracked value changes.
///
/// Used for counters and badges so a number ticking over is felt, not just seen.
/// Pairs well with `.contentTransition(.numericText())`.
struct PopOnChange<V: Equatable>: ViewModifier {
    let value: V
    var scale: CGFloat = 1.18
    var haptic: Bool = false

    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(popped && !reduceMotion ? scale : 1)
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                if haptic { HapticManager.shared.playImpact(style: .light) }
                withAnimation(Motion.playful) { popped = true }
                withMotion(Motion.snappy, after: 0.14) { popped = false }
            }
    }
}

extension View {
    func popOnChange<V: Equatable>(of value: V, scale: CGFloat = 1.18, haptic: Bool = false) -> some View {
        modifier(PopOnChange(value: value, scale: scale, haptic: haptic))
    }
}

// MARK: - Wiggle

/// A short back-and-forth rotation, triggered by a value change.
///
/// Deliberately reserved for "look at me" moments — an overdue plant, a rejected
/// input — because a wiggle used casually reads as a bug.
struct WiggleOnChange<V: Equatable>: ViewModifier {
    let value: V
    var amount: Double = 6

    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                for (i, step) in [1, 2, 3, 0].enumerated() {
                    withMotion(Animation.spring(response: 0.16, dampingFraction: 0.5), after: Double(i) * 0.07) {
                        phase = step
                    }
                }
            }
    }

    private var rotation: Double {
        switch phase {
        case 1: return amount
        case 2: return -amount
        case 3: return amount * 0.45
        default: return 0
        }
    }
}

extension View {
    func wiggle<V: Equatable>(on value: V, amount: Double = 6) -> some View {
        modifier(WiggleOnChange(value: value, amount: amount))
    }
}

// MARK: - Breathing

/// Gentle continuous scale, for idle elements that should feel alive.
struct Breathing: ViewModifier {
    var active: Bool = true
    var range: ClosedRange<CGFloat> = 1.0...1.05
    var animation: Animation = Motion.breathe

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(expanded ? range.upperBound : range.lowerBound)
            .onAppear { start() }
            .onChange(of: active) { _, _ in start() }
    }

    private func start() {
        guard active, !reduceMotion else {
            withAnimation(Motion.reduced) { expanded = false }
            return
        }
        withAnimation(animation) { expanded = true }
    }
}

extension View {
    func breathing(_ active: Bool = true, range: ClosedRange<CGFloat> = 1.0...1.05) -> some View {
        modifier(Breathing(active: active, range: range))
    }
}

// MARK: - Cut-paper button styles

/// Presses the card flat against its own drop shadow.
///
/// The Indie House cards are drawn as a filled rectangle sitting above an offset
/// solid-ink shadow. Sliding the card down-right by exactly the shadow offset while
/// shrinking it slightly makes it read as a physical piece of paper being pushed
/// into the page — the shadow disappears because the card lands on it.
struct PaperPressButtonStyle: ButtonStyle {
    var shadowOffset: CGFloat = 5
    var scale: CGFloat = 0.985
    var tilt: Double = 0
    var haptic: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        return configuration.label
            .offset(x: pressed ? shadowOffset : 0, y: pressed ? shadowOffset : 0)
            .scaleEffect(pressed ? scale : 1)
            .rotationEffect(.degrees(pressed ? tilt : 0))
            .opacity(configuration.isPressed && reduceMotion ? 0.72 : 1)
            .animation(reduceMotion ? Motion.reduced : Motion.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && haptic { HapticManager.shared.playImpact(style: .light) }
            }
    }
}

/// Squash-and-stretch press for round icon buttons.
struct SquishButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.88
    var rotation: Double = -5
    var haptic: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        return configuration.label
            .scaleEffect(x: pressed ? scale * 1.06 : 1, y: pressed ? scale : 1, anchor: .center)
            .rotationEffect(.degrees(pressed ? rotation : 0))
            .opacity(configuration.isPressed && reduceMotion ? 0.72 : 1)
            .animation(reduceMotion ? Motion.reduced : Motion.playful, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && haptic { HapticManager.shared.playSelection() }
            }
    }
}

// MARK: - Paper confetti burst

/// A short burst of cut-paper scraps, used to celebrate care actions.
///
/// Built from plain rectangles in the Indie House palette rather than emoji or
/// gradients, so the celebration looks like it was cut from the same construction
/// paper as the rest of the UI. Renders nothing at all under Reduce Motion.
struct PaperBurst: View {
    /// Toggle to fire the burst. Set true; the view resets itself.
    @Binding var isActive: Bool
    var count: Int = 14
    var radius: CGFloat = 62
    var colors: [Color] = [
        IndieHousePalette.green,
        IndieHousePalette.yellow,
        IndieHousePalette.blue,
        IndieHousePalette.pink,
        IndieHousePalette.orange
    ]

    @State private var launched = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Scrap: Identifiable {
        let id: Int
        let angle: Double
        let distance: CGFloat
        let size: CGSize
        let spin: Double
        let color: Color
        let delay: Double
    }

    private var scraps: [Scrap] {
        (0..<count).map { i in
            // Deterministic pseudo-random so the burst is stable across redraws
            // (a `.random` call in a computed property would reshuffle every frame).
            let seed = Double(i) * 2.399963
            let jitter = (sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
            let spread = CGFloat(abs(jitter))
            return Scrap(
                id: i,
                angle: (360.0 / Double(count)) * Double(i) + jitter * 18,
                distance: radius * (0.65 + spread * 0.5),
                size: CGSize(width: 5 + spread * 5, height: 8 + spread * 6),
                spin: jitter * 320,
                color: colors[i % colors.count],
                delay: abs(jitter) * 0.06
            )
        }
    }

    var body: some View {
        ZStack {
            if isActive && !reduceMotion {
                ForEach(scraps) { scrap in
                    Rectangle()
                        .fill(scrap.color)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1))
                        .frame(width: scrap.size.width, height: scrap.size.height)
                        .rotationEffect(.degrees(launched ? scrap.spin : 0))
                        .offset(
                            x: launched ? CGFloat(cos(scrap.angle * .pi / 180)) * scrap.distance : 0,
                            y: launched ? CGFloat(sin(scrap.angle * .pi / 180)) * scrap.distance : 0
                        )
                        .opacity(launched ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.72).delay(scrap.delay),
                            value: launched
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            guard active else { return }
            guard !reduceMotion else {
                isActive = false
                return
            }
            launched = false
            DispatchQueue.main.async { launched = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                isActive = false
                launched = false
            }
        }
    }
}

extension View {
    /// Overlays a celebratory paper burst centred on this view.
    func paperBurst(_ isActive: Binding<Bool>, count: Int = 14, radius: CGFloat = 62) -> some View {
        overlay {
            PaperBurst(isActive: isActive, count: count, radius: radius)
        }
    }
}

// MARK: - Transitions

extension AnyTransition {
    /// Card being dealt in: rises, scales and untilts.
    static var dealtCard: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.92))
                .combined(with: .move(edge: .bottom)),
            removal: .opacity.combined(with: .scale(scale: 0.96))
        )
    }

    /// Panel sliding in like a sheet of paper pushed across a desk.
    static var paperSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Content popping open from its own centre.
    static var popOpen: AnyTransition {
        .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
    }

    /// Reduce-Motion-aware picker: falls back to a plain fade.
    static func safe(_ transition: AnyTransition, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : transition
    }
}

// MARK: - Timeline-driven effects
//
// Everything above this point animates by interpolating between two states: SwiftUI is
// told "this value changed" and fills in the middle. Timeline-driven effects work the
// other way round — the view is a pure function of the clock, redrawn every frame, with
// no start and end state at all.
//
// That's the right model for anything continuous (a shimmer that never resolves, a
// ripple with its own physics) and the wrong model for anything discrete. Reach for
// `Motion` curves for state changes; reach for these for texture.

/// Shared handle to the shaders in Shimmer.metal.
private enum PlantShaders {
    static let library = ShaderLibrary.bundle(.main)
}

/// Sweeps a soft diagonal band of light across a view, forever.
///
/// Used to mark something as earned — a live streak, a plant restored to health. Because
/// it's clock-driven it never "finishes", which is what separates a state worth
/// celebrating from an event that just happened.
struct RewardShimmer: ViewModifier {
    var isActive: Bool = true
    var tint: Color = IndieHousePalette.yellow
    var intensity: Double = 0.55
    /// Seconds per sweep. Slow — this is meant to be noticed peripherally, not watched.
    var period: Double = 3.2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        // A continuously redrawing view is exactly what Reduce Motion exists to prevent,
        // so it degrades to the plain content rather than to a slower shimmer.
        if isActive && !reduceMotion {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate / period
                content
                    .visualEffect { view, proxy in
                        view.layerEffect(
                            PlantShaders.library.rewardShimmer(
                                .float2(proxy.size),
                                .float(time),
                                .color(tint),
                                .float(intensity)
                            ),
                            maxSampleOffset: .zero
                        )
                    }
            }
        } else {
            content
        }
    }
}

extension View {
    /// Continuous earned-state shimmer. See `RewardShimmer`.
    func rewardShimmer(
        _ isActive: Bool = true,
        tint: Color = IndieHousePalette.yellow,
        intensity: Double = 0.55
    ) -> some View {
        modifier(RewardShimmer(isActive: isActive, tint: tint, intensity: intensity))
    }
}

/// A single ripple expanding from a point, driven by the clock rather than by a spring.
///
/// Fired by setting `trigger`; the modifier tracks its own elapsed time and stops
/// rendering once the ripple has run out, so it costs nothing at rest.
struct WaterRipple: ViewModifier {
    @Binding var trigger: Bool
    var origin: UnitPoint = .center
    var duration: Double = 0.9
    var strength: Double = 22

    @State private var startedAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        Group {
            if let startedAt, !reduceMotion {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startedAt)
                    let progress = min(max(elapsed / duration, 0), 1)
                    content
                        .visualEffect { view, proxy in
                            view.layerEffect(
                                // Argument order must match Shimmer.metal exactly after
                                // the implicit `position` and `layer`: size, origin,
                                // progress, strength.
                                PlantShaders.library.waterRipple(
                                    .float2(proxy.size),
                                    .float2(
                                        proxy.size.width * origin.x,
                                        proxy.size.height * origin.y
                                    ),
                                    .float(progress),
                                    .float(strength)
                                ),
                                // The shader samples outward from the wavefront, so the
                                // renderer has to know how far off-pixel it may read.
                                maxSampleOffset: CGSize(width: strength, height: strength)
                            )
                        }
                        .onChange(of: progress >= 1) { _, finished in
                            if finished { self.startedAt = nil }
                        }
                }
            } else {
                content
            }
        }
        .onChange(of: trigger) { _, fired in
            guard fired else { return }
            if !reduceMotion { startedAt = Date() }
            trigger = false
        }
    }
}

extension View {
    /// Ripples outward from `origin` each time `trigger` is set true.
    func waterRipple(
        _ trigger: Binding<Bool>,
        origin: UnitPoint = .center,
        strength: Double = 22
    ) -> some View {
        modifier(WaterRipple(trigger: trigger, origin: origin, strength: strength))
    }
}
