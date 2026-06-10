import SwiftUI

// MARK: - Info Sheet View
struct MoonGardeningInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What is Moon Gardening?")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Moon gardening is an ancient practice that uses the lunar cycle to determine the best times to plant, cultivate, and harvest for optimal plant health.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "moonphase.waxing.crescent", title: "Waxing Moon", text: "As the moon's light increases, plants are encouraged to grow leaves and stems. Ideal for planting above-ground crops. Moisture rises in the soil layer.", color: .blue)
                            
                            InfoRow(icon: "moonphase.waning.crescent", title: "Waning Moon", text: "As the moon's light decreases, energy is drawn down to the roots. Perfect for planting root crops, bulbs, and pruning.", color: .orange)
                            
                            InfoRow(icon: "moonphase.new.moon", title: "New Moon", text: "A time of rest for the garden. Prepare soil, plan your layout, pull weeds, and wait for the waxing phase.", color: .indigo)
                            
                            InfoRow(icon: "moonphase.full.moon", title: "Full Moon", text: "High gravitational pull and light. Great for harvesting herbs and picking fruits due to maximum sap concentration.", color: .yellow)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Guide")
                        .font(.claudeSans(size: 16, weight: .bold))
                }
            }
        }
    }
}


// MARK: - Supporting Components

struct MoonTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.claudeSans(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "818CF8").opacity(0.4))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

struct LunarEventRow: View {
    let icon: String
    let title: String
    let date: String
    let daysAway: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.claudeSans(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(date)
                    .font(.claudeSans(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(daysAway)
                .font(.claudeSans(size: 13, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .cornerRadius(10)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct CelestialStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.claudeSans(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.claudeSans(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct MoonGraphic: View {
    let phase: Double // 0 to 1
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Base Moon with hyper-realistic gradient
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color(hex: "FDFCC4").opacity(0.1), Color(hex: "FDFBFC"), Color(hex: "D8D9E0"), Color(hex: "9A9BAB")]),
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: size * 0.05,
                            endRadius: size * 0.95
                        )
                    )
                
                // Detailed Craters & Maria Texture
                Group {
                    // Mare Imbrium (Top left)
                    Ellipse().fill(Color.black.opacity(0.12)).frame(width: size * 0.28, height: size * 0.22).offset(x: -size * 0.12, y: -size * 0.18).blur(radius: size * 0.025)
                    // Mare Serenitatis (Top rightish)
                    Ellipse().fill(Color.black.opacity(0.1)).frame(width: size * 0.22, height: size * 0.18).offset(x: size * 0.12, y: -size * 0.12).blur(radius: size * 0.02)
                    // Mare Tranquillitatis & Fecunditatis (Middle right)
                    Ellipse().fill(Color.black.opacity(0.14)).frame(width: size * 0.32, height: size * 0.28).offset(x: size * 0.18, y: size * 0.08).blur(radius: size * 0.035)
                    // Oceanus Procellarum (Left edge)
                    Ellipse().fill(Color.black.opacity(0.08)).frame(width: size * 0.25, height: size * 0.4).offset(x: -size * 0.28, y: size * 0.05).blur(radius: size * 0.04)
                    
                    // Tycho Crater with bright rays (Bottom left)
                    Circle().fill(Color.white.opacity(0.7)).frame(width: size * 0.02, height: size * 0.02).offset(x: -size * 0.08, y: size * 0.3).blur(radius: size * 0.005)
                    Circle().fill(Color.black.opacity(0.08)).frame(width: size * 0.12, height: size * 0.12).offset(x: -size * 0.08, y: size * 0.3).blur(radius: size * 0.02)
                    
                    // Copernicus Crater (Upper mid-left)
                    Circle().fill(Color.white.opacity(0.5)).frame(width: size * 0.025, height: size * 0.025).offset(x: -size * 0.15, y: -size * 0.02).blur(radius: size * 0.008)
                }
                .clipShape(Circle())
                
                // High Quality Phase Shadowing Overlay
                HStack(spacing: 0) {
                    if phase > 0.5 {
                        Spacer()
                        Rectangle()
                            .fill(LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.95)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: size * CGFloat(1.0 - phase))
                            .blur(radius: size * 0.06)
                    } else {
                        Rectangle()
                            .fill(LinearGradient(colors: [.black.opacity(0.95), .black.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: size * CGFloat(0.5 - phase))
                            .blur(radius: size * 0.06)
                        Spacer()
                    }
                }
                .clipShape(Circle())
                
                // Inner Rim Light for a 3D spherical effect
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0.1), .black.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.012
                    )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
