import SwiftUI

/// A deliberately tiny, mascot-led entry point inspired by Pool's launch interaction.
/// HousePlants keeps the gesture and pacing, but uses its own Sprig character, copy, and art.
struct WelcomeView: View {
    @Environment(DataLoader.self) private var dataLoader
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isCompleted: Bool

    @State private var sprigOffset: CGSize = .zero
    @State private var isEntering = false
    @State private var hasAppeared = false
    @State private var isDragging = false
    @State private var celebrating = false

    private let dragThreshold: CGFloat = 110

    /// Lean angle for Sprig, clamped to ±12° so a long drag never looks like a tumble.
    private var sprigTilt: Double {
        guard !reduceMotion else { return 0 }
        return max(-12, min(12, Double(sprigOffset.width) / 8))
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                HStack {
                    IndieCutLabel(text: "HousePlants.ai", color: IndieHousePalette.yellow)
                    Spacer()
                    Text("A little care, every day")
                        .font(.claudeSans(size: 12, weight: .semibold))
                        .foregroundStyle(Color.claudeSecondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared || reduceMotion ? 0 : -10)
                .animation(reduceMotion ? Motion.reduced : Motion.gentle, value: hasAppeared)

                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    Text("Welcome to your\njungle.")
                        .font(.claudeSerif(size: 42, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("onboarding.title")

                    Text("Sprig is waiting to help you get started.")
                        .font(.claudeSans(size: 16, weight: .medium))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared || reduceMotion ? 0 : 14)
                .animation(reduceMotion ? Motion.reduced : Motion.gentle.delay(0.10), value: hasAppeared)

                Spacer(minLength: 18)

                ZStack {
                    Circle()
                        .fill(IndieHousePalette.green.opacity(isDragging ? 0.22 : 0.14))
                        .frame(width: 250, height: 250)
                        .overlay(Circle().stroke(IndieHousePalette.green.opacity(isDragging ? 0.6 : 0.35), lineWidth: 1.5))
                        // The halo swells as Sprig is pulled away from centre, hinting
                        // that letting go past the threshold will do something.
                        .scaleEffect(isDragging ? 1.06 : 1)
                        .motion(Motion.gentle, value: isDragging)

                    VStack(spacing: 14) {
                        SprigView(stage: .seedling, mood: .curious)
                            .scaleEffect(1.25)
                            // Sprig leans into the direction of the drag, which makes the
                            // mascot feel like it's being carried rather than dragged.
                            .rotationEffect(.degrees(sprigTilt))
                            .scaleEffect(isDragging ? 1.08 : 1)
                            .breathing(!isDragging && !isEntering, range: 1.0...1.035)
                            // Scoped above `.offset` on purpose: the pick-up/put-down scale
                            // is animated, but the offset must track the finger 1:1 with no
                            // lag while the drag is in progress.
                            .motion(Motion.gentle, value: isDragging)
                            .offset(sprigOffset)
                            .paperBurst($celebrating, count: 20, radius: 110)
                            .gesture(dragGesture)
                            .accessibilityHint("Press and drag Sprig into your jungle to enter")
                            .accessibilityAction(named: "Enter your jungle") { enterJungle() }

                        Text(isEntering ? "Growing your welcome…" : "Press and drag Sprig to enter")
                            .font(.claudeSans(size: 14, weight: .bold))
                            .foregroundStyle(isEntering ? IndieHousePalette.green : Color.claudePrimaryText)
                            .contentTransition(.numericText())
                            .motion(Motion.snappy, value: isEntering)
                    }
                }
                .frame(width: 280, height: 310)
                .accessibilityIdentifier("onboarding.sprigEntry")

                Spacer(minLength: 18)

                VStack(spacing: 12) {
                    Button(action: enterJungle) {
                        HStack(spacing: 10) {
                            Text("Enter your jungle")
                            Image(systemName: "arrow.right")
                        }
                        .font(.claudeSans(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(IndieHousePalette.blue)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.8))
                        .background(IndieHousePalette.ink.offset(x: 4, y: 4))
                    }
                    .buttonStyle(BubblingButtonStyle())
                    .accessibilityIdentifier("onboarding.enter")

                    Text("You can personalize your care plan anytime in Profile.")
                        .font(.claudeSans(size: 12))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 28)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared || reduceMotion ? 0 : 20)
                .animation(reduceMotion ? Motion.reduced : Motion.gentle.delay(0.22), value: hasAppeared)
            }
        }
        .onAppear {
            if reduceMotion {
                hasAppeared = true
            } else {
                withMotion(Motion.gentle) { hasAppeared = true }
            }
        }
    }

    private var background: some View {
        ZStack {
            Color.claudeBackground
            Circle()
                .fill(IndieHousePalette.yellow.opacity(0.12))
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: 170, y: -320)
            Circle()
                .fill(IndieHousePalette.blue.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 65)
                .offset(x: -180, y: 380)
        }
        .ignoresSafeArea()
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isEntering else { return }
                if !isDragging { withMotion(Motion.gentle) { isDragging = true } }
                let translation = value.translation
                let distance = hypot(translation.width, translation.height)
                let scale = min(1, 150 / max(distance, 150))
                sprigOffset = CGSize(width: translation.width * scale, height: translation.height * scale)
            }
            .onEnded { value in
                guard !isEntering else { return }
                withMotion(Motion.gentle) { isDragging = false }
                let distance = hypot(value.translation.width, value.translation.height)
                if distance >= dragThreshold {
                    enterJungle()
                } else {
                    // Springs back with real bounce, so a short drag reads as
                    // "not far enough" rather than as a failed interaction.
                    withMotion(Motion.playful) { sprigOffset = .zero }
                }
            }
    }

    private func enterJungle() {
        guard !isEntering else { return }
        isEntering = true
        HapticManager.shared.playImpact(style: .medium)

        dataLoader.updateProfile(username: "Plant Lover", city: "Unknown", country: "Unknown")
        dataLoader.updatePreferences(difficulty: "Beginner", petSafeOnly: false, notifyOnSundays: false)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        if reduceMotion {
            isCompleted = true
        } else {
            celebrating = true
            withMotion(Motion.playful) {
                sprigOffset = CGSize(width: 0, height: -18)
            }
            Task { @MainActor in
                // Long enough for the burst to read, short enough that the app doesn't
                // feel like it's making the user wait to get in.
                try? await Task.sleep(for: .milliseconds(420))
                guard !Task.isCancelled else { return }
                isCompleted = true
            }
        }
    }
}

#Preview {
    WelcomeView(isCompleted: .constant(false))
        .environment(DataLoader())
}
