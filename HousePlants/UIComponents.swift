import SwiftUI
import MapKit

struct ClaudeHeader: View {
    let title: String
    var subtitle: String? = nil
    var location: String? = nil
    var trailingActions: AnyView? = nil
    var showBackButton: Bool = false
    @Environment(\.dismiss) var dismiss

    private var displayLocation: String? {
        guard let location else { return nil }
        let normalized = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty,
              !["unknown", "not set", "-"].contains(normalized.lowercased()) else {
            return nil
        }
        return normalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showBackButton {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(.claudeSans(size: 14, weight: .medium))
                    }
                    .foregroundColor(.claudePrimaryText)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let location = displayLocation {
                            IndieCutLabel(text: location, color: IndieHousePalette.yellow)
                                .padding(.bottom, 5)
                        }
                        
                        Text(title)
                            .font(.claudeSerif(size: 36, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                            .minimumScaleFactor(0.85)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.claudeSans(size: 15, weight: .medium))
                                .foregroundStyle(Color.claudeSecondaryText)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .layoutPriority(0)
                    
                    Spacer()
                    
                    if let actions = trailingActions {
                        actions
                            .layoutPriority(1)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

struct ClaudeTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.claudeAccent)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.body)
            }
            .padding()
            .background(Color.claudeSecondaryBackground)
            .overlay(
                Rectangle()
                    .stroke(Color.claudeBorder, lineWidth: 1.5)
            )
        }
    }
}

struct ClaudeCitySearchField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var onSelect: (String, String) -> Void 
    
    @StateObject private var searchManager = LocationSearchManager()
    @State private var isFocused: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.claudeAccent)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.body)
                    .onChange(of: text) { _, newValue in
                        searchManager.updateSearch(query: newValue)
                    }
                    .onTapGesture {
                        isFocused = true
                    }
            }
            .padding()
            .background(Color.claudeSecondaryBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused && !searchManager.suggestions.isEmpty ? Color.claudeAccent : Color.claudeBorder, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if isFocused && !searchManager.suggestions.isEmpty {
                    VStack {
                        Spacer(minLength: 58)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(searchManager.suggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        isLoading = true
                                        searchManager.getCityAndCountry(from: suggestion) { city, country in
                                            if let city = city, let country = country {
                                                onSelect(city, country)
                                            } else {
                                                onSelect(suggestion.title, "")
                                            }
                                            isFocused = false
                                            isLoading = false
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .font(.body.bold())
                                                    .foregroundColor(.primary)
                                                Text(suggestion.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if isLoading {
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            } else {
                                                Image(systemName: "arrow.up.left")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 15)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if suggestion.title != searchManager.suggestions.last?.title {
                                        Divider()
                                            .padding(.horizontal, 10)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        )
                        .padding(.top, 4)
                    }
                    .frame(width: 250)
                    .zIndex(100)
                }
            }
        }
    }
}

struct ClaudeBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = .claudeAccent
    var isGlassy: Bool = true
    
    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            
            Text(text)
                .font(.claudeSans(size: 11, weight: .bold))
                .tracking(0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Rectangle().fill(color.opacity(isGlassy ? 0.2 : 0.12))
        }
        .foregroundStyle(Color.claudePrimaryText)
        .overlay(
            Rectangle()
                .stroke(Color.claudePrimaryText, lineWidth: 1)
        )
        .rotationEffect(.degrees(-1))
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.claudeSans(size: 16, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                Text(text)
                    .font(.claudeSans(size: 14))
                    .foregroundColor(.claudeSecondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
    }
}
