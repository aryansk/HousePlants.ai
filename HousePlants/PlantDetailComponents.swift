import SwiftUI

// MARK: - Components

struct CareItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(color)
                    }
                    
                    Text(title)
                        .font(.claudeSans(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                
                Text(value)
                    .font(.claudeSans(size: 14, weight: .medium))
                    .foregroundStyle(Color.claudePrimaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.claudeBorder, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}

struct Badge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        ClaudeBadge(text: text, icon: icon, color: color, isGlassy: false)
    }
}

struct ToolLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.claudeSans(size: 16, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(subtitle)
                        .font(.claudeSans(size: 13))
                        .foregroundStyle(Color.claudeSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.claudeBorder)
            }
            .padding(16)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}


// MARK: - Utilities

// Re-using CareDetail models from original file or defining them if needed

// Re-using CareDetail models from original file or defining them if needed
struct CareDetail: Identifiable {
    let id: String
    let info: String
    let icon: String
    let color: Color
}

struct CareDetailView: View {
    @Environment(\.dismiss) var dismiss
    let detail: CareDetail
    
    var proTip: String {
        switch detail.id {
        case "Light Requirements": return "Rotate your plant every two weeks to ensure even growth on all sides. Leaning plants usually mean they need more light!"
        case "Watering Schedule": return "Always check the top inch of soil with your finger before watering. If it's still damp, wait a few days."
        case "Temperature": return "Keep plants away from cold drafts and heating vents. Drastic temperature swings can cause leaf drop."
        case "Humidity Levels": return "Grouping plants together naturally increases local humidity. For tropical plants, a pebble tray works wonders!"
        case "Soil & Potting": return "Make sure your pot has drainage holes! Fresh soil every year helps replenish nutrients."
        case "Care Level": return "Don't be discouraged if a plant struggles. Observation is key—the plant will tell you what it needs."
        default: return "Consistent observation is the best care strategy."
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(detail.color.opacity(0.1))
                        .frame(width: 90, height: 90)
                    Image(systemName: detail.icon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(detail.color)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text(detail.id)
                        .font(.claudeSerif(size: 28, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    
                    Text("Specialist Insight")
                        .font(.claudeSans(size: 14, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(detail.color)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Current Requirement", systemImage: "info.circle.fill")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(detail.color)
                        
                        Text(detail.info)
                            .font(.claudeSans(size: 16))
                            .foregroundStyle(Color.claudePrimaryText.opacity(0.8))
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(detail.color.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pro Plant Tip", systemImage: "lightbulb.fill")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(.orange)
                        
                        Text(proTip)
                            .font(.claudeSans(size: 16))
                            .italic()
                            .foregroundStyle(Color.claudeSecondaryText)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                
                Button(action: { dismiss() }) {
                    Text("I've Got This")
                        .font(.claudeSans(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(detail.color)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)
                }
                .frame(width: geometry.size.width)
                .padding(32)
            }
        }
        .background(Color.claudeBackground)
    }
}

struct OriginCountriesView: View {
    @Environment(\.dismiss) var dismiss
    let region: String
    let countries: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            // Modal Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Native Distribution")
                        .font(.claudeSerif(size: 24, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(region)
                        .font(.claudeSans(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .padding(24)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 12) {
                    ForEach(countries, id: \.self) { country in
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.orange.opacity(0.1)))
                            
                            Text(country)
                                .font(.claudeSans(size: 16, weight: .medium))
                                .foregroundStyle(Color.claudePrimaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.claudeSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                    }
                    }
                    .frame(width: geometry.size.width)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.claudeBackground)
    }
}
