import SwiftUI

struct MyJungleView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @Namespace private var filterNamespace
    @State private var isGridView = true
    @State private var sortOption: SortOption = .name
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var showStreakSheet = false
    @State private var activeToast: ActiveToast? = nil

    enum ActiveToast {
        case watered, fertilized, misted, rotated

        var message: String {
            switch self {
            case .watered:   return "All plants watered!"
            case .fertilized: return "All plants fertilized!"
            case .misted:    return "All plants misted!"
            case .rotated:   return "Rotation reminder set!"
            }
        }
        var icon: String {
            switch self {
            case .watered:   return "drop.fill"
            case .fertilized: return "leaf.circle.fill"
            case .misted:    return "humidity.fill"
            case .rotated:   return "arrow.trianglehead.2.clockwise.rotate.90"
            }
        }
        var color: Color {
            switch self {
            case .watered:   return .blue
            case .fertilized: return .green
            case .misted:    return Color(red: 0.1, green: 0.7, blue: 0.75)
            case .rotated:   return .orange
            }
        }
    }
    @State private var headerVisible = false
    @State private var dashboardVisible = false
    
    enum SortOption {
        case name, difficulty, lastWatered, health
        
        var label: String {
            switch self {
            case .name: return "Name"
            case .difficulty: return "Difficulty"
            case .lastWatered: return "Last Watered"
            case .health: return "Health"
            }
        }
    }
    
    enum FilterOption {
        case all, needsWatering, healthy, needsAttention

        var label: String {
            switch self {
            case .all: return "All Plants"
            case .needsWatering: return "Needs Watering"
            case .healthy: return "Healthy"
            case .needsAttention: return "Needs Attention"
            }
        }

        var icon: String {
            switch self {
            case .all: return "leaf.fill"
            case .needsWatering: return "drop.fill"
            case .healthy: return "heart.fill"
            case .needsAttention: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var myPlants: [Plant] {
        guard let profile = dataLoader.userProfile else { return [] }
        let myPlantIds = profile.myJungle.map { $0.plantId }
        var plants = dataLoader.plants.filter { myPlantIds.contains($0.id) }
        
        // Apply search filter
        if !searchText.isEmpty {
            plants = plants.filter { plant in
                let nickname = dataLoader.myJungleLookup[plant.id]?.nickname
                return plant.commonName.localizedCaseInsensitiveContains(searchText) ||
                       plant.botanicalName.localizedCaseInsensitiveContains(searchText) ||
                       (nickname?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        plants = plants.filter { plant in
            guard let myPlant = dataLoader.myJungleLookup[plant.id] else { return false }
            
            switch filterOption {
            case .all:
                return true
            case .needsWatering:
                return dataLoader.needsWatering(myPlant: myPlant)
            case .healthy:
                return (myPlant.healthScore ?? 80) >= 70
            case .needsAttention:
                return (myPlant.healthScore ?? 80) < 70 || dataLoader.needsWatering(myPlant: myPlant)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .name:
            return plants.sorted { $0.commonName < $1.commonName }
        case .difficulty:
            let difficultyOrder = ["very easy": 0, "easy": 1, "medium": 2, "hard": 3, "hard (indoors)": 3]
            return plants.sorted {
                (difficultyOrder[$0.careGuide.difficulty.lowercased()] ?? 4) <
                (difficultyOrder[$1.careGuide.difficulty.lowercased()] ?? 4)
            }
        case .lastWatered:
            return plants.sorted { plant1, plant2 in
                guard let myPlant1 = dataLoader.myJungleLookup[plant1.id],
                      let myPlant2 = dataLoader.myJungleLookup[plant2.id],
                      let next1 = myPlant1.nextWateringDate,
                      let next2 = myPlant2.nextWateringDate else { return false }
                // Lexicographical comparison for ISO8601 strings is sufficient for sorting
                return next1 < next2
            }
        case .health:
            return plants.sorted { plant1, plant2 in
                let health1 = dataLoader.myJungleLookup[plant1.id]?.healthScore ?? 80
                let health2 = dataLoader.myJungleLookup[plant2.id]?.healthScore ?? 80
                return health1 > health2
            }
        }
    }
    
    var plantsNeedingWater: Int {
        guard let profile = dataLoader.userProfile else { return 0 }
        return profile.myJungle.filter { dataLoader.needsWatering(myPlant: $0) }.count
    }
    
    var averageHealth: Int {
        guard let profile = dataLoader.userProfile, !profile.myJungle.isEmpty else { return 0 }
        let total = profile.myJungle.reduce(0) { $0 + ($1.healthScore ?? 80) }
        return total / profile.myJungle.count
    }
    
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤️"
        case 17..<22: return "Good Evening 🌙"
        default: return "Hello Night Owl 🦉"
        }
    }

    var healthStatus: String {
        let health = averageHealth
        if health >= 80 { return "Thriving" }
        else if health >= 60 { return "Good" }
        else if health >= 40 { return "Fair" }
        else { return "Needs Care" }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(greetingMessage)
                                    .font(.claudeSans(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.claudeSecondaryText)
                                    .opacity(headerVisible ? 1 : 0)
                                    .offset(y: headerVisible ? 0 : -8)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: headerVisible)

                                Text("My Jungle")
                                    .font(.claudeSerif(size: 34, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                    .opacity(headerVisible ? 1 : 0)
                                    .offset(y: headerVisible ? 0 : -10)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: headerVisible)
                            }

                            Spacer()

                            HStack(spacing: 12) {
                                Button(action: { showStreakSheet = true }) {
                                    if let streak = dataLoader.userProfile?.currentStreak {
                                        StreakBadge(streakCount: streak)
                                    } else {
                                        StreakBadge(streakCount: 0)
                                    }
                                }
                                .buttonStyle(.plain)
                                .opacity(headerVisible ? 1 : 0)
                                .offset(y: headerVisible ? 0 : -8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: headerVisible)

                                Menu {
                                    Picker("Sort By", selection: $sortOption) {
                                        Text("Name").tag(SortOption.name)
                                        Text("Difficulty").tag(SortOption.difficulty)
                                        Text("Last Watered").tag(SortOption.lastWatered)
                                        Text("Health").tag(SortOption.health)
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.claudeAccent)
                                        .shadow(color: Color.claudeAccent.opacity(0.3), radius: 5, x: 0, y: 2)
                                }
                                .opacity(headerVisible ? 1 : 0)
                                .offset(y: headerVisible ? 0 : -8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.22), value: headerVisible)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .onAppear {
                            withAnimation { headerVisible = true }
                        }
                        
                        GeometryReader { geometry in
                            ScrollView {
                                VStack(spacing: 24) {
                                // Stats Dashboard
                                if dataLoader.userProfile != nil {
                                    VStack(alignment: .leading, spacing: 16) {
                                        JungleHubDashboard(
                                            totalPlants: myPlants.count,
                                            plantsToWater: plantsNeedingWater,
                                            averageHealth: averageHealth
                                        )
                                        .padding(.top, 8)
                                        .opacity(dashboardVisible ? 1 : 0)
                                        .offset(y: dashboardVisible ? 0 : 16)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.15), value: dashboardVisible)

                                        JungleInsightCard()
                                            .padding(.horizontal, 20)
                                            .opacity(dashboardVisible ? 1 : 0)
                                            .offset(y: dashboardVisible ? 0 : 12)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.25), value: dashboardVisible)
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .onAppear {
                                        withAnimation { dashboardVisible = true }
                                    }
                                }
                                
                                // Search Bar
                                HStack {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(.secondary)
                                        TextField("Search plants...", text: $searchText)
                                            .textFieldStyle(.plain)
                                        
                                        if !searchText.isEmpty {
                                            Button(action: {
                                                withAnimation {
                                                    searchText = ""
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.claudeSecondaryBackground)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.claudeBorder, lineWidth: 1))
                                }
                                .padding(.horizontal)
                                
                                // Filter Pills
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach([FilterOption.all, .needsWatering, .healthy, .needsAttention], id: \.label) { filter in
                                            let isSelected = filterOption == filter
                                            Button(action: {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                    filterOption = filter
                                                }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: filter.icon)
                                                        .font(.system(size: 11, weight: .bold))
                                                    Text(filter.label)
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .foregroundStyle(isSelected ? .white : Color.claudePrimaryText)
                                                .background {
                                                    ZStack {
                                                        if isSelected {
                                                            Capsule()
                                                                .fill(Color.claudeAccent)
                                                                .matchedGeometryEffect(id: "filter_pill_bg", in: filterNamespace)
                                                                .shadow(color: Color.claudeAccent.opacity(0.35), radius: 6, x: 0, y: 3)
                                                        } else {
                                                            Capsule()
                                                                .fill(Color.claudeSecondaryBackground)
                                                                .overlay(Capsule().stroke(Color.claudeBorder, lineWidth: 1))
                                                        }
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 2)
                                }
                                
                                // Quick Actions
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        // Water All — filled primary action
                                        Button(action: {
                                            HapticManager.shared.playImpact(style: .medium)
                                            dataLoader.waterAllPlants()
                                            showToast(.watered)
                                        }) {
                                            HStack(spacing: 7) {
                                                Image(systemName: "drop.fill")
                                                    .font(.system(size: 13, weight: .bold))
                                                Text("Water All")
                                                    .font(.claudeSans(size: 14, weight: .bold))
                                            }
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 13)
                                            .background(
                                                LinearGradient(colors: [.blue, Color(red: 0.15, green: 0.5, blue: 0.95)],
                                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                            .shadow(color: .blue.opacity(0.32), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(ScaleButtonStyle())

                                        QuickActionButton(title: "Fertilize", icon: "leaf.circle.fill", color: .green) {
                                            HapticManager.shared.playImpact(style: .light)
                                            dataLoader.fertilizeAllPlants()
                                            showToast(.fertilized)
                                        }

                                        QuickActionButton(title: "Mist All", icon: "humidity.fill", color: Color(red: 0.1, green: 0.7, blue: 0.75)) {
                                            HapticManager.shared.playImpact(style: .light)
                                            dataLoader.mistAllPlants()
                                            showToast(.misted)
                                        }

                                        QuickActionButton(title: "Rotate", icon: "arrow.trianglehead.2.clockwise.rotate.90", color: .orange) {
                                            HapticManager.shared.playImpact(style: .light)
                                            showToast(.rotated)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // View Toggle Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Your Collection")
                                            .font(.claudeSerif(size: 20, weight: .bold))
                                            .foregroundStyle(Color.claudePrimaryText)
                                        if !myPlants.isEmpty {
                                            Text("\(myPlants.count) plant\(myPlants.count == 1 ? "" : "s")")
                                                .font(.claudeSans(size: 12, weight: .medium))
                                                .foregroundStyle(Color.claudeSecondaryText)
                                        }
                                    }

                                    Spacer()

                                    HStack(spacing: 2) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                isGridView = true
                                            }
                                        }) {
                                            Image(systemName: "square.grid.2x2.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 7)
                                                .foregroundStyle(isGridView ? .white : Color.claudeSecondaryText)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(isGridView ? Color.claudeAccent : Color.clear)
                                                )
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                isGridView = false
                                            }
                                        }) {
                                            Image(systemName: "list.bullet")
                                                .font(.system(size: 14, weight: .semibold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 7)
                                                .foregroundStyle(!isGridView ? .white : Color.claudeSecondaryText)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(!isGridView ? Color.claudeAccent : Color.clear)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.claudeSecondaryBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.claudeBorder, lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Plants List/Grid
                                if myPlants.isEmpty {
                                    EmptyJungleView(isSearching: !searchText.isEmpty)
                                        .padding(.top, 40)
                                } else {
                                    VStack(alignment: .leading, spacing: 24) {
                                        // Pending Tasks Section
                                        if filterOption == .all && searchText.isEmpty {
                                            let pendingPlants = myPlants.filter { plant in
                                                guard let myPlant = dataLoader.myJungleLookup[plant.id] else { return false }
                                                return dataLoader.needsWatering(myPlant: myPlant) || (myPlant.healthScore ?? 80) < 60
                                            }
                                            
                                            if !pendingPlants.isEmpty {
                                                VStack(alignment: .leading, spacing: 12) {
                                                    HStack(spacing: 8) {
                                                        Text("Needs Attention")
                                                            .font(.claudeSerif(size: 18, weight: .bold))
                                                            .foregroundStyle(Color.claudePrimaryText)

                                                        Text("\(pendingPlants.count)")
                                                            .font(.claudeSans(size: 11, weight: .bold))
                                                            .foregroundStyle(.white)
                                                            .padding(.horizontal, 7)
                                                            .padding(.vertical, 3)
                                                            .background(Capsule().fill(Color.red))

                                                        Spacer()
                                                    }
                                                    .padding(.horizontal)
                                                    
                                                    ScrollView(.horizontal, showsIndicators: false) {
                                                        HStack(spacing: 16) {
                                                            let cardWidth = (geometry.size.width - 48) / 2
                                                            ForEach(pendingPlants) { plant in
                                                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                                    EnhancedPlantCard(plant: plant)
                                                                        .frame(width: cardWidth)
                                                                }
                                                                .buttonStyle(ScaleButtonStyle())
                                                            }
                                                        }
                                                        .padding(.horizontal)
                                                    }
                                                }
                                                .transition(.opacity.combined(with: .move(edge: .top)))
                                            }
                                        }
                                        Group {
                                            if isGridView {
                                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                                                    ForEach(myPlants) { plant in
                                                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                            EnhancedPlantCard(plant: plant)
                                                        }
                                                        .buttonStyle(ScaleButtonStyle())
                                                    }
                                                }
                                                .padding(.horizontal)
                                            } else {
                                                LazyVStack(spacing: 12) {
                                                    ForEach(myPlants) { plant in
                                                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                            EnhancedJungleListRow(plant: plant)
                                                        }
                                                        .buttonStyle(ScaleButtonStyle())
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                                    }
                                }
                                }
                                .frame(width: geometry.size.width)
                                .padding(.vertical)
                            }
                        }
                    }
                
                if let toast = activeToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: toast.icon)
                                .font(.system(size: 15, weight: .bold))
                            Text(toast.message)
                                .font(.claudeSans(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [toast.color, toast.color.opacity(0.78)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: toast.color.opacity(0.4), radius: 16, x: 0, y: 6)
                        )
                        .padding(.bottom, 24)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.visible, for: .tabBar)
            .onAppear {
                dataLoader.checkAndUpdateStreak()
            }
            .sheet(isPresented: $showStreakSheet) {
                StreakView()
                    .environmentObject(dataLoader)
            }
        }
    }

    private func showToast(_ toast: ActiveToast) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            activeToast = toast
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activeToast = nil
            }
        }
    }
}

// Helper Views
struct JungleHubDashboard: View {
    let totalPlants: Int
    let plantsToWater: Int
    let averageHealth: Int

    @State private var animateRing = false
    @State private var tilesVisible = false

    var ringColor: LinearGradient {
        LinearGradient(
            colors: averageHealth >= 80 ? [Color.green, Color.mint] :
                    averageHealth >= 60 ? [Color.yellow, Color.orange] :
                                         [Color.red, Color.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            // Overall Health Ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.13), lineWidth: 9)

                    Circle()
                        .trim(from: 0, to: animateRing ? CGFloat(averageHealth) / 100.0 : 0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.4, dampingFraction: 0.75).delay(0.2), value: animateRing)

                    VStack(spacing: 1) {
                        Text("\(averageHealth)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.claudePrimaryText)
                            .contentTransition(.numericText())
                        Text("Health")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }
                .frame(width: 76, height: 76)

                Text(averageHealth >= 80 ? "Thriving" : averageHealth >= 60 ? "Good" : "Needs Care")
                    .font(.claudeSans(size: 11, weight: .semibold))
                    .foregroundStyle(averageHealth >= 80 ? Color.green : averageHealth >= 60 ? Color.orange : Color.red)
                    .opacity(animateRing ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.9), value: animateRing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.claudeBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            .onAppear { animateRing = true }

            VStack(spacing: 10) {
                // Total Plants
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Plants")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("\(totalPlants)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.claudePrimaryText)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.green)
                        .font(.system(size: 18))
                        .padding(8)
                        .background(Color.green.opacity(0.13))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.claudeSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.claudeBorder, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                .opacity(tilesVisible ? 1 : 0)
                .offset(x: tilesVisible ? 0 : 16)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: tilesVisible)

                // Needs Water
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To Water")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("\(plantsToWater)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(plantsToWater > 0 ? Color.blue : Color.claudePrimaryText)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Image(systemName: plantsToWater > 0 ? "drop.fill" : "checkmark.circle.fill")
                        .foregroundStyle(plantsToWater > 0 ? Color.blue : Color.green)
                        .font(.system(size: 18))
                        .padding(8)
                        .background((plantsToWater > 0 ? Color.blue : Color.green).opacity(0.13))
                        .clipShape(Circle())
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.claudeSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.claudeBorder, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                .opacity(tilesVisible ? 1 : 0)
                .offset(x: tilesVisible ? 0 : 16)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: tilesVisible)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation { tilesVisible = true }
        }
    }
}

struct JungleInsightCard: View {
    @State private var isAnimating = false
    
    let insights = [
        "Monstera Deliciosa literally means 'delicious monster', referring to its massive leaves and edible fruit in the wild.",
        "In the wild, Golden Pothos can grow leaves up to 3 feet wide when climbing tall trees in French Polynesia.",
        "Snake Plants are native to rocky, dry habitats in Africa, which is why they thrive on neglect and drought.",
        "Calatheas grow on the forest floor of the Amazon where they get minimal light, making them perfect for low-light corners.",
        "Epiphytes like Air Plants don't grow in soil; they attach themselves to branches and rocks in the wild.",
        "The ZZ Plant developed bulky rhizomes to store water during extreme droughts in its native Eastern Africa.",
        "Fiddle Leaf Figs are native to West Africa where they grow as massive canopy trees up to 50 feet tall.",
        "Spider Plants originate from tropical and southern Africa and reproduce by sending runners across the forest floor.",
        "Peace Lilies naturally grow along streams and waterfalls in Central America, hence their love for high humidity.",
        "Succulents like Echeveria grow natively in high-altitude, rocky terrains in Mexico and South America.",
        "The Rubber Tree (Ficus elastica) can grow over 100 feet tall in the wild rainforests of Southeast Asia.",
        "Venus Flytraps natively grow in boggy, nutrient-poor soil in North and South Carolina, relying on insects for nitrogen.",
        "Orchids are some of the most evolved plants, often mimicking the exact shape of specific insects to attract pollinators.",
        "Aloe Vera has been used for centuries, originating in the Arabian Peninsula where its thick leaves store vital water.",
        "Ferns are incredibly ancient, having thrived on Earth's forest floors for over 360 million years—long before dinosaurs.",
        "The Jade Plant grows in the rocky, dry hillsides of South Africa where it can easily survive for decades.",
        "String of Pearls relies on unique transparent 'window' slits in its bead-like leaves to let light in while minimizing water loss in the hot Namibian desert.",
        "Alocasias are natively from tropical Asia where they use their giant 'Elephant Ear' leaves to capture passing rainfall.",
        "The Cast Iron Plant earned its name because it survived the extreme neglect, toxic fumes, and darkness of Victorian-era London homes.",
        "English Ivy originally evolved to climb sheer cliff faces and giant trees across Europe using tiny, naturally glue-secreting rootlets.",
        "Philodendrons change leaf shapes dramatically; their juvenile leaves near the forest floor look completely different from their massive mature canopy leaves.",
        "Bromeliads naturally form central 'tanks' in their leaves that catch rainwater, literally creating tiny pools for wild tree frogs to live in.",
        "Lithops are succulents that perfectly camouflage themselves as pebbles in the hot deserts of southern Africa to hide from thirsty animals.",
        "Anthuriums in the wild are natural climbers that drop incredibly long aerial roots straight down from the rainforest canopy just to reach the soil below.",
        "The beloved Chinese Money Plant (Pilea) natively grows alone clinging to shady, damp rocks in the mountainous Yunnan province of China.",
        "The deeply colored leaves of Rex Begonias evolved specifically to absorb the exact spectrums of light available on a darkened rainforest floor.",
        "Venus Flytraps can actually count! They wait for precisely two distinct touches on their sensory hairs within 20 seconds before springing their trap.",
        "The Dragon Tree (Dracaena) grows natively in Madagascar and can live for hundreds of years, slowly forming striking umbrella-like canopies.",
        "Peperomias originated in the high cloud forests of the Andes, where their thick leaves soak up dense moisture right out of the misty air.",
        "The beautiful Bird of Paradise evolved its heavy, sturdy floral perch specifically to support the weight of African sunbirds that pollinate it."
    ]
    
    var hourlyInsight: String {
        let calendar = Calendar.current
        let date = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let hourOfDay = calendar.component(.hour, from: date)
        
        let totalHours = (dayOfYear * 24) + hourOfDay
        return insights[totalHours % insights.count]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.claudeAccent.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.claudeAccent)
                    .symbolEffect(.pulse, options: .repeating, value: isAnimating)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Jungle Insight")
                    .font(.claudeSans(size: 12, weight: .bold))
                    .foregroundStyle(Color.claudeAccent)
                    .textCase(.uppercase)
                
                Text(hourlyInsight)
                    .font(.claudeSerif(size: 14))
                    .foregroundStyle(Color.claudePrimaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.claudeSecondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(colors: [Color.claudeAccent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .onAppear { isAnimating = true }
    }
}

struct EmptyJungleView: View {
    let isSearching: Bool
    @Environment(TabSelection.self) var tabSelection
    @State private var floating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.claudeAccent.opacity(0.07))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.claudeAccent.opacity(0.04))
                    .frame(width: 150, height: 150)
                    .scaleEffect(floating ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)

                Image(systemName: isSearching ? "doc.text.magnifyingglass" : "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.claudeAccent.opacity(0.45))
                    .offset(y: floating ? -5 : 0)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
            }
            .onAppear { floating = true }

            VStack(spacing: 8) {
                Text(isSearching ? "No matches found" : "Your Jungle is Quiet")
                    .font(.claudeSerif(size: 22, weight: .bold))

                Text(isSearching ? "Try adjusting your search terms or filters." : "Every great garden starts with a single leaf. Add your first plant to begin.")
                    .font(.claudeSans(size: 15))
                    .foregroundStyle(Color.claudeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if !isSearching {
                Button(action: { tabSelection.selectedTab = 0 }) {
                    Text("Discover Plants")
                        .font(.claudeSans(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.claudeAccent)
                        .clipShape(Capsule())
                        .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.claudeSans(size: 15, weight: .bold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.claudeSecondaryBackground)
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct JungleListRow: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            ZStack {
                if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                    Image(String(imageName))
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.green.opacity(0.2)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(.headline)
                Text(plant.botanicalName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StreakBadge: View {
    let streakCount: Int
    @State private var glowing = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streakCount > 0 ? Color.orange : Color.gray)
                .symbolEffect(.pulse, options: .repeating, isActive: streakCount > 3)
            Text("\(streakCount)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(streakCount > 0 ? Color.orange : Color.gray)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.claudeSecondaryBackground)
                .shadow(
                    color: streakCount > 0 ? Color.orange.opacity(glowing ? 0.45 : 0.15) : .clear,
                    radius: glowing ? 10 : 4,
                    x: 0, y: 0
                )
        )
        .overlay(
            Capsule()
                .stroke(streakCount > 0 ? Color.orange.opacity(0.25) : Color.claudeBorder, lineWidth: 1)
        )
        .onAppear {
            if streakCount > 0 {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
        }
    }
}

#Preview {
    let dataLoader = DataLoader()
    MyJungleView()
        .environmentObject(dataLoader)
        .environment(TabSelection())
}
