import SwiftUI

// MARK: - Indie House Theme
//
// The public Indie House site uses warm paper, navy ink, bright primary accents,
// editorial type, and deliberately imperfect cut-paper edges.  The existing
// `claude…` names are kept as compatibility aliases so the visual refresh can
// flow through every screen without a risky app-wide rename.
struct ClaudeTheme {
    static func dynamicColor(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
    
    struct Colors {
        static let background = dynamicColor(light: "F5EDDC", dark: "11182B")
        static let secondaryBackground = dynamicColor(light: "FFFAF0", dark: "1B2540")
        static let tertiaryBackground = dynamicColor(light: "E9DFC9", dark: "24304D")
        static let primaryText = dynamicColor(light: "17213B", dark: "FFF8E9")
        static let secondaryText = dynamicColor(light: "41495C", dark: "C5CBDA")
        static let accent = dynamicColor(light: "1E3AD6", dark: "7892FF")
        static let border = dynamicColor(light: "17213B", dark: "D8DFF2")
    }
}

enum IndieHousePalette {
    static let paper = Color.claudeBackground
    static let paperRaised = Color.claudeSecondaryBackground
    static let ink = Color.claudePrimaryText
    static let inkMuted = Color.claudeSecondaryText
    static let green = Color(hex: "2A9D54")
    static let yellow = Color(hex: "F5C518")
    static let red = Color(hex: "E5372B")
    static let blue = Color.claudeAccent
    static let orange = Color(hex: "F0941F")
    static let pink = Color(hex: "FF92B6")
}

extension Color {
    static let claudeBackground = ClaudeTheme.Colors.background
    static let claudeSecondaryBackground = ClaudeTheme.Colors.secondaryBackground
    static let claudePrimaryText = ClaudeTheme.Colors.primaryText
    static let claudeSecondaryText = ClaudeTheme.Colors.secondaryText
    static let claudeAccent = ClaudeTheme.Colors.accent
    static let claudeBorder = ClaudeTheme.Colors.border
}

extension Font {
    static func claudeSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // `relativeTo:` lets Georgia scale with the user's Dynamic Type setting instead of being
        // pinned to a fixed point size (which ignored accessibility text sizes entirely).
        return .custom("Georgia", size: size, relativeTo: .body).weight(weight)
    }

    static func claudeSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // `.system(size:)` is a fixed size and ignores Dynamic Type. SwiftUI has no size+relativeTo
        // variant for the system font, so scale the point size via UIFontMetrics (evaluated during
        // body, so it tracks the user's current text-size setting).
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: size)
        return .system(size: scaled, weight: weight, design: .default)
    }
}

// MARK: - Interactive Button Styles

struct BubblingButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(
                x: configuration.isPressed && !reduceMotion ? 3 : 0,
                y: configuration.isPressed && !reduceMotion ? 3 : 0
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.72 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.76), value: configuration.isPressed)
    }
}

struct NotificationButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.9 : 1)
            .rotationEffect(.degrees(configuration.isPressed && !reduceMotion ? 8 : 0))
            .opacity(configuration.isPressed && reduceMotion ? 0.72 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct InteractiveCardButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .opacity(configuration.isPressed && reduceMotion ? 0.76 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - Cut-paper building blocks

struct IndiePaperCard: ViewModifier {
    var fill: Color = .claudeSecondaryBackground
    var border: Color = .claudePrimaryText
    var shadow: Color = .claudePrimaryText
    var rotation: Double = 0
    var cornerRadius: CGFloat = 3
    var shadowOffset: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border, lineWidth: 1.6)
            }
            .background(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(shadow)
                    .offset(x: shadowOffset, y: shadowOffset)
            }
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    func indiePaperCard(
        fill: Color = .claudeSecondaryBackground,
        border: Color = .claudePrimaryText,
        shadow: Color = .claudePrimaryText,
        rotation: Double = 0,
        cornerRadius: CGFloat = 3,
        shadowOffset: CGFloat = 5
    ) -> some View {
        modifier(IndiePaperCard(
            fill: fill,
            border: border,
            shadow: shadow,
            rotation: rotation,
            cornerRadius: cornerRadius,
            shadowOffset: shadowOffset
        ))
    }
}

struct IndieCutLabel: View {
    let text: String
    var color: Color = IndieHousePalette.green

    var body: some View {
        Text(text.uppercased())
            .font(.claudeSans(size: 10, weight: .black))
            .tracking(1.25)
            .foregroundStyle(IndieHousePalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color)
            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
            .background(IndieHousePalette.ink.offset(x: 3, y: 3))
            .rotationEffect(.degrees(-1.5))
    }
}

struct WaterButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
