import SwiftUI
import MapKit

struct PlantListView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @Namespace private var categoryNamespace
    @State private var isShowingNotifications = false
    @FocusState private var searchFieldFocused: Bool
    
    var filteredPlants: [Plant] {
        var plants = dataLoader.plants
        
        if let category = selectedCategory {
            plants = plants.filter { $0.categoryId == category }
        }
        
        if !searchText.isEmpty {
            plants = plants.filter { plant in
                plant.commonName.localizedCaseInsensitiveContains(searchText) ||
                plant.botanicalName.localizedCaseInsensitiveContains(searchText) ||
                plant.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return plants
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground
                    .ignoresSafeArea()
                
                if let errorMessage = dataLoader.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        Text("Data Load Error")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Header Section
                        ClaudeHeader(
                            title: "Discover",
                            subtitle: "Find your next houseplant",
                            location: dataLoader.isProfileComplete ? dataLoader.userProfile?.locationSettings.city : nil,
                            trailingActions: AnyView(
                                Button(action: {
                                    isShowingNotifications = true
                                }) {
                                    Image(systemName: "bell.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                        .padding(10)
                                        .background(Circle().fill(Color(UIColor.secondarySystemGroupedBackground)))
                                        .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
                                        .overlay(alignment: .topTrailing) {
                                            if dataLoader.notifications.contains(where: { !$0.isRead }) {
                                                Circle()
                                                    .fill(.red)
                                                    .frame(width: 10, height: 10)
                                                    .offset(x: -2, y: 2)
                                                    .shadow(radius: 2)
                                            }
                                        }
                                }
                                .buttonStyle(NotificationButtonStyle())
                            )
                        )
                        
                        // Premium Search Bar
                        DiscoverSearchBar(
                            searchText: $searchText,
                            isSearchFocused: $isSearchFocused,
                            searchFieldFocused: $searchFieldFocused
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        
                        GeometryReader { geometry in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 24) {
                                // Recommended Section
                                if searchText.isEmpty, let profile = dataLoader.userProfile {
                                    let recommendedPlants = dataLoader.plants.filter { $0.careGuide.difficulty == profile.preferences.difficultyLevel }
                                    if !recommendedPlants.isEmpty {
                                        VStack(alignment: .leading, spacing: 16) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Recommended for You")
                                                        .font(.claudeSerif(size: 24, weight: .bold))
                                                        .foregroundStyle(Color.claudePrimaryText)
                                                    Text("Based on your \(profile.preferences.difficultyLevel.lowercased()) level")
                                                        .font(.claudeSans(size: 14))
                                                        .foregroundStyle(Color.claudeSecondaryText)
                                                }
                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 16) {
                                                    ForEach(recommendedPlants.prefix(5)) { plant in
                                                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                            ModernPlantCard(plant: plant, isFeatured: true)
                                                                .frame(width: 220)
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                }
                                
                                // Category Filter
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ModernCategoryPill(title: "All", icon: "leaf", isSelected: selectedCategory == nil, namespace: categoryNamespace) {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                selectedCategory = nil
                                            }
                                        }
                                        
                                        ForEach(dataLoader.categories) { category in
                                            ModernCategoryPill(title: category.name, icon: category.icon, isSelected: selectedCategory == category.id, namespace: categoryNamespace) {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                    selectedCategory = category.id
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                                
                                // Explore All Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text(searchText.isEmpty ? "Explore All Plants" : "Search Results")
                                            .font(.claudeSerif(size: 24, weight: .bold))
                                            .foregroundStyle(Color.claudePrimaryText)
                                        Spacer()
                                        Text("\(filteredPlants.count)")
                                            .font(.caption)
                                            .foregroundStyle(Color.claudeSecondaryText)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.claudeAccent.opacity(0.15)))
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    if filteredPlants.isEmpty {
                                        VStack(spacing: 20) {
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.green.opacity(0.2))
                                            
                                            VStack(spacing: 8) {
                                                Text("No plants found")
                                                    .font(.headline)
                                                Text("Try a different search term or category")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                    } else {
                                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                                            ForEach(filteredPlants) { plant in
                                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                    ModernPlantCard(plant: plant, isFeatured: false)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.bottom, 20)
                                }
                                .frame(width: geometry.size.width, alignment: .leading)
                                .padding(.top, 10)
                            }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.visible, for: .tabBar)
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationCenterView()
                .environmentObject(dataLoader)
        }
    }
}

// MARK: - Premium Discover Search Bar
struct DiscoverSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool
    var searchFieldFocused: FocusState<Bool>.Binding
    
    @State private var animateGlow = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 12) {
                // Magnifying glass icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        isSearchFocused
                        ? Color.claudeAccent
                        : Color.claudeSecondaryText.opacity(0.6)
                    )
                    .scaleEffect(isSearchFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFocused)
                
                // Text field
                TextField("Search plants, species, care tips...", text: $searchText)
                    .font(.claudeSans(size: 16))
                    .foregroundStyle(Color.claudePrimaryText)
                    .focused(searchFieldFocused)
                    .submitLabel(.search)
                    .tint(Color.claudeAccent)
                    .onChange(of: searchFieldFocused.wrappedValue) { _, newValue in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isSearchFocused = newValue
                        }
                    }
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.claudeSecondaryText.opacity(0.5))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.claudeSecondaryBackground)
                    
                    // Focused glassmorphic overlay
                    if isSearchFocused {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSearchFocused
                        ? Color.claudeAccent.opacity(0.5)
                        : Color.claudeBorder,
                        lineWidth: isSearchFocused ? 1.5 : 1
                    )
            }
            .shadow(
                color: isSearchFocused
                    ? Color.claudeAccent.opacity(0.1)
                    : Color.black.opacity(0.03),
                radius: isSearchFocused ? 12 : 6,
                x: 0,
                y: isSearchFocused ? 6 : 3
            )
            
            // Cancel button
            if isSearchFocused {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        searchText = ""
                        searchFieldFocused.wrappedValue = false
                        isSearchFocused = false
                    }
                }) {
                    Text("Cancel")
                        .font(.claudeSans(size: 15, weight: .semibold))
                        .foregroundStyle(Color.claudeAccent)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: searchText.isEmpty)
    }
}

// Modern Plant Card
struct ModernPlantCard: View {
    let plant: Plant
    let isFeatured: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                GeometryReader { geometry in
                    Group {
                        if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Color.green.opacity(0.1)
                                        .overlay(Image(systemName: "photo").foregroundStyle(.green.opacity(0.3)))
                                case .empty:
                                    Rectangle().fill(Color.gray.opacity(0.1)).overlay(ProgressView())
                                @unknown default: EmptyView()
                                }
                            }
                        } else {
                            let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                            Image(String(imageName))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(height: isFeatured ? 200 : 160)
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.commonName)
                    .font(.claudeSerif(size: isFeatured ? 20 : 17, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(Color.claudePrimaryText)
                
                Text(plant.botanicalName)
                    .font(.claudeSans(size: 13))
                    .italic()
                    .foregroundStyle(Color.claudeSecondaryText)
                    .lineLimit(1)
                
                DifficultyBadge(difficulty: plant.careGuide.difficulty)
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.claudeSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}

// Modern Category Pill
struct ModernCategoryPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    if icon.count == 1 {
                        Text(icon).font(.caption)
                    } else {
                        Image(systemName: icon).font(.caption)
                    }
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.claudeAccent)
                        .matchedGeometryEffect(id: "pill_bg", in: namespace)
                } else {
                    Capsule()
                        .fill(Color.claudeSecondaryBackground)
                        .overlay(Capsule().stroke(Color.claudeBorder, lineWidth: 1))
                }
            }
            .foregroundStyle(isSelected ? .white : Color.claudePrimaryText)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

// Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: String
    
    var color: Color {
        switch difficulty.lowercased() {
        case "very easy": return Color.green
        case "easy": return Color.mint
        case "medium": return Color.orange
        case "hard", "hard (indoors)": return Color.red
        default: return Color.claudeAccent
        }
    }
    
    var icon: String {
        switch difficulty.lowercased() {
        case "very easy": return "sparkles"
        case "easy": return "leaf.fill"
        case "hard", "hard (indoors)": return "exclamationmark.triangle.fill"
        default: return "gauge.medium"
        }
    }
    
    var body: some View {
        ClaudeBadge(text: difficulty, icon: icon, color: color)
    }
}


