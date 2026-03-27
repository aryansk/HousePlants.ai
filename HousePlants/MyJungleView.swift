import SwiftUI

struct MyJungleView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @Namespace private var filterNamespace
    @State private var isGridView = true
    @State private var sortOption: SortOption = .name
    @State private var showWateringConfetti = false
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var isSelectionMode = false
    @State private var selectedPlantIds: Set<String> = []
    
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
    
    var healthStatus: String {
        let health = averageHealth
        if health >= 80 { return "Thriving" }
        else if health >= 60 { return "Good" }
        else if health >= 40 { return "Fair" }
        else { return "Needs Care" }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Dashboard
                        if dataLoader.userProfile != nil {
                            StatsDashboard(
                                totalPlants: myPlants.count,
                                plantsToWater: plantsNeedingWater,
                                jungleHealth: healthStatus
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
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
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach([FilterOption.all, .needsWatering, .healthy, .needsAttention], id: \.label) { filter in
                                    let isSelected = filterOption == filter
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            filterOption = filter
                                        }
                                    }) {
                                        Text(filter.label)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .background {
                                                ZStack {
                                                    if isSelected {
                                                        Capsule()
                                                            .fill(Color.green)
                                                            .matchedGeometryEffect(id: "filter_pill_bg", in: filterNamespace)
                                                    } else {
                                                        Capsule()
                                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                                    }
                                                }
                                            }
                                            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Quick Actions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(title: "Water All", icon: "drop.fill", color: .blue) {
                                    dataLoader.waterAllPlants()
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        showWateringConfetti = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation {
                                            showWateringConfetti = false
                                        }
                                    }
                                }
                                
                                QuickActionButton(title: isSelectionMode ? "Done" : "Select", icon: isSelectionMode ? "checkmark" : "checkmark.circle", color: .purple) {
                                    withAnimation(.spring()) {
                                        isSelectionMode.toggle()
                                        if !isSelectionMode {
                                            selectedPlantIds.removeAll()
                                        }
                                    }
                                }
                                
                                if isSelectionMode && !selectedPlantIds.isEmpty {
                                    QuickActionButton(title: "Remove (\(selectedPlantIds.count))", icon: "trash", color: .red) {
                                        withAnimation {
                                            dataLoader.removePlants(plantIds: Array(selectedPlantIds))
                                            selectedPlantIds.removeAll()
                                            isSelectionMode = false
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Main Content Header
                        HStack {
                            Text("Your Collection")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // View Toggle
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isGridView = true
                                    }
                                }) {
                                    Image(systemName: "square.grid.2x2.fill")
                                        .padding(8)
                                        .foregroundStyle(isGridView ? .green : .secondary)
                                        .background(isGridView ? Color(UIColor.secondarySystemGroupedBackground) : Color.clear)
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isGridView = false
                                    }
                                }) {
                                    Image(systemName: "list.bullet")
                                        .padding(8)
                                        .foregroundStyle(!isGridView ? .green : .secondary)
                                        .background(!isGridView ? Color(UIColor.secondarySystemGroupedBackground) : Color.clear)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        // Plants List/Grid
                        if myPlants.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "leaf")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.green.opacity(0.3))
                                Text(searchText.isEmpty ? "Your jungle is empty!" : "No plants found")
                                    .font(.headline)
                                Text(searchText.isEmpty ? "Start your collection by discovering new plants." : "Try a different search or filter")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                            .transition(.opacity)
                        } else {
                            Group {
                                if isGridView {
                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                                        ForEach(myPlants) { plant in
                                            if isSelectionMode {
                                                PlantSelectionCard(plant: plant, isSelected: selectedPlantIds.contains(plant.id)) {
                                                    if selectedPlantIds.contains(plant.id) {
                                                        selectedPlantIds.remove(plant.id)
                                                    } else {
                                                        selectedPlantIds.insert(plant.id)
                                                    }
                                                }
                                                .transition(.scale)
                                            } else {
                                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                    EnhancedPlantCard(plant: plant)
                                                }
                                                .buttonStyle(ScaleButtonStyle())
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(myPlants) { plant in
                                            if isSelectionMode {
                                                JungleListRowSelectable(plant: plant, isSelected: selectedPlantIds.contains(plant.id)) {
                                                    if selectedPlantIds.contains(plant.id) {
                                                        selectedPlantIds.remove(plant.id)
                                                    } else {
                                                        selectedPlantIds.insert(plant.id)
                                                    }
                                                }
                                                .transition(.move(edge: .leading))
                                            } else {
                                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                    EnhancedJungleListRow(plant: plant)
                                                }
                                                .buttonStyle(ScaleButtonStyle())
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                        }
                    }
                    .padding(.vertical)
                }
                
                if showWateringConfetti {
                    VStack {
                        Text("💧 Plants Watered! 💧")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(radius: 10)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationTitle("My Jungle")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            Text("Name").tag(SortOption.name)
                            Text("Difficulty").tag(SortOption.difficulty)
                            Text("Last Watered").tag(SortOption.lastWatered)
                            Text("Health").tag(SortOption.health)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
}

// Helper Views
struct StatsDashboard: View {
    let totalPlants: Int
    let plantsToWater: Int
    let jungleHealth: String
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total Plants", value: "\(totalPlants)", icon: "leaf.fill", color: .green, delay: 0.1)
            StatCard(title: "To Water", value: "\(plantsToWater)", icon: "drop.fill", color: .blue, delay: 0.2)
            StatCard(title: "Health", value: jungleHealth, icon: "heart.fill", color: .red, delay: 0.3)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var delay: Double = 0
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
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
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(20)
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
