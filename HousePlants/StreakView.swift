import SwiftUI

struct StreakView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dismiss) var dismiss
    
    var streakCount: Int {
        dataLoader.userProfile?.currentStreak ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // A static hero keeps the sheet calm and lets the number carry the emphasis.
                        VStack(spacing: 12) {
                            Text(streakCount == 1 ? "Your first day" : "Your current rhythm")
                                .font(.claudeSans(size: 15, weight: .semibold))
                                .foregroundStyle(Color.claudeSecondaryText)
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.13))
                                    .frame(width: 96, height: 96)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                            }

                            Text("\(streakCount)")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.claudePrimaryText)
                            Text(streakCount == 1 ? "day streak" : "day streak")
                                .font(.claudeSerif(size: 24, weight: .bold))
                                .foregroundStyle(Color.claudePrimaryText)
                        }
                        .padding(.top, 24)

                        Text(streakCount > 0 ? "Come back tomorrow to keep your streak growing." : "Care for a plant today to start your streak.")
                            .font(.claudeSans(size: 16))
                            .foregroundStyle(Color.claudeSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 28)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("This week")
                                    .font(.claudeSans(size: 16, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                Spacer()
                                Text("\(streakCount) day\(streakCount == 1 ? "" : "s") active")
                                    .font(.claudeSans(size: 13, weight: .medium))
                                    .foregroundStyle(Color.claudeSecondaryText)
                            }
                            HStack(spacing: 8) {
                                ForEach(0..<7, id: \.self) { index in
                                    DayCircle(index: index, history: dataLoader.userProfile?.streakHistory ?? [])
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.claudeSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 24)

                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.claudeSans(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.claudeAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                    }
                    .padding(.bottom, 28)
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
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.orange : Color.claudeBorder.opacity(0.7))
                    .frame(width: 36, height: 36)
                    
                if isActive {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Text(dayInitial)
                .font(.system(size: 12, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .claudePrimaryText : .gray)
        }
        .frame(maxWidth: .infinity)
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
