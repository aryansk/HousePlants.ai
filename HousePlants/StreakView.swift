import SwiftUI

struct StreakView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @Environment(\.dismiss) var dismiss
    
    @State private var pulseAmount: CGFloat = 1.0
    @State private var fireScale: CGFloat = 0.01
    @State private var numberScale: CGFloat = 0.01
    @State private var showMilestoneGlow = false
    @State private var showConfetti = false
    
    var streakCount: Int {
        dataLoader.userProfile?.currentStreak ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Flame Icon and Count
                    VStack(spacing: 16) {
                        ZStack {
                            if showMilestoneGlow {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(pulseAmount * 1.2)
                                    .opacity(2 - pulseAmount)
                            }
                            
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseAmount)
                                
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulseAmount * 0.95)
                                
                            Image(systemName: "flame.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                                .scaleEffect(fireScale)
                                .rotationEffect(.degrees(fireScale == 1 ? 0 : -10))
                        }
                        
                        Text("\(streakCount)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(Color.orange)
                            .scaleEffect(numberScale)
                            
                        Text("Day Streak")
                            .font(.claudeSerif(size: 24, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                            .opacity(numberScale == 1 ? 1 : 0)
                            .offset(y: numberScale == 1 ? 0 : 20)
                    }
                    .padding(.top, 40)
                    
                    // Streak Status Text
                    Text(streakCount > 0 ? "You're on a roll! Keep coming back every day to watch your jungle grow." : "Water your plants or check your jungle daily to build your streak!")
                        .font(.claudeSans(size: 16))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Week Calendar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past 7 Days")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                            
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                DayCircle(index: index, history: dataLoader.userProfile?.streakHistory ?? [])
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.claudeSecondaryBackground)
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.claudeAccent)
                            .cornerRadius(16)
                            .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                
                if showConfetti {
                    MilestoneConfetti()
                        .offset(y: -100)
                }
            }
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    fireScale = 1.0
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                    numberScale = 1.0
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAmount = 1.1
                }
                
                // Show confetti and glow for milestone days
                if streakCount > 0 && (streakCount == 1 || streakCount % 7 == 0 || streakCount % 10 == 0) {
                    showConfetti = true
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        showMilestoneGlow = true
                    }
                }
            }
        }
    }
}

struct DayCircle: View {
    let index: Int
    let history: [String]
    
    var dateString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Start from 6 days ago up to today
        let offset = index - 6
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return "" }
        return DataLoader.isoFormatter.string(from: date)
    }
    
    var dayInitial: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let offset = index - 6
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return String(formatter.string(from: date).prefix(1))
    }
    
    var isActive: Bool {
        history.contains(dateString)
    }
    
    var isToday: Bool {
        index == 6
    }
    
    @State private var isAppeared = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.orange : Color.gray.opacity(0.1))
                    .frame(height: 40)
                    
                if isActive {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .scaleEffect(isAppeared ? 1 : 0.01)
                }
            }
            .scaleEffect(isAppeared ? 1 : 0.01)
            
            Text(dayInitial)
                .font(.system(size: 12, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .claudePrimaryText : .gray)
                .opacity(isAppeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.1)) {
                isAppeared = true
            }
        }
    }
}

struct MilestoneConfetti: View {
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: View {
    let startX: CGFloat = 0
    let startY: CGFloat = 0
    let endX: CGFloat = .random(in: -200...200)
    let endY: CGFloat = .random(in: -400...100)
    
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = .random(in: 0...360)
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = .random(in: 1.0...2.5)
    @State private var emoji: String = ["🌿", "🍃", "🌱", "🍀", "🪴", "☘️"].randomElement() ?? "🌿"
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 20))
            .scaleEffect(scale)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: .random(in: 0.8...1.2))) {
                    xOffset = endX
                    yOffset = endY
                    rotation += .random(in: 180...360)
                }
                
                withAnimation(.easeIn(duration: 1.5).delay(1.0)) {
                    yOffset += 400
                    opacity = 0
                }
            }
    }
}
