import SwiftUI

// MARK: - Claude Theme
struct ClaudeTheme {
    static func dynamicColor(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
    
    struct Colors {
        static let background = dynamicColor(light: "FBF7F1", dark: "1A1A17")
        static let secondaryBackground = dynamicColor(light: "F3EFE9", dark: "22221E")
        static let tertiaryBackground = dynamicColor(light: "EBE7E0", dark: "2B2B26")
        static let primaryText = dynamicColor(light: "29211D", dark: "F5F2ED")
        static let secondaryText = dynamicColor(light: "72655E", dark: "A69D92")
        static let accent = dynamicColor(light: "D97757", dark: "E69173")
        static let border = dynamicColor(light: "E5E1D9", dark: "2D2D28")
    }
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
        // Fallback to system serif if Georgia isn't available, though it usually is on iOS
        return .custom("Georgia", size: size).weight(weight)
    }
    
    static func claudeSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Interactive Button Styles

struct BubblingButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct NotificationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? 10 : 0))
            .animation(.spring(response: 0.2, dampingFraction: 0.4), value: configuration.isPressed)
    }
}

struct InteractiveCardButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct WaterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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

