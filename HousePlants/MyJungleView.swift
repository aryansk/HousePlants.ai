import SwiftUI

struct MyJungleView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var filterNamespace
    @AppStorage("jungleGridView") private var isGridView = true
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

    private var hasCollection: Bool {
        !(dataLoader.userProfile?.myJungle.isEmpty ?? true)
    }

    private var usesGridLayout: Bool {
        isGridView && !dynamicTypeSize.isAccessibilitySize
    }
    
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
        let base: (String, String)
        switch hour {
        case 5..<12: base = ("Good Morning", "☀️")
        case 12..<17: base = ("Good Afternoon", "🌤️")
        case 17..<22: base = ("Good Evening", "🌙")
        default: base = ("Hello Night Owl", "🦉")
        }
        if let first = dataLoader.userProfile?.username
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first, !first.isEmpty {
            return "\(base.0), \(first) \(base.1)"
        }
        return "\(base.0) \(base.1)"
    }

    /// Plants that need care right now, independent of the active search/filter,
    /// so the Today's Care checklist always reflects reality.
    var careTasks: [Plant] {
        guard let profile = dataLoader.userProfile else { return [] }
        return profile.myJungle
            .filter { dataLoader.needsWatering(myPlant: $0) }
            .compactMap { dataLoader.plant(for: $0.plantId) }
            .sorted { $0.commonName < $1.commonName }
    }

    /// Search is only worth its screen space once the collection is big enough to lose things in.
    private var showsSearch: Bool {
        (dataLoader.userProfile?.myJungle.count ?? 0) > 5 || !searchText.isEmpty
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
                                .accessibilityLabel("Sort collection")
                                .accessibilityValue(sortOption.label)
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
                                VStack(spacing: 18) {
                                // Stats Dashboard
                                if hasCollection {
                                    VStack(alignment: .leading, spacing: 0) {
                                        JungleHubDashboard(
                                            totalPlants: myPlants.count,
                                            plantsToWater: plantsNeedingWater,
                                            averageHealth: averageHealth,
                                            onWaterTap: {
                                                HapticManager.shared.playSelection()
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                    filterOption = plantsNeedingWater > 0 ? .needsWatering : .all
                                                }
                                            }
                                        )
                                        .padding(.top, 8)
                                        .opacity(dashboardVisible ? 1 : 0)
                                        .offset(y: dashboardVisible ? 0 : 16)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.15), value: dashboardVisible)

                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .onAppear {
                                        withAnimation { dashboardVisible = true }
                                    }
                                }
                                
                                if hasCollection {
                                // Today's Care — one-tap checklist, or a small celebration when done
                                if searchText.isEmpty && filterOption == .all {
                                    if !careTasks.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                IndieCutLabel(text: "Today's care", color: IndieHousePalette.yellow)
                                                Spacer()
                                                Text("\(careTasks.count) task\(careTasks.count == 1 ? "" : "s")")
                                                    .font(.claudeSans(size: 12, weight: .bold))
                                                    .foregroundStyle(Color.claudeSecondaryText)
                                            }

                                            VStack(spacing: 0) {
                                                ForEach(Array(careTasks.prefix(4).enumerated()), id: \.element.id) { index, plant in
                                                    JungleTaskRow(plant: plant)
                                                    if index < min(careTasks.count, 4) - 1 {
                                                        Divider().overlay(IndieHousePalette.ink.opacity(0.15))
                                                    }
                                                }

                                                if careTasks.count > 4 {
                                                    Button(action: {
                                                        HapticManager.shared.playSelection()
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                            filterOption = .needsWatering
                                                        }
                                                    }) {
                                                        Text("Show all \(careTasks.count) thirsty plants")
                                                            .font(.claudeSans(size: 13, weight: .bold))
                                                            .foregroundStyle(Color.claudeAccent)
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.vertical, 12)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .indiePaperCard(
                                                fill: Color.claudeSecondaryBackground,
                                                border: IndieHousePalette.ink,
                                                shadow: IndieHousePalette.yellow,
                                                rotation: -0.3,
                                                cornerRadius: 2,
                                                shadowOffset: 4
                                            )
                                            .padding(.trailing, 4)
                                            .padding(.bottom, 4)
                                        }
                                        .padding(.horizontal, 20)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: careTasks.map(\.id))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    } else {
                                        HStack(spacing: 12) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.title2)
                                                .foregroundStyle(IndieHousePalette.green)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("All caught up")
                                                    .font(.claudeSerif(size: 17, weight: .bold))
                                                    .foregroundStyle(Color.claudePrimaryText)
                                                Text("Every plant is watered and happy. The jungle thanks you 🌿")
                                                    .font(.claudeSans(size: 12))
                                                    .foregroundStyle(Color.claudeSecondaryText)
                                            }
                                            Spacer()
                                        }
                                        .padding(14)
                                        .indiePaperCard(
                                            fill: Color.claudeSecondaryBackground,
                                            border: IndieHousePalette.ink,
                                            shadow: IndieHousePalette.green,
                                            rotation: -0.3,
                                            cornerRadius: 2,
                                            shadowOffset: 4
                                        )
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 4)
                                        .padding(.horizontal, 20)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                // Search Bar
                                if showsSearch {
                                HStack {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(.secondary)
                                        TextField("Search plants...", text: $searchText)
                                            .textFieldStyle(.plain)
                                            .submitLabel(.search)
                                            .accessibilityLabel("Search My Jungle")
                                        
                                        if !searchText.isEmpty {
                                            Button(action: {
                                                withAnimation {
                                                    searchText = ""
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .accessibilityLabel("Clear search")
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.claudeSecondaryBackground)
                                    .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(0.45), lineWidth: 1.3))
                                }
                                .padding(.horizontal)
                                }

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
                                                            Rectangle()
                                                                .fill(Color.claudeAccent)
                                                                .matchedGeometryEffect(id: "filter_pill_bg", in: filterNamespace)
                                                        } else {
                                                            Rectangle()
                                                                .fill(Color.claudeSecondaryBackground)
                                                        }
                                                    }
                                                }
                                                .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(isSelected ? 1 : 0.4), lineWidth: 1.3))
                                                .background(
                                                    IndieHousePalette.ink
                                                        .opacity(isSelected ? 1 : 0)
                                                        .offset(x: 3, y: 3)
                                                )
                                                .padding(.trailing, 3)
                                                .padding(.bottom, 3)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 2)
                                }
                                
                                // Keep one clear primary action; secondary care tasks live in a menu.
                                HStack(spacing: 10) {
                                    Button(action: {
                                        HapticManager.shared.playImpact(style: .medium)
                                        dataLoader.waterAllPlants()
                                        showToast(.watered)
                                    }) {
                                        Label("Water all", systemImage: "drop.fill")
                                            .font(.claudeSans(size: 14, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 13)
                                            .foregroundStyle(.white)
                                            .background(IndieHousePalette.blue)
                                            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                                            .background(IndieHousePalette.ink.offset(x: 3, y: 3))
                                            .padding(.trailing, 3)
                                            .padding(.bottom, 3)
                                    }
                                    .buttonStyle(BubblingButtonStyle())
                                    .disabled(plantsNeedingWater == 0)
                                    .opacity(plantsNeedingWater == 0 ? 0.55 : 1)
                                    .accessibilityHint(plantsNeedingWater == 0 ? "No plants need water" : "Marks every due plant as watered")

                                    Menu {
                                        Button("Fertilize all", systemImage: "leaf.circle.fill") {
                                            HapticManager.shared.playImpact(style: .light)
                                            dataLoader.fertilizeAllPlants()
                                            showToast(.fertilized)
                                        }
                                        Button("Mist all", systemImage: "humidity.fill") {
                                            HapticManager.shared.playImpact(style: .light)
                                            dataLoader.mistAllPlants()
                                            showToast(.misted)
                                        }
                                        Button("Set rotation reminder", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
                                            dataLoader.addNotification(title: "Rotate Your Plants", message: "Give each plant a quarter turn toward the light for even, balanced growth.", type: .tip)
                                            showToast(.rotated)
                                        }
                                    } label: {
                                        Label("Care", systemImage: "ellipsis")
                                            .font(.claudeSans(size: 14, weight: .bold))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 13)
                                            .foregroundStyle(Color.claudePrimaryText)
                                            .background(Color.claudeSecondaryBackground)
                                            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                                            .background(IndieHousePalette.ink.offset(x: 3, y: 3))
                                            .padding(.trailing, 3)
                                            .padding(.bottom, 3)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
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

                                    if !dynamicTypeSize.isAccessibilitySize {
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
                                                .background(Rectangle().fill(isGridView ? Color.claudeAccent : Color.clear))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Grid view")
                                        .accessibilityAddTraits(isGridView ? .isSelected : [])

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
                                                .background(Rectangle().fill(!isGridView ? Color.claudeAccent : Color.clear))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("List view")
                                        .accessibilityAddTraits(!isGridView ? .isSelected : [])
                                    }
                                    .padding(4)
                                    .background(
                                        Rectangle()
                                            .fill(Color.claudeSecondaryBackground)
                                            .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(0.45), lineWidth: 1.3))
                                    )
                                    }
                                }
                                .padding(.horizontal)
                                }
                                
                                // Plants List/Grid
                                if myPlants.isEmpty {
                                    EmptyJungleView(
                                        isSearching: hasCollection && (!searchText.isEmpty || filterOption != .all),
                                        clearFilters: hasCollection ? {
                                            withAnimation {
                                                searchText = ""
                                                filterOption = .all
                                            }
                                        } : nil
                                    )
                                        .padding(.top, 40)
                                } else {
                                    VStack(alignment: .leading, spacing: 24) {
                                        Group {
                                            if usesGridLayout {
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

                                        if filterOption == .all && searchText.isEmpty {
                                            JungleInsightCard()
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                }
                                .frame(width: geometry.size.width)
                                .padding(.top, 8)
                                .padding(.bottom, 108)
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
                        .background(toast.color)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.6))
                        .background(IndieHousePalette.ink.offset(x: 4, y: 4))
                        .rotationEffect(.degrees(-0.6))
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
