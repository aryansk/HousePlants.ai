import SwiftUI

// MARK: - Moon Phase Calculator
struct MoonCalculator {
    static func moonAge(for date: Date) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        var r = year % 100
        r = r % 19
        if r > 9 { r -= 19 }
        r = ((r * 11) % 30) + month + day
        if month < 3 { r += 2 }
        r -= ((year < 2000) ? 4 : 8)
        r = ((r + 30) % 30)
        return Double(r < 0 ? r + 30 : r)
    }
    
    static func phaseFraction(for date: Date) -> Double {
        return moonAge(for: date) / 29.53
    }
    
    static func illumination(for date: Date) -> Double {
        let fraction = phaseFraction(for: date)
        return (1.0 - cos(fraction * 2 * .pi)) / 2.0 * 100.0
    }
    
    static func phaseName(for date: Date) -> String {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:     return "New Moon"
        case 1.85..<7.38:  return "Waxing Crescent"
        case 7.38..<9.23:  return "First Quarter"
        case 9.23..<14.77: return "Waxing Gibbous"
        case 14.77..<16.61: return "Full Moon"
        case 16.61..<22.15: return "Waning Gibbous"
        case 22.15..<24.0: return "Last Quarter"
        case 24.0..<29.53: return "Waning Crescent"
        default: return "New Moon"
        }
    }
    
    static func phaseIcon(for date: Date) -> String {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:     return "moonphase.new.moon"
        case 1.85..<7.38:  return "moonphase.waxing.crescent"
        case 7.38..<9.23:  return "moonphase.first.quarter"
        case 9.23..<14.77: return "moonphase.waxing.gibbous"
        case 14.77..<16.61: return "moonphase.full.moon"
        case 16.61..<22.15: return "moonphase.waning.gibbous"
        case 22.15..<24.0: return "moonphase.last.quarter"
        case 24.0..<29.53: return "moonphase.waning.crescent"
        default: return "moonphase.new.moon"
        }
    }
    
    static func nextPhaseDate(from date: Date, targetAge: Double) -> Date {
        let currentAge = moonAge(for: date)
        var daysUntil = targetAge - currentAge
        if daysUntil <= 0 { daysUntil += 29.53 }
        return Calendar.current.date(byAdding: .day, value: Int(ceil(daysUntil)), to: date) ?? date
    }
    
    static func gardeningAdvice(for date: Date) -> (title: String, advice: String, activities: [GardeningActivity]) {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:
            return ("Rest & Plan", "The new moon is a time for rest. Plan your garden layout and prepare seeds for the cycle ahead.",
                    [.init(name: "Plan Layout", icon: "map", recommended: true),
                     .init(name: "Prepare Soil", icon: "square.stack.3d.up.fill", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false),
                     .init(name: "Harvest", icon: "basket", recommended: false)])
        case 1.85..<7.38:
            return ("Sow & Sprout", "Rising lunar light encourages leaf growth. Ideal for planting leafy greens and above-ground crops.",
                    [.init(name: "Sow Seeds", icon: "leaf", recommended: true),
                     .init(name: "Graft Plants", icon: "scissors", recommended: true),
                     .init(name: "Fertilize", icon: "drop.fill", recommended: true),
                     .init(name: "Prune", icon: "scissors", recommended: false)])
        case 7.38..<9.23:
            return ("Growth Surge", "First quarter moon pulls moisture upward. Strong sap flow benefits transplanting.",
                    [.init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: true),
                     .init(name: "Fertilize", icon: "drop.fill", recommended: true),
                     .init(name: "Plant Vines", icon: "leaf.arrow.triangle.pullpath", recommended: true),
                     .init(name: "Root Crops", icon: "carrot", recommended: false)])
        case 9.23..<14.77:
            return ("Peak Energy", "Optimal alignment for foliar feeding. Focus on nutrient absorption while the lunar pull is strong.",
                    [.init(name: "Foliar Feed", icon: "spray", recommended: true),
                     .init(name: "Water Deeply", icon: "drop.fill", recommended: true),
                     .init(name: "Mist Leaves", icon: "humidity.fill", recommended: true),
                     .init(name: "Heavy Prune", icon: "scissors", recommended: false)])
        case 14.77..<16.61:
            return ("Harvest Moon", "Full moon maximum light and gravity. Harvest herbs at peak potency. Avoid pruning.",
                    [.init(name: "Harvest Herbs", icon: "leaf.fill", recommended: true),
                     .init(name: "Harvest Fruit", icon: "basket", recommended: true),
                     .init(name: "Make Cuttings", icon: "scissors", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false)])
        case 16.61..<22.15:
            return ("Wind Down", "Declining light draws energy to roots. Perfect for root crops and bulbs.",
                    [.init(name: "Plant Bulbs", icon: "circle.fill", recommended: true),
                     .init(name: "Root Crops", icon: "carrot", recommended: true),
                     .init(name: "Compost", icon: "leaf.arrow.triangle.pullpath", recommended: true),
                     .init(name: "Sow Seeds", icon: "leaf", recommended: false)])
        case 22.15..<24.0:
            return ("Deep Roots", "Last quarter. Energy concentrated below ground. Excellent time for pruning and weeding.",
                    [.init(name: "Prune", icon: "scissors", recommended: true),
                     .init(name: "Weed", icon: "xmark.circle", recommended: true),
                     .init(name: "Pest Control", icon: "ant", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false)])
        default:
            return ("Rest Phase", "Waning crescent. The cycle nears its end. Clear debris and prepare for the next new moon.",
                    [.init(name: "Clear Debris", icon: "trash", recommended: true),
                     .init(name: "Turn Soil", icon: "square.stack.3d.up.fill", recommended: true),
                     .init(name: "Rest", icon: "moon.zzz", recommended: true),
                     .init(name: "Sow Seeds", icon: "leaf", recommended: false)])
        }
    }
}

struct GardeningActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let recommended: Bool
}

// MARK: - Main View
struct CelestialMoonPhaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var selectedTab: Int = 0
    @State private var showInfoSheet = false
    
    private var phaseName: String { MoonCalculator.phaseName(for: selectedDate) }
    private var illumination: Double { MoonCalculator.illumination(for: selectedDate) }
    private var phaseFraction: Double { MoonCalculator.phaseFraction(for: selectedDate) }
    private var advice: (title: String, advice: String, activities: [GardeningActivity]) {
        MoonCalculator.gardeningAdvice(for: selectedDate)
    }
    private var nextFull: Date { MoonCalculator.nextPhaseDate(from: selectedDate, targetAge: 14.77) }
    private var nextNew: Date { MoonCalculator.nextPhaseDate(from: selectedDate, targetAge: 0) }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        ZStack {
            // Celestial Dark Theme
            LinearGradient(colors: [Color(hex: "090A0F"), Color(hex: "171821")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Back")
                                    .font(.claudeSans(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 12)
                        
                        Text("Moon Gardening")
                            .font(.claudeSerif(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Celestial planting guide")
                            .font(.claudeSans(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .padding(.top, 28) // roughly align with title
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                        
                        // Date Selector Pill
                        HStack(spacing: 16) {
                            Button(action: { shiftDate(by: -1) }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                            
                            Button(action: { withAnimation(.spring()) { showDatePicker.toggle() } }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "A9B2F6")) // Subtle indigo
                                    Text(isToday ? "Today" : formattedDate(selectedDate))
                                        .font(.claudeSans(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            
                            Button(action: { shiftDate(by: 1) }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                        }
                        
                        if showDatePicker {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .tint(Color(hex: "818CF8"))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                )
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Large Moon Graphic Component
                        ZStack {
                            // Outer Glow
                            Circle()
                                .fill(RadialGradient(gradient: Gradient(colors: [.white.opacity(0.15), .clear]), center: .center, startRadius: 50, endRadius: 180))
                                .frame(width: 360, height: 360)
                            
                            MoonGraphic(phase: phaseFraction)
                                .frame(width: 220, height: 220)
                                .shadow(color: .white.opacity(0.3), radius: 40)
                            
                            // Info Tags floating around the moon
                            VStack {
                                Spacer()
                                HStack {
                                    // Phase Badge
                                    HStack(spacing: 6) {
                                        Image(systemName: MoonCalculator.phaseIcon(for: selectedDate))
                                            .font(.system(size: 12))
                                        Text(phaseName.uppercased())
                                            .font(.claudeSans(size: 11, weight: .bold))
                                            .tracking(1.5)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.black.opacity(0.5)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                                    
                                    // Illumination Badge
                                    HStack(spacing: 4) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                        Text("\(Int(illumination))% LIT")
                                            .font(.claudeSans(size: 11, weight: .bold))
                                            .tracking(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.black.opacity(0.5)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                                }
                                .offset(y: 20)
                            }
                            .frame(height: 220)
                        }
                        .padding(.vertical, 10)
                        
                        // Tab Selector
                        HStack(spacing: 0) {
                            MoonTabButton(title: "Wisdom", isSelected: selectedTab == 0) { withAnimation(.spring()) { selectedTab = 0 } }
                            MoonTabButton(title: "Activities", isSelected: selectedTab == 1) { withAnimation(.spring()) { selectedTab = 1 } }
                            MoonTabButton(title: "Forecast", isSelected: selectedTab == 2) { withAnimation(.spring()) { selectedTab = 2 } }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 24)
                        
                        // Tab Content
                        Group {
                            switch selectedTab {
                            case 0:
                                lunarWisdomCard
                            case 1:
                                activitiesCard
                            case 2:
                                calendarCard
                            default:
                                EmptyView()
                            }
                        }
                        .transition(.opacity)
                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            MoonGardeningInfoSheet()
        }
    }
    
    // MARK: - Lunar Wisdom Tab
    private var lunarWisdomCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4ADE80").opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color(hex: "4ADE80"))
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT PHASE FOCUS")
                        .font(.claudeSans(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.5)
                    Text(advice.title)
                        .font(.claudeSerif(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            Text(advice.advice)
                .font(.claudeSans(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Activities Tab
    private var activitiesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECOMMENDED ACTIVITIES")
                    .font(.claudeSans(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                Spacer()
            }
            
            // 2x2 Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(advice.activities) { activity in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: activity.icon)
                                .font(.system(size: 20))
                                .foregroundColor(activity.recommended ? Color(hex: "4ADE80") : Color.red.opacity(0.8))
                            Spacer()
                            Image(systemName: activity.recommended ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(activity.recommended ? Color(hex: "4ADE80") : Color.red.opacity(0.8))
                        }
                        
                        Text(activity.name)
                            .font(.claudeSans(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Calendar Tab (7 Day Forecast)
    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("7-DAY FORECAST")
                    .font(.claudeSans(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        
                        Button(action: { withAnimation(.spring()) { selectedDate = date } }) {
                            VStack(spacing: 10) {
                                Text(dayLabel(date))
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                                
                                Text(dayNumber(date))
                                    .font(.claudeSans(size: 18, weight: .bold))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                                
                                MoonGraphic(phase: MoonCalculator.phaseFraction(for: date))
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .white.opacity(0.2), radius: 5)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .frame(width: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isSelected ? Color(hex: "818CF8").opacity(0.4) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color(hex: "818CF8").opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Key Events
            VStack(spacing: 10) {
                LunarEventRow(icon: "moonphase.full.moon", title: "Next Full Moon", date: formattedDate(nextFull), daysAway: daysUntil(nextFull), color: Color(hex: "FACC15"))
                LunarEventRow(icon: "moonphase.new.moon", title: "Next New Moon", date: formattedDate(nextNew), daysAway: daysUntil(nextNew), color: Color(hex: "818CF8"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helpers
    
    private func shiftDate(by days: Int) {
        withAnimation(.spring()) {
            selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func daysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: selectedDate), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "1 Day" }
        return "\(days) Days"
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

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

// Removed StarfieldView

#Preview {
    CelestialMoonPhaseView()
}
