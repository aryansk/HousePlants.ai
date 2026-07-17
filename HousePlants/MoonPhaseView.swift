import SwiftUI

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
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                            .accessibilityLabel("Previous day")
                            
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
                            .frame(minHeight: 44)
                            .accessibilityLabel("Choose date")
                            .accessibilityValue(formattedDate(selectedDate))
                            
                            Button(action: { shiftDate(by: 1) }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                            .accessibilityLabel("Next day")
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


#Preview {
    CelestialMoonPhaseView()
}
