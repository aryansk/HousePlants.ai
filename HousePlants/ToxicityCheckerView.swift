import SwiftUI

struct ToxicityCheckerView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var searchText = ""
    @State private var filterMode: ToxicityFilter = .all
    @State private var animateShield = false
    @State private var showInfoSheet = false
    
    enum ToxicityFilter: String, CaseIterable {
        case all = "All Plants"
        case safe = "Pet Safe"
        case toxic = "Toxic"
    }
    
    var filteredPlants: [Plant] {
        var result = dataLoader.plants
        
        switch filterMode {
        case .safe:
            result = result.filter { $0.toxicity.isPetSafe }
        case .toxic:
            result = result.filter { !$0.toxicity.isPetSafe }
        case .all:
            break
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.commonName.localizedCaseInsensitiveContains(searchText) ||
                $0.botanicalName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort: toxic first when showing all, for awareness
        if filterMode == .all {
            result.sort { !$0.toxicity.isPetSafe && $1.toxicity.isPetSafe }
        }
        
        return result
    }
    
    var safeCount: Int {
        dataLoader.plants.filter { $0.toxicity.isPetSafe }.count
    }
    
    var toxicCount: Int {
        dataLoader.plants.filter { !$0.toxicity.isPetSafe }.count
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Toxicity Checker",
                    subtitle: "Keep your furry friends safe",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.green.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                        
                        // Hero Shield
                        VStack(spacing: 16) {
                            ZStack {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(Color.green.opacity(0.12), lineWidth: 2)
                                        .frame(width: 96 + CGFloat(i * 32), height: 96 + CGFloat(i * 32))
                                        .scaleEffect(animateShield ? 1.06 : 1.0)
                                        .opacity(animateShield ? 0.4 : 0.12)
                                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: animateShield)
                                }
                                
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(width: 96, height: 96)
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 42))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.green, Color(hex: "2ECC71")], startPoint: .top, endPoint: .bottom)
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8)
                            }
                            .onAppear { animateShield = true }
                            
                            Text("Protecting paws and whiskers since day one.")
                                .font(.claudeSans(size: 14))
                                .foregroundColor(.claudeSecondaryText)
                                .italic()
                        }
                        .padding(.top, 8)
                        
                        // Stats Overview
                        HStack(spacing: 12) {
                            ToxicityStatCard(
                                count: safeCount,
                                label: "Pet Safe",
                                icon: "checkmark.shield.fill",
                                color: .green
                            )
                            ToxicityStatCard(
                                count: toxicCount,
                                label: "Caution",
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Search
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.claudeSecondaryText)
                            TextField("Search any plant...", text: $searchText)
                                .font(.claudeSans(size: 15))
                                .foregroundColor(.claudePrimaryText)
                        }
                        .padding(14)
                        .background(Color.claudeSecondaryBackground)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Filter Segmented Control
                        HStack(spacing: 0) {
                            ForEach(ToxicityFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        filterMode = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.claudeSans(size: 13, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(filterMode == filter ? Color.claudeAccent : Color.clear)
                                        .foregroundColor(filterMode == filter ? .white : .claudeSecondaryText)
                                }
                            }
                        }
                        .background(Color.claudeSecondaryBackground)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Results
                        HStack {
                            Text("\(filteredPlants.count) RESULTS")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Plant List
                        VStack(spacing: 12) {
                            ForEach(filteredPlants) { plant in
                                ToxicityPlantRow(plant: plant)
                            }
                        }
                        .padding(.horizontal, 20)
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
            ToxicityCheckerInfoSheet()
        }
    }
}

// MARK: - Stat Card

struct ToxicityStatCard: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text("\(count)")
                .font(.claudeSerif(size: 28, weight: .bold))
                .foregroundColor(.claudePrimaryText)
            
            Text(label.uppercased())
                .font(.claudeSans(size: 10, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

// MARK: - Plant Row

struct ToxicityPlantRow: View {
    let plant: Plant
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .center, spacing: 14) {
                    // Safety Indicator
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(plant.toxicity.isPetSafe ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: plant.toxicity.isPetSafe ? "pawprint.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(plant.toxicity.isPetSafe ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plant.commonName)
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundColor(.claudePrimaryText)
                            .lineLimit(1)
                        
                        Text(plant.botanicalName)
                            .font(.claudeSans(size: 12))
                            .foregroundColor(.claudeSecondaryText)
                            .italic()
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Safety Badge
                    Text(plant.toxicity.isPetSafe ? "SAFE" : "TOXIC")
                        .font(.claudeSans(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(plant.toxicity.isPetSafe ? .green : .red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(plant.toxicity.isPetSafe ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.claudeBorder)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded Detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(plant.toxicity.isPetSafe ? .green : .red)
                        
                        Text(plant.toxicity.warning)
                            .font(.claudeSans(size: 14))
                            .foregroundColor(.claudePrimaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    
                    // Safety icons row
                    HStack(spacing: 20) {
                        SafetyIcon(animal: "🐶", label: "Dogs", isSafe: plant.toxicity.isPetSafe)
                        SafetyIcon(animal: "🐱", label: "Cats", isSafe: plant.toxicity.isPetSafe)
                        SafetyIcon(animal: "👶", label: "Children", isSafe: plant.toxicity.isPetSafe)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

struct SafetyIcon: View {
    let animal: String
    let label: String
    let isSafe: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isSafe ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(animal)
                    .font(.system(size: 20))
            }
            
            HStack(spacing: 2) {
                Image(systemName: isSafe ? "checkmark" : "xmark")
                    .font(.system(size: 8, weight: .bold))
                Text(label)
                    .font(.claudeSans(size: 10, weight: .medium))
            }
            .foregroundColor(isSafe ? .green : .red)
        }
    }
}

// MARK: - Info Sheet View
struct ToxicityCheckerInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Toxicity Checker Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Quickly verify whether a houseplant is safe to keep around pets and children, with detailed safety information for each species.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "checkmark.shield.fill", title: "Safety Status", text: "Every plant in your collection is classified as either pet-safe or toxic, based on ASPCA and veterinary databases.", color: .green)
                            
                            InfoRow(icon: "magnifyingglass", title: "Search & Filter", text: "Search by name or filter to show only safe or toxic plants. Perfect for planning a pet-friendly home.", color: .blue)
                            
                            InfoRow(icon: "pawprint.fill", title: "Detailed Warnings", text: "Tap any plant for specific toxicity details — which animals are affected and what symptoms to watch for.", color: .orange)
                            
                            InfoRow(icon: "exclamationmark.triangle.fill", title: "Emergency Advice", text: "If your pet ingests a toxic plant, contact your veterinarian or the ASPCA Poison Control Center immediately.", color: .red)
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
        ToxicityCheckerView()
    }
}
