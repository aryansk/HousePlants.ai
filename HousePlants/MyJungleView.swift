import SwiftUI

struct MyJungleView: View {
    @Environment(DataLoader.self) var dataLoader
    @Namespace private var filterNamespace
    @State private var isGridView = true
    @State private var sortOption: SortOption = .name
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var showStreakSheet = false
    @State private var activeSheet: JungleSheet? = nil
    @State private var activeToast: ActiveToast? = nil
    @State private var toastTask: Task<Void, Never>? = nil

    /// Single sheet driver for the whole collection, replacing a per-card `.sheet` pair.
    enum JungleSheet: Identifiable {
        case care(Plant)
        case insights(MyPlant)

        var id: String {
            switch self {
            case .care(let plant): return "care-\(plant.id)"
            case .insights(let myPlant): return "insights-\(myPlant.id)"
            }
        }
    }

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
        let myPlantIds = Set(profile.myJungle.map { $0.plantId })
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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                            dataLoader.addNotification(
                                                title: "Rotate Your Plants",
                                                message: "Give each plant a quarter turn toward the light for even, balanced growth.",
                                                type: .tip
                                            )
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
                                                                    EnhancedPlantCard(plant: plant,
                                                                                      onManage: { activeSheet = .care(plant) },
                                                                                      onInsights: { presentInsights(for: plant) })
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
                                                            EnhancedPlantCard(plant: plant,
                                                                              onManage: { activeSheet = .care(plant) },
                                                                              onInsights: { presentInsights(for: plant) })
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
                            .scrollDismissesKeyboard(.immediately)
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
                    .environment(dataLoader)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .care(let plant):
                    PlantCareSheet(plant: plant)
                        .environment(dataLoader)
                case .insights(let myPlant):
                    NavigationStack {
                        PlantInsightsView(myPlant: myPlant)
                    }
                    .environment(dataLoader)
                }
            }
        }
    }

    private func presentInsights(for plant: Plant) {
        if let myPlant = dataLoader.myJungleLookup[plant.id] {
            activeSheet = .insights(myPlant)
        }
    }

    private func showToast(_ toast: ActiveToast) {
        // Cancel any in-flight dismissal so a second toast within 2.4s isn't cut short by the
        // first one's timer.
        toastTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            activeToast = toast
        }
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activeToast = nil
            }
        }
    }

}

#Preview {
    let dataLoader = DataLoader()
    MyJungleView()
        .environment(dataLoader)
        .environment(TabSelection())
}
