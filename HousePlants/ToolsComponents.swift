import SwiftUI

// Tool-specific subviews extracted from ToolsView.
struct SunSeekerARView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScanning = false
    @State private var windowDirection: WindowDirection = .south
    @State private var isDirectSun: Bool = true
    @State private var isSouthernHemisphere: Bool = false
    @State private var showInfoSheet = false

    enum WindowDirection: String, CaseIterable {
        case north = "North", south = "South", east = "East", west = "West"

        // Peak foot-candles measured ~1 m inside a clean, unobstructed window
        // on a clear day, Northern Hemisphere (mid-latitude). Values from
        // standard horticultural references (Cornell, RHS light guides).
        func peakFootCandles(southernHemisphere: Bool) -> Double {
            let dir: WindowDirection
            if southernHemisphere {
                // Polar-facing window is the dim one; flip N <-> S.
                switch self {
                case .north: dir = .south
                case .south: dir = .north
                default: dir = self
                }
            } else {
                dir = self
            }
            switch dir {
            case .north: return 200    // dim, diffuse only
            case .east:  return 1800   // gentle direct AM sun
            case .west:  return 2800   // hot direct PM sun
            case .south: return 5000   // strongest, longest direct exposure
            }
        }
    }

    // Diffuse / filtered light is ~25-30% of direct beam intensity.
    private let filteredFraction: Double = 0.28

    var effectiveFootCandles: Double {
        let peak = windowDirection.peakFootCandles(southernHemisphere: isSouthernHemisphere)
        return isDirectSun ? peak : peak * filteredFraction
    }

    // 0-1 scale for the visual gauge, log-mapped so the meter doesn't saturate
    // at the high end (plant photoreception is roughly logarithmic).
    var effectiveLightLevel: Double {
        let fc = max(1.0, effectiveFootCandles)
        // log10(25 fc) ≈ 1.4  → 0.0    (deep shade)
        // log10(5000 fc) ≈ 3.7 → 1.0   (full sun at a south window)
        let normalized = (log10(fc) - 1.4) / (3.7 - 1.4)
        return max(0, min(1, normalized))
    }

    var lightStatus: (String, Color) {
        let fc = effectiveFootCandles
        // Standard houseplant light categories (foot-candles):
        //   < 100   Low / shade-tolerant only
        //   100-500 Medium / bright indirect
        //   500-2000 Bright indirect to some direct
        //   > 2000  Direct sun
        if fc < 100 {
            return ("Low Light", .blue)
        } else if fc < 500 {
            return ("Medium Light", .green)
        } else if fc < 2000 {
            return ("Bright Indirect", .yellow)
        } else {
            return ("Direct Sun", .orange)
        }
    }

    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Sun Seeker",
                    subtitle: "Find the perfect spot for your plants.",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.orange.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )

                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {

                            // Light level readout
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    ForEach(0..<3) { i in
                                        Circle()
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 2)
                                            .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                                            .scaleEffect(isScanning ? 1.1 : 1.0)
                                            .opacity(isScanning ? 0.3 : 0.1)
                                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: isScanning)
                                    }
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.orange)
                                        .shadow(color: .orange.opacity(0.3), radius: 10)
                                        .onAppear { isScanning = true }
                                }

                                Text(lightStatus.0.uppercased())
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(lightStatus.1)
                                    .tracking(2)

                                Text("\(Int(effectiveFootCandles.rounded())) fc")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.claudePrimaryText)

                                Text("≈ \(Int((effectiveFootCandles * 10.764).rounded())) lux")
                                    .font(.claudeSans(size: 13, weight: .medium))
                                    .foregroundColor(.claudeSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)

                            // Window direction picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Window Direction")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)

                                HStack(spacing: 12) {
                                    ForEach(WindowDirection.allCases, id: \.self) { dir in
                                        Button(action: { windowDirection = dir }) {
                                            Text(dir.rawValue)
                                                .font(.claudeSans(size: 15, weight: windowDirection == dir ? .bold : .regular))
                                                .foregroundColor(windowDirection == dir ? .white : .claudePrimaryText)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(windowDirection == dir ? Color.orange : Color.claudeSecondaryBackground)
                                                .cornerRadius(14)
                                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.claudeBorder, lineWidth: windowDirection == dir ? 0 : 1))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            // Direct sun toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Conditions")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)

                                VStack(spacing: 12) {
                                    HStack {
                                        Text(isDirectSun ? "Direct sunlight" : "Filtered / indirect light")
                                            .font(.claudeSans(size: 15))
                                            .foregroundColor(.claudePrimaryText)
                                        Spacer()
                                        Toggle("", isOn: $isDirectSun)
                                            .tint(.orange)
                                    }
                                    .padding(16)
                                    .background(Color.claudeSecondaryBackground)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))

                                    HStack {
                                        Text("Southern Hemisphere")
                                            .font(.claudeSans(size: 15))
                                            .foregroundColor(.claudePrimaryText)
                                        Spacer()
                                        Toggle("", isOn: $isSouthernHemisphere)
                                            .tint(.orange)
                                    }
                                    .padding(16)
                                    .background(Color.claudeSecondaryBackground)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                                }
                                .padding(.horizontal, 24)
                            }

                            // Light guide
                            VStack(alignment: .leading, spacing: 12) {
                                Text("The Light Spectrum")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)

                                VStack(spacing: 0) {
                                    LightGuideRow(title: "Low Light", desc: "North windows or deep room corners.", color: .blue)
                                    Divider().padding(.leading, 60)
                                    LightGuideRow(title: "Medium Light", desc: "East/West windows with filtered light.", color: .green)
                                    Divider().padding(.leading, 60)
                                    LightGuideRow(title: "Bright Light", desc: "South windows or direct sun exposure.", color: .orange)
                                }
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            .padding(.horizontal, 24)

                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInfoSheet) {
            SunSeekerInfoSheet()
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct LightGuideRow: View {
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.claudeSans(size: 15, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                Text(desc)
                    .font(.claudeSans(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }
}


struct PotSizeCalculatorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentDiameter: Double = 4
    @State private var isRootBound = false
    @State private var growthRate = 1 // 0: Slow, 1: Moderate, 2: Fast
    @State private var showInfoSheet = false
    
    var recommendedSize: Double {
        // Standard horticultural rule: step up by 1" for pots <10" diameter,
        // 2" for larger pots, since soil volume scales with d^2-d^3 and a
        // too-large jump leaves unrooted soil that stays wet → root rot.
        let baseStep: Double = currentDiameter < 10 ? 1 : 2

        let growthAdj: Double
        switch growthRate {
        case 0: growthAdj = 0          // slow growers prefer a snug fit
        case 2: growthAdj = 1          // fast growers can use extra room
        default: growthAdj = 0.5       // moderate
        }

        // Root-bound adds one more inch but never more than +3" total to
        // avoid the waterlogging risk above.
        let rootBoundAdj: Double = isRootBound ? 1 : 0

        let increase = min(baseStep + growthAdj + rootBoundAdj, 3)
        return currentDiameter + increase
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Repotting Helper",
                    subtitle: "Find the perfect pot size",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.brown.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                        // Pot Growth Visualization
                        VStack(spacing: 20) {
                            PotGrowthView(current: currentDiameter, recommended: recommendedSize)
                                .frame(height: 200)
                                .shadow(color: Color.brown.opacity(0.1), radius: 20, x: 0, y: 10)

                            HStack(alignment: .center) {
                                Text("REC. DIAMETER: ")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                Text("\(Int(recommendedSize))\"")
                                    .font(.claudeSerif(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CURRENT POT")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1)
                            
                                HStack {
                                    Text("\(Int(currentDiameter))\"")
                                        .font(.claudeSerif(size: 24, weight: .bold))
                                        .frame(width: 60)
                                    Slider(value: $currentDiameter, in: 2...20, step: 1)
                                        .tint(.brown)
                                }
                                .padding(20)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            
                            Toggle(isOn: $isRootBound) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Root Bound?")
                                        .font(.claudeSans(size: 16, weight: .bold))
                                    Text("Visible roots escaping drainage holes")
                                        .font(.claudeSans(size: 13))
                                        .foregroundColor(.claudeSecondaryText)
                                }
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            .tint(Color.claudeAccent)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("GROWTH RATE")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1)
                                
                                Picker("Growth Rate", selection: $growthRate) {
                                    Text("Slow").tag(0)
                                    Text("Moderate").tag(1)
                                    Text("Fast").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(4)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(12)
                            }
                            
                            VStack(alignment: .center, spacing: 16) {
                                Text("RECOMMENDATION")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(2)
                                
                                Text("\(Int(recommendedSize))\"")
                                    .font(.system(size: 72, weight: .black, design: .serif))
                                    .foregroundColor(Color.claudeAccent)
                                
                                Text("Ideal Diameter")
                                    .font(.claudeSans(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                                
                                Text(isRootBound ? "Your plant is feeling cramped. A two-inch increase will give those roots the sanctuary they deserve." : "A modest one-inch increase provides space without risking waterlogged soil.")
                                    .font(.claudeSans(size: 14))
                                    .foregroundColor(.claudeSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.claudeSecondaryBackground)
                                    .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.claudeBorder, lineWidth: 1))
                        }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            RepottingHelperInfoSheet()
        }
    }
}

struct DetailStat: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.purple)
            Text(title)
                .font(.claudeSans(size: 12, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
            Text(value)
                .font(.claudeSans(size: 14, weight: .medium))
                .foregroundColor(.claudePrimaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PotGrowthView: View {
    let current: Double
    let recommended: Double
    
    var body: some View {
        ZStack {
            // Container
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.white.opacity(0.05))
                .background(BlurView(style: .systemThinMaterial).clipShape(RoundedRectangle(cornerRadius: 35)))
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.claudeBorder, lineWidth: 1)
                )
            
            // Outer Pot (Recommended)
            Circle()
                .stroke(Color.claudeAccent.opacity(0.3), lineWidth: 4)
                .frame(width: CGFloat(recommended * 10), height: CGFloat(recommended * 10))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: recommended)
            
            // Inner Pot (Current)
            Circle()
                .fill(Color.brown.opacity(0.6))
                .frame(width: CGFloat(current * 10), height: CGFloat(current * 10))
                .overlay(
                    Circle()
                        .stroke(Color.brown, lineWidth: 2)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
            
            // Legend
            VStack {
                Spacer()
                Text("GROWTH CAPACITY")
                    .font(.claudeSans(size: 9, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
                    .tracking(1)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: 160)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sun Seeker Info Sheet
struct SunSeekerInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Sun Seeker Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Tell Sun Seeker about your window direction and lighting conditions to find the perfect spot for every plant.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "sun.max.fill", title: "Light Estimator", text: "Select your window direction and whether you get direct sun to instantly estimate light intensity, measured as a percentage of full sun exposure.", color: .orange)
                            
                            InfoRow(icon: "circle.fill", title: "Low Light (0-30%)", text: "North-facing windows and deep corners. Perfect for snake plants, ZZ plants, pothos, and peace lilies.", color: .blue)
                            
                            InfoRow(icon: "circle.fill", title: "Medium Light (30-70%)", text: "East or west-facing windows with filtered light. Ideal for most tropical houseplants and ferns.", color: .green)
                            
                            InfoRow(icon: "circle.fill", title: "Bright Light (70-100%)", text: "South-facing windows or direct sun. Best for succulents, cacti, herbs, and sun-loving tropicals.", color: .orange)
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

// MARK: - Repotting Helper Info Sheet
struct RepottingHelperInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Repotting Helper Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Calculate the ideal new pot size based on your current pot diameter, root condition, and the plant's growth rate.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Size Calculation", text: "We recommend going up 1-2 inches in diameter. Too large a jump can lead to waterlogged soil and root rot.", color: .brown)
                            
                            InfoRow(icon: "arrow.triangle.branch", title: "Root Bound Signs", text: "Roots circling the pot, poking from drainage holes, or pushing the plant upward all indicate it's time to repot.", color: .green)
                            
                            InfoRow(icon: "chart.line.uptrend.xyaxis", title: "Growth Rate Factor", text: "Fast growers like pothos may need a larger size jump, while slow growers like snake plants prefer a snugger fit.", color: .blue)
                            
                            InfoRow(icon: "calendar", title: "Best Timing", text: "Spring is the ideal repotting season when plants are actively growing and can recover quickly from root disturbance.", color: .orange)
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

#Preview {
    ToolsView()
}

