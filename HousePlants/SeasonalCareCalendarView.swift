import SwiftUI

struct SeasonalCareCalendarView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var animateLeaf = false
    @State private var showInfoSheet = false
    
    let months = Calendar.current.monthSymbols
    
    var currentSeason: Season {
        Season.from(month: selectedMonth)
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Seasonal Care",
                    subtitle: "Month-by-month plant care timeline",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color(hex: "4CAF50").opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Season Hero
                        VStack(spacing: 16) {
                            ZStack {
                                // Background ring
                                Circle()
                                    .fill(currentSeason.color.opacity(0.08))
                                    .frame(width: 120, height: 120)
                                
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(currentSeason.color.opacity(0.1), lineWidth: 1.5)
                                        .frame(width: 120 + CGFloat(i * 28), height: 120 + CGFloat(i * 28))
                                        .scaleEffect(animateLeaf ? 1.06 : 1.0)
                                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: animateLeaf)
                                }
                                
                                Image(systemName: currentSeason.icon)
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(colors: currentSeason.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .shadow(color: currentSeason.color.opacity(0.3), radius: 10)
                            }
                            .onAppear { animateLeaf = true }
                            
                            VStack(spacing: 4) {
                                Text(currentSeason.name)
                                    .font(.claudeSerif(size: 26, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                                
                                Text(currentSeason.subtitle)
                                    .font(.claudeSans(size: 14))
                                    .foregroundColor(.claudeSecondaryText)
                                    .italic()
                            }
                        }
                        .padding(.top, 8)
                        
                        // Month Selector
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(1...12, id: \.self) { month in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedMonth = month
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                Text(shortMonth(month))
                                                    .font(.claudeSans(size: 12, weight: .bold))
                                                
                                                // Season dot indicator
                                                Circle()
                                                    .fill(Season.from(month: month).color)
                                                    .frame(width: 6, height: 6)
                                            }
                                            .frame(width: 52, height: 52)
                                            .background(selectedMonth == month ? currentSeason.color : Color.claudeSecondaryBackground)
                                            .foregroundColor(selectedMonth == month ? .white : .claudePrimaryText)
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(selectedMonth == month ? currentSeason.color : Color.claudeBorder, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(BubblingButtonStyle())
                                        .id(month)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .onAppear {
                                proxy.scrollTo(selectedMonth, anchor: .center)
                            }
                            .onChange(of: selectedMonth) { _, newValue in
                                withAnimation {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                        }
                        
                        // Care Tasks for Month
                        let tasks = SeasonalTask.tasks(for: selectedMonth)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("\(months[selectedMonth - 1].uppercased()) CARE GUIDE")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            ForEach(tasks) { task in
                                SeasonalTaskCard(task: task)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Quick Tips for Season
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SEASONAL WISDOM")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                ForEach(currentSeason.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.orange)
                                            .frame(width: 28, height: 28)
                                            .background(Color.orange.opacity(0.1))
                                            .clipShape(Circle())
                                        
                                        Text(tip)
                                            .font(.claudeSans(size: 14))
                                            .foregroundColor(.claudePrimaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.claudeSecondaryBackground)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            SeasonalCareInfoSheet()
        }
    }
    
    func shortMonth(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = month
        return formatter.string(from: Calendar.current.date(from: components)!)
    }
}

// MARK: - Season Model

enum Season {
    case spring, summer, autumn, winter
    
    static func from(month: Int) -> Season {
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        case 12, 1, 2: return .winter
        default: return .spring
        }
    }
    
    var name: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }
    
    var subtitle: String {
        switch self {
        case .spring: return "Season of awakening and growth"
        case .summer: return "Peak growing season"
        case .autumn: return "Time to prepare and slow down"
        case .winter: return "Rest, recover, and plan ahead"
        }
    }
    
    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }
    
    var color: Color {
        switch self {
        case .spring: return Color(hex: "4CAF50")
        case .summer: return Color(hex: "FF9800")
        case .autumn: return Color(hex: "E67E22")
        case .winter: return Color(hex: "5DADE2")
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .spring: return [Color(hex: "4CAF50"), Color(hex: "81C784")]
        case .summer: return [Color(hex: "FF9800"), Color(hex: "FFB74D")]
        case .autumn: return [Color(hex: "E67E22"), Color(hex: "F0B27A")]
        case .winter: return [Color(hex: "5DADE2"), Color(hex: "85C1E9")]
        }
    }
    
    var tips: [String] {
        switch self {
        case .spring:
            return [
                "Gradually increase watering as days grow longer and plants break dormancy.",
                "This is the ideal time to repot root-bound plants into fresh soil.",
                "Begin a light fertilizing routine — half-strength is best to start.",
                "Inspect all plants for signs of new pests emerging with warmer temperatures."
            ]
        case .summer:
            return [
                "Water early morning or late evening to reduce evaporation loss.",
                "Rotate plants weekly for even light distribution during peak sun.",
                "Increase humidity for tropical species — misting or pebble trays help.",
                "Watch for sunburn on leaves moved near south-facing windows."
            ]
        case .autumn:
            return [
                "Gradually reduce watering frequency as growth slows down.",
                "Stop fertilizing most houseplants by late October.",
                "Bring outdoor plants inside before nighttime temperatures drop below 50°F.",
                "Clean leaves to maximize light absorption during shorter days."
            ]
        case .winter:
            return [
                "Water sparingly — most plants need far less water during dormancy.",
                "Keep plants away from cold drafts, radiators, and heating vents.",
                "Maximize natural light by cleaning windows and moving plants closer.",
                "Hold off on repotting until spring unless absolutely necessary."
            ]
        }
    }
}

// MARK: - Seasonal Task Model

struct SeasonalTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let priority: TaskPriority
    
    enum TaskPriority: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
    
    static func tasks(for month: Int) -> [SeasonalTask] {
        switch month {
        case 1: // January
            return [
                SeasonalTask(title: "Minimal Watering", description: "Most plants are dormant. Check soil deeply before watering — overwatering in winter is the most common cause of root rot.", icon: "drop.fill", color: .blue, priority: .high),
                SeasonalTask(title: "Maximize Light", description: "Move plants closer to south-facing windows. Clean glass for maximum photon transmission.", icon: "sun.max.fill", color: .orange, priority: .high),
                SeasonalTask(title: "Inspect for Pests", description: "Dry indoor heating creates favorable conditions for spider mites. Check leaf undersides weekly.", icon: "ladybug.fill", color: .red, priority: .medium),
                SeasonalTask(title: "Plan Spring Propagation", description: "Research propagation methods for your collection. Order supplies for stem cuttings and division.", icon: "calendar", color: .purple, priority: .low)
            ]
        case 2: // February
            return [
                SeasonalTask(title: "Pre-Spring Assessment", description: "Examine each plant for health. Note any that need repotting, pruning, or treatment when spring arrives.", icon: "magnifyingglass", color: .teal, priority: .high),
                SeasonalTask(title: "Light Pruning", description: "Remove dead or yellowing leaves to redirect energy. Save major pruning for March.", icon: "scissors", color: .green, priority: .medium),
                SeasonalTask(title: "Humidity Check", description: "Indoor air is still very dry. Group tropical plants together to create a humidity microclimate.", icon: "humidity.fill", color: .cyan, priority: .medium),
                SeasonalTask(title: "Order Supplies", description: "Get fresh potting mix, perlite, and fertilizer ready for the spring growing season ahead.", icon: "cart.fill", color: .brown, priority: .low)
            ]
        case 3: // March
            return [
                SeasonalTask(title: "Resume Fertilizing", description: "Begin with half-strength balanced fertilizer as plants emerge from dormancy and new growth appears.", icon: "leaf.fill", color: .green, priority: .high),
                SeasonalTask(title: "Spring Repotting", description: "Now is the ideal time to repot root-bound plants. Go up one pot size with fresh, well-draining soil.", icon: "arrow.up.left.and.arrow.down.right.circle.fill", color: .brown, priority: .high),
                SeasonalTask(title: "Increase Watering", description: "As daylight increases, plants metabolize more. Gradually increase watering frequency.", icon: "drop.fill", color: .blue, priority: .medium),
                SeasonalTask(title: "Start Propagation", description: "Take stem cuttings from healthy parent plants. Warmth and increasing light favor root development.", icon: "scissors", color: .purple, priority: .medium)
            ]
        case 4: // April
            return [
                SeasonalTask(title: "Full Fertilizing Schedule", description: "Transition to regular-strength fertilizer for actively growing plants. Every 2-4 weeks is ideal.", icon: "flask.fill", color: .green, priority: .high),
                SeasonalTask(title: "Pest Prevention", description: "Aphids and mealybugs emerge in spring. Apply preventive neem oil treatments.", icon: "ladybug.fill", color: .red, priority: .high),
                SeasonalTask(title: "Rotate Plants", description: "With stronger sun, rotate all plants 90° weekly for symmetrical growth.", icon: "arrow.clockwise", color: .orange, priority: .medium),
                SeasonalTask(title: "Outdoor Transition", description: "Start hardening off plants for outdoor summer placement. Begin with a few hours of shade daily.", icon: "sun.haze.fill", color: .yellow, priority: .low)
            ]
        case 5: // May
            return [
                SeasonalTask(title: "Deep Watering", description: "Warmer days mean higher water demands. Water deeply and thoroughly, letting excess drain.", icon: "drop.fill", color: .blue, priority: .high),
                SeasonalTask(title: "Sun Protection", description: "Direct afternoon sun intensifies. Move sensitive plants back from south windows or add sheer curtains.", icon: "sun.max.trianglebadge.exclamationmark.fill", color: .orange, priority: .high),
                SeasonalTask(title: "Division Time", description: "Overcrowded plants benefit from division now. Separate clumps and share with friends.", icon: "arrow.triangle.branch", color: .green, priority: .medium),
                SeasonalTask(title: "Clean Leaves", description: "Dust accumulation blocks light. Gently wipe leaves with a damp cloth for optimal photosynthesis.", icon: "sparkles", color: .teal, priority: .low)
            ]
        case 6: // June
            return [
                SeasonalTask(title: "Peak Growth Support", description: "Plants are at maximum growth rate. Ensure consistent watering, feeding, and light.", icon: "chart.line.uptrend.xyaxis", color: .green, priority: .high),
                SeasonalTask(title: "Humidity Boost", description: "Air conditioning dries indoor air. Mist tropical plants or run a humidifier nearby.", icon: "humidity.fill", color: .cyan, priority: .high),
                SeasonalTask(title: "Stake & Train", description: "Fast-growing vines and climbers need support. Install moss poles or trellises now.", icon: "arrow.up", color: .brown, priority: .medium),
                SeasonalTask(title: "Watch for Sunburn", description: "Leaves showing bleached or brown patches from direct sun? Relocate or add shade.", icon: "exclamationmark.triangle.fill", color: .red, priority: .medium)
            ]
        case 7: // July
            return [
                SeasonalTask(title: "Heat Stress Monitoring", description: "Check soil moisture daily during heat waves. Some plants may need watering every other day.", icon: "thermometer.high", color: .red, priority: .high),
                SeasonalTask(title: "Continue Feeding", description: "Maintain regular fertilizer schedule for actively growing plants. Switch to bloom formula for flowering types.", icon: "leaf.fill", color: .green, priority: .high),
                SeasonalTask(title: "Propagation Window", description: "Summer warmth accelerates root development. Take cuttings of your favorites.", icon: "scissors", color: .purple, priority: .medium),
                SeasonalTask(title: "Vacation Prep", description: "Traveling? Group plants in a bright bathroom. Self-watering stakes or wicks can help.", icon: "suitcase.fill", color: .blue, priority: .low)
            ]
        case 8: // August
            return [
                SeasonalTask(title: "Late Summer Pruning", description: "Shape leggy growth from the growing season. Remove spent blooms to encourage new flowers.", icon: "scissors", color: .green, priority: .high),
                SeasonalTask(title: "Soil Check", description: "Months of watering can compact soil. Aerate with a chopstick if water pools on the surface.", icon: "square.stack.3d.up.fill", color: .brown, priority: .medium),
                SeasonalTask(title: "Pest Patrol", description: "Late summer is peak pest season. Thoroughly inspect all plants, especially new acquisitions.", icon: "ladybug.fill", color: .red, priority: .high),
                SeasonalTask(title: "Start Autumn Transition", description: "Begin reducing fertilizer strength. Plants are starting to slow their metabolic rate.", icon: "arrow.down.right", color: .orange, priority: .low)
            ]
        case 9: // September
            return [
                SeasonalTask(title: "Bring Plants Indoors", description: "Night temps dropping below 55°F? Time to bring tropical plants back inside.", icon: "house.fill", color: .blue, priority: .high),
                SeasonalTask(title: "Reduce Watering", description: "Growth slows as days shorten. Allow soil to dry more between waterings.", icon: "drop.fill", color: .cyan, priority: .high),
                SeasonalTask(title: "Last Fertilizer Application", description: "Give a final half-strength feeding. Plants entering dormancy shouldn't be pushed to grow.", icon: "flask.fill", color: .green, priority: .medium),
                SeasonalTask(title: "Quarantine New Plants", description: "Isolate any plants brought indoors from outdoors for 2 weeks to prevent pest introductions.", icon: "shield.checkered", color: .orange, priority: .medium)
            ]
        case 10: // October
            return [
                SeasonalTask(title: "Stop Fertilizing", description: "Most houseplants should not be fertilized from now until March. Let them rest.", icon: "xmark.circle.fill", color: .red, priority: .high),
                SeasonalTask(title: "Adjust Light Positions", description: "With shorter days, move plants to brighter spots. Consider grow lights for light-hungry species.", icon: "lightbulb.fill", color: .yellow, priority: .high),
                SeasonalTask(title: "Reduce Humidity Needs", description: "Cooler temps mean less evaporation. Only mist plants that truly need high humidity.", icon: "humidity.fill", color: .cyan, priority: .medium),
                SeasonalTask(title: "Root Health Check", description: "Gently unpot and inspect roots of any struggling plants. Treat rot before winter dormancy.", icon: "cross.case.fill", color: .red, priority: .medium)
            ]
        case 11: // November
            return [
                SeasonalTask(title: "Minimal Watering Mode", description: "Winter is approaching fast. Water only when topsoil is fully dry, 1-2\" deep.", icon: "drop.fill", color: .blue, priority: .high),
                SeasonalTask(title: "Protect from Drafts", description: "Move plants away from cold windows, doors, and heating vents that create dry hot spots.", icon: "wind", color: .gray, priority: .high),
                SeasonalTask(title: "Clean Foliage", description: "With less available light, clean leaves are essential for maximum photosynthesis.", icon: "sparkles", color: .teal, priority: .medium),
                SeasonalTask(title: "Group for Humidity", description: "Cluster tropical plants together to create a shared humidity microclimate.", icon: "rectangle.3.group.fill", color: .green, priority: .low)
            ]
        case 12: // December
            return [
                SeasonalTask(title: "Holiday Plant Care", description: "Poinsettias need 14+ hours of darkness for red bracts. Keep amaryllis warm and watered.", icon: "gift.fill", color: .red, priority: .high),
                SeasonalTask(title: "Dormancy Respect", description: "Most plants are fully dormant. This is normal — don't panic over lack of new growth.", icon: "moon.zzz.fill", color: .indigo, priority: .high),
                SeasonalTask(title: "Grow Light Assessment", description: "If plants are stretching or losing color, invest in full-spectrum LED grow lights.", icon: "lightbulb.led.fill", color: .yellow, priority: .medium),
                SeasonalTask(title: "Year-End Reflection", description: "Review your plant journal. Note successes, losses, and plans for the coming growth season.", icon: "book.fill", color: .purple, priority: .low)
            ]
        default:
            return []
        }
    }
}

// MARK: - Task Card View

struct SeasonalTaskCard: View {
    let task: SeasonalTask
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(task.color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: task.icon)
                    .font(.system(size: 20))
                    .foregroundColor(task.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.claudeSans(size: 16, weight: .bold))
                        .foregroundColor(.claudePrimaryText)
                    
                    Spacer()
                    
                    Text(task.priority.rawValue.uppercased())
                        .font(.claudeSans(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(task.priority.color.opacity(0.1))
                        )
                }
                
                Text(task.description)
                    .font(.claudeSans(size: 13))
                    .foregroundColor(.claudeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

// MARK: - Info Sheet View
struct SeasonalCareInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How Seasonal Care Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("A month-by-month calendar of essential care tasks, adapting to each season's unique demands on your houseplants.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "leaf.fill", title: "Spring", text: "The season of awakening. Increase watering, start fertilizing at half strength, and repot root-bound plants into fresh substrate.", color: Color(hex: "4CAF50"))
                            
                            InfoRow(icon: "sun.max.fill", title: "Summer", text: "Peak growth demands consistent care. Water frequently, rotate for even light, and watch for heat stress and sunburn.", color: Color(hex: "FF9800"))
                            
                            InfoRow(icon: "wind", title: "Autumn", text: "Time to slow down. Reduce watering, stop fertilizing, and bring outdoor plants inside before temperatures drop.", color: Color(hex: "E67E22"))
                            
                            InfoRow(icon: "snowflake", title: "Winter", text: "Respect dormancy. Water sparingly, keep plants away from cold drafts and heating vents, and maximize available light.", color: Color(hex: "5DADE2"))
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
    NavigationView {
        SeasonalCareCalendarView()
    }
}
