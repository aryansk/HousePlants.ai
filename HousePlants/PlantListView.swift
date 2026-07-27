import SwiftUI

private enum CatalogSort: String, CaseIterable, Identifiable {
    case recommended
    case name
    case easiest
    case petSafe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recommended: return "Recommended"
        case .name: return "Name"
        case .easiest: return "Easiest first"
        case .petSafe: return "Pet-safe first"
        }
    }

    var icon: String {
        switch self {
        case .recommended: return "sparkles"
        case .name: return "textformat.abc"
        case .easiest: return "leaf.fill"
        case .petSafe: return "pawprint.fill"
        }
    }
}

private enum CatalogLayout: String, CaseIterable {
    case grid
    case list

    var icon: String { self == .grid ? "square.grid.2x2" : "rectangle.grid.1x2" }
    var title: String { self == .grid ? "Grid" : "List" }
}

struct PlantListView: View {
    @Environment(DataLoader.self) private var dataLoader
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedCategory: String?
    @State private var selectedDifficulty: String?
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var isSearchFocused = false
    @State private var petSafeOnly = false
    @State private var favoritesOnly = false
    @State private var sort: CatalogSort = .recommended
    @State private var isShowingFilters = false
    @State private var isShowingNotifications = false
    @FocusState private var searchFieldFocused: Bool
    @Namespace private var categoryNamespace
    @AppStorage("catalogLayout") private var catalogLayoutRaw = CatalogLayout.grid.rawValue

    private var catalogLayout: CatalogLayout {
        CatalogLayout(rawValue: catalogLayoutRaw) ?? .grid
    }

    private var usesListLayout: Bool {
        catalogLayout == .list || dynamicTypeSize.isAccessibilitySize
    }

    private var difficultyOptions: [String] {
        Array(Set(dataLoader.plants.map(\.careGuide.difficulty)))
            .sorted { difficultyRank($0) < difficultyRank($1) }
    }

    private var activeFilterCount: Int {
        [selectedCategory != nil, selectedDifficulty != nil, petSafeOnly, favoritesOnly]
            .filter { $0 }
            .count
    }

    private var hasActiveQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || activeFilterCount > 0
    }

    private var filteredPlants: [Plant] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var plants = dataLoader.plants.filter { plant in
            if let selectedCategory, plant.categoryId != selectedCategory { return false }
            if let selectedDifficulty, plant.careGuide.difficulty != selectedDifficulty { return false }
            if petSafeOnly && !plant.toxicity.isPetSafe { return false }
            if favoritesOnly && !dataLoader.isFavorite(plantId: plant.id) { return false }

            guard !query.isEmpty else { return true }
            return plant.commonName.localizedCaseInsensitiveContains(query)
                || plant.botanicalName.localizedCaseInsensitiveContains(query)
                || plant.description.localizedCaseInsensitiveContains(query)
                || plant.origin.region.localizedCaseInsensitiveContains(query)
                || plant.careGuide.light.localizedCaseInsensitiveContains(query)
                || plant.careGuide.water.localizedCaseInsensitiveContains(query)
        }

        plants.sort { lhs, rhs in
            switch sort {
            case .recommended:
                let lhsScore = recommendationScore(for: lhs)
                let rhsScore = recommendationScore(for: rhs)
                return lhsScore == rhsScore
                    ? lhs.commonName.localizedStandardCompare(rhs.commonName) == .orderedAscending
                    : lhsScore > rhsScore
            case .name:
                return lhs.commonName.localizedStandardCompare(rhs.commonName) == .orderedAscending
            case .easiest:
                let lhsRank = difficultyRank(lhs.careGuide.difficulty)
                let rhsRank = difficultyRank(rhs.careGuide.difficulty)
                return lhsRank == rhsRank
                    ? lhs.commonName.localizedStandardCompare(rhs.commonName) == .orderedAscending
                    : lhsRank < rhsRank
            case .petSafe:
                if lhs.toxicity.isPetSafe != rhs.toxicity.isPetSafe {
                    return lhs.toxicity.isPetSafe
                }
                return lhs.commonName.localizedStandardCompare(rhs.commonName) == .orderedAscending
            }
        }
        return plants
    }

    private var recommendations: [Plant] {
        dataLoader.plants
            .sorted {
                let lhsScore = recommendationScore(for: $0)
                let rhsScore = recommendationScore(for: $1)
                return lhsScore == rhsScore
                    ? $0.commonName.localizedStandardCompare($1.commonName) == .orderedAscending
                    : lhsScore > rhsScore
            }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()

                if let errorMessage = dataLoader.errorMessage {
                    CatalogErrorView(message: errorMessage)
                } else {
                    VStack(spacing: 0) {
                        header
                        searchAndFilter
                        catalogContent
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationCenterView()
                .environment(dataLoader)
        }
        .sheet(isPresented: $isShowingFilters) {
            CatalogFilterSheet(
                selectedDifficulty: $selectedDifficulty,
                petSafeOnly: $petSafeOnly,
                favoritesOnly: $favoritesOnly,
                sort: $sort,
                difficultyOptions: difficultyOptions,
                resultCount: filteredPlants.count,
                clearFilters: clearRefinements
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task(id: searchText) {
            if searchText.isEmpty {
                debouncedSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            debouncedSearchText = searchText
        }
    }

    private var header: some View {
        ClaudeHeader(
            title: "Discover",
            subtitle: "Find a plant that fits your life",
            location: dataLoader.isProfileComplete ? dataLoader.userProfile?.locationSettings.city : nil,
            trailingActions: AnyView(
                Button {
                    isShowingNotifications = true
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(IndieHousePalette.ink)
                        .frame(width: 44, height: 44)
                        .background(IndieHousePalette.yellow)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                        .background(IndieHousePalette.ink.offset(x: 3, y: 3))
                        .overlay(alignment: .topTrailing) {
                            if dataLoader.notifications.contains(where: { !$0.isRead }) {
                                Circle()
                                    .fill(IndieHousePalette.red)
                                    .frame(width: 11, height: 11)
                                    .overlay(Circle().stroke(Color.claudeSecondaryBackground, lineWidth: 2))
                                    .offset(x: 3, y: -3)
                            }
                        }
                }
                .buttonStyle(NotificationButtonStyle())
                .accessibilityLabel("Notifications")
                .accessibilityValue(
                    dataLoader.notifications.contains(where: { !$0.isRead })
                        ? "Unread notifications"
                        : "No unread notifications"
                )
            )
        )
    }

    private var searchAndFilter: some View {
        VStack(spacing: 12) {
            DiscoverSearchBar(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                searchFieldFocused: $searchFieldFocused,
                activeFilterCount: activeFilterCount,
                showFilters: { isShowingFilters = true }
            )

            if !isSearchFocused {
                HStack(spacing: 10) {
                    Menu {
                        Picker("Sort plants", selection: $sort) {
                            ForEach(CatalogSort.allCases) { option in
                                Label(option.title, systemImage: option.icon).tag(option)
                            }
                        }
                    } label: {
                        CatalogControlLabel(icon: "arrow.up.arrow.down", title: sort.title)
                    }

                    Spacer(minLength: 4)

                    Button {
                        withMotion(Motion.fade) {
                            let next: CatalogLayout = catalogLayout == .grid ? .list : .grid
                            catalogLayoutRaw = next.rawValue
                        }
                    } label: {
                        Image(systemName: catalogLayout.icon)
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 44, height: 36)
                            .background(Color.claudeSecondaryBackground)
                            .overlay(Rectangle().stroke(Color.claudeBorder, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.claudePrimaryText)
                    .accessibilityLabel("Switch to \(catalogLayout == .grid ? "list" : "grid") view")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var catalogContent: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if !hasActiveQuery {
                        recommendationsSection
                    }

                    categoriesSection
                    resultsSection(availableWidth: geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CatalogSectionHeader(
                eyebrow: "Picked for you",
                title: "Good matches",
                subtitle: recommendationSubtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            ModernPlantCard(plant: plant, isFeatured: true)
                                .frame(width: 224)
                        }
                        .buttonStyle(InteractiveCardButtonStyle())
                        .accessibilityIdentifier("catalog.card.featured.\(plant.id)")
                        .staggeredAppear(index: index, step: 0.06, cap: 4, animation: Motion.bouncy, offset: 10, tilt: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse by type")
                .font(.claudeSans(size: 13, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
                .padding(.horizontal, 20)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ModernCategoryPill(
                        title: "All",
                        icon: "leaf",
                        isSelected: selectedCategory == nil,
                        namespace: categoryNamespace
                    ) {
                        selectCategory(nil)
                    }
                    .staggeredAppear(index: 0, step: 0.04, cap: 6, animation: Motion.playful, offset: 0, tilt: 3)

                    ForEach(Array(dataLoader.categories.enumerated()), id: \.element.id) { index, category in
                        ModernCategoryPill(
                            title: category.name,
                            icon: category.icon,
                            isSelected: selectedCategory == category.id,
                            namespace: categoryNamespace
                        ) {
                            selectCategory(category.id)
                        }
                        // +1 so the hard-coded "All" pill reads as index 0 of the row.
                        .staggeredAppear(index: index + 1, step: 0.04, cap: 6, animation: Motion.playful, offset: 0, tilt: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func resultsSection(availableWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasActiveQuery ? "Matching plants" : "All plants")
                        .font(.claudeSerif(size: 25, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text(resultSummary)
                        .font(.claudeSans(size: 13, weight: .medium))
                        .foregroundStyle(Color.claudeSecondaryText)
                }

                Spacer()

                if activeFilterCount > 0 {
                    Button("Clear") { clearRefinements() }
                        .font(.claudeSans(size: 13, weight: .bold))
                        .foregroundStyle(Color.claudeAccent)
                        .buttonStyle(.plain)
                }

                Text("\(filteredPlants.count)")
                    .font(.claudeSans(size: 12, weight: .black))
                    .foregroundStyle(IndieHousePalette.ink)
                    .contentTransition(.numericText())
                    .popOnChange(of: filteredPlants.count)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(IndieHousePalette.pink)
                    .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1))
                    .accessibilityLabel("\(filteredPlants.count) results")
            }
            .padding(.horizontal, 20)

            if filteredPlants.isEmpty {
                CatalogEmptyView(clearAll: clearAll)
                    .padding(.horizontal, 20)
            } else if usesListLayout {
                LazyVStack(spacing: 14) {
                    ForEach(Array(filteredPlants.enumerated()), id: \.element.id) { index, plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            CatalogPlantRow(plant: plant)
                        }
                        .buttonStyle(InteractiveCardButtonStyle())
                        .accessibilityIdentifier("catalog.card.result.\(plant.id)")
                        .staggeredAppear(index: index, step: 0.03, cap: 8, offset: 12)
                    }
                }
                .padding(.horizontal, 20)
                .id(resultsIdentity)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    ForEach(Array(filteredPlants.enumerated()), id: \.element.id) { index, plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            ModernPlantCard(plant: plant, isFeatured: false)
                        }
                        .buttonStyle(InteractiveCardButtonStyle())
                        .accessibilityIdentifier("catalog.card.result.\(plant.id)")
                        .staggeredAppear(index: index, step: 0.03, cap: 8)
                    }
                }
                .padding(.horizontal, 20)
                .id(resultsIdentity)
            }
        }
    }

    /// Changing category, difficulty or layout replaces this identity, which resets every
    /// card's entrance state so the results visibly re-deal instead of mutating in place.
    /// Deliberately excludes the search text — re-dealing on every keystroke would be noise.
    private var resultsIdentity: String {
        "\(selectedCategory ?? "all")-\(selectedDifficulty ?? "any")-\(petSafeOnly)-\(favoritesOnly)-\(usesListLayout)"
    }

    private var recommendationSubtitle: String {
        guard let profile = dataLoader.userProfile else {
            return "Approachable plants to start exploring"
        }
        if profile.preferences.petSafeOnly {
            return "Prioritizing pet-safe, \(profile.preferences.difficultyLevel.lowercased())-care plants"
        }
        return "Matched to your \(profile.preferences.difficultyLevel.lowercased()) care preference"
    }

    private var resultSummary: String {
        var parts: [String] = []
        if let selectedCategory,
           let category = dataLoader.categories.first(where: { $0.id == selectedCategory }) {
            parts.append(category.name)
        }
        if let selectedDifficulty { parts.append(selectedDifficulty) }
        if petSafeOnly { parts.append("Pet safe") }
        if favoritesOnly { parts.append("Favorites") }
        if !searchText.isEmpty { parts.append("Search") }
        return parts.isEmpty ? "Browse the complete collection" : parts.joined(separator: " · ")
    }

    private func recommendationScore(for plant: Plant) -> Int {
        guard let preferences = dataLoader.userProfile?.preferences else {
            return max(0, 5 - difficultyRank(plant.careGuide.difficulty))
        }

        var score = 0
        if careLevel(plant.careGuide.difficulty, matchesExperience: preferences.difficultyLevel) {
            score += 6
        }
        if preferences.petSafeOnly {
            score += plant.toxicity.isPetSafe ? 5 : -10
        } else if plant.toxicity.isPetSafe {
            score += 1
        }
        score += max(0, 4 - difficultyRank(plant.careGuide.difficulty))
        if dataLoader.isFavorite(plantId: plant.id) { score += 2 }
        return score
    }

    private func careLevel(_ careLevel: String, matchesExperience experience: String) -> Bool {
        switch experience.lowercased() {
        case "beginner":
            return ["very easy", "easy"].contains(careLevel.lowercased())
        case "enthusiast", "intermediate":
            return ["medium", "moderate"].contains(careLevel.lowercased())
        case "botany pro", "expert", "advanced":
            return ["hard", "hard (indoors)"].contains(careLevel.lowercased())
        default:
            return careLevel.caseInsensitiveCompare(experience) == .orderedSame
        }
    }

    private func difficultyRank(_ difficulty: String) -> Int {
        switch difficulty.lowercased() {
        case "very easy": return 0
        case "easy": return 1
        case "medium", "moderate": return 2
        case "hard", "hard (indoors)": return 3
        default: return 4
        }
    }

    private func selectCategory(_ category: String?) {
        HapticManager.shared.playImpact(style: .light)
        withMotion(Motion.bouncy) {
            selectedCategory = category
        }
    }

    private func clearRefinements() {
        withMotion(Motion.fade) {
            selectedCategory = nil
            selectedDifficulty = nil
            petSafeOnly = false
            favoritesOnly = false
            sort = .recommended
        }
    }

    private func clearAll() {
        clearRefinements()
        searchText = ""
        debouncedSearchText = ""
        searchFieldFocused = false
    }
}

private struct CatalogSectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            IndieCutLabel(text: eyebrow, color: IndieHousePalette.green)
            Text(title)
                .font(.claudeSerif(size: 25, weight: .bold))
                .foregroundStyle(Color.claudePrimaryText)
            Text(subtitle)
                .font(.claudeSans(size: 14, weight: .medium))
                .foregroundStyle(Color.claudeSecondaryText)
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct CatalogControlLabel: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.claudeSans(size: 13, weight: .bold))
            .foregroundStyle(Color.claudePrimaryText)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.claudeSecondaryBackground)
            .overlay(Rectangle().stroke(Color.claudeBorder, lineWidth: 1.5))
    }
}

private struct CatalogErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t load the catalog", systemImage: "leaf.circle")
        } description: {
            Text(message)
        }
        .foregroundStyle(Color.claudePrimaryText)
        .padding(24)
    }
}

private struct CatalogEmptyView: View {
    let clearAll: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(IndieHousePalette.green)

            VStack(spacing: 6) {
                Text("No plants match")
                    .font(.claudeSerif(size: 22, weight: .bold))
                Text("Try broadening your search or clearing a filter.")
                    .font(.claudeSans(size: 14))
                    .foregroundStyle(Color.claudeSecondaryText)
                    .multilineTextAlignment(.center)
            }

            Button("Show all plants", action: clearAll)
                .font(.claudeSans(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background(Color.claudeAccent)
                .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                .buttonStyle(BubblingButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .indiePaperCard(shadow: IndieHousePalette.green, cornerRadius: 3, shadowOffset: 5)
        .padding(.trailing, 5)
        .padding(.bottom, 5)
    }
}

private struct CatalogFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDifficulty: String?
    @Binding var petSafeOnly: Bool
    @Binding var favoritesOnly: Bool
    @Binding var sort: CatalogSort
    let difficultyOptions: [String]
    let resultCount: Int
    let clearFilters: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Care level") {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        Text("Any difficulty").tag(nil as String?)
                        ForEach(difficultyOptions, id: \.self) { difficulty in
                            Text(difficulty).tag(difficulty as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Preferences") {
                    Toggle(isOn: $petSafeOnly) {
                        Label("Pet-safe plants only", systemImage: "pawprint.fill")
                    }
                    .tint(IndieHousePalette.green)

                    Toggle(isOn: $favoritesOnly) {
                        Label("Favorites only", systemImage: "heart.fill")
                    }
                    .tint(IndieHousePalette.red)
                }

                Section("Sort by") {
                    Picker("Sort", selection: $sort) {
                        ForEach(CatalogSort.allCases) { option in
                            Label(option.title, systemImage: option.icon).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Button("Clear all filters", role: .destructive, action: clearFilters)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.claudeBackground)
            .navigationTitle("Refine plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show \(resultCount)") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Search

struct DiscoverSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool
    var searchFieldFocused: FocusState<Bool>.Binding
    let activeFilterCount: Int
    let showFilters: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSearchFocused ? Color.claudeAccent : Color.claudeSecondaryText)
                    .accessibilityHidden(true)

                TextField("Name, species, care or origin", text: $searchText)
                    .font(.claudeSans(size: 16))
                    .foregroundStyle(Color.claudePrimaryText)
                    .focused(searchFieldFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(Color.claudeAccent)
                    .accessibilityLabel("Search plant catalog")
                    .onChange(of: searchFieldFocused.wrappedValue) { _, isFocused in
                        withMotion(Motion.snappy) {
                            isSearchFocused = isFocused
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.claudeSecondaryText)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.claudeSecondaryBackground)
            .overlay {
                Rectangle()
                    .stroke(isSearchFocused ? Color.claudeAccent : Color.claudeBorder, lineWidth: isSearchFocused ? 2 : 1.5)
            }
            .background(IndieHousePalette.ink.offset(x: 4, y: 4))

            if isSearchFocused {
                Button("Cancel") {
                    searchFieldFocused.wrappedValue = false
                    isSearchFocused = false
                }
                .font(.claudeSans(size: 14, weight: .bold))
                .foregroundStyle(Color.claudeAccent)
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                Button(action: showFilters) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(activeFilterCount > 0 ? .white : Color.claudePrimaryText)
                        .frame(width: 48, height: 48)
                        .background(activeFilterCount > 0 ? Color.claudeAccent : Color.claudeSecondaryBackground)
                        .overlay(Rectangle().stroke(Color.claudeBorder, lineWidth: 1.5))
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(IndieHousePalette.ink)
                                    .frame(width: 20, height: 20)
                                    .background(IndieHousePalette.yellow)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(IndieHousePalette.ink, lineWidth: 1))
                                    .offset(x: 6, y: -6)
                            }
                        }
                }
                .buttonStyle(BubblingButtonStyle())
                .accessibilityIdentifier("catalog.filters")
                .accessibilityLabel("Filter plants")
                .accessibilityValue(activeFilterCount == 0 ? "No active filters" : "\(activeFilterCount) active filters")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .motion(Motion.snappy, value: isSearchFocused)
    }
}

// MARK: - Cards

struct ModernPlantCard: View {
    let plant: Plant
    let isFeatured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                PlantImage(plant: plant)
                    .frame(maxWidth: .infinity)
                    .frame(height: isFeatured ? 176 : 142)
                    .clipped()

                PetSafetyMark(isSafe: plant.toxicity.isPetSafe, compact: true)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(plant.commonName)
                    .font(.claudeSerif(size: isFeatured ? 20 : 17, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.claudePrimaryText)

                Text(plant.botanicalName)
                    .font(.claudeSans(size: 12))
                    .italic()
                    .foregroundStyle(Color.claudeSecondaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(shortLightDescription(plant.careGuide.light), systemImage: "sun.max.fill")
                    Spacer(minLength: 2)
                    DifficultyBadge(difficulty: plant.careGuide.difficulty, compact: true)
                }
                .font(.claudeSans(size: 10, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
                .padding(.top, 2)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .indiePaperCard(
            shadow: isFeatured ? IndieHousePalette.green : IndieHousePalette.ink,
            rotation: isFeatured ? -0.6 : 0,
            cornerRadius: 2,
            shadowOffset: isFeatured ? 6 : 4
        )
        .padding(.trailing, isFeatured ? 6 : 4)
        .padding(.bottom, isFeatured ? 6 : 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.commonName), \(plant.botanicalName)")
        .accessibilityValue("\(plant.careGuide.difficulty) care, \(plant.toxicity.isPetSafe ? "pet safe" : "toxic to pets"), \(plant.careGuide.light)")
        .accessibilityHint("Opens plant details")
    }

    private func shortLightDescription(_ light: String) -> String {
        let lower = light.lowercased()
        if lower.contains("low") { return "Low light" }
        if lower.contains("direct") && !lower.contains("indirect") { return "Direct sun" }
        if lower.contains("bright") { return "Bright light" }
        if lower.contains("medium") { return "Medium light" }
        return "Flexible light"
    }
}

private struct CatalogPlantRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 14) {
            PlantImage(plant: plant, showsProgress: false)
                .frame(width: 104, height: 118)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    PetSafetyMark(isSafe: plant.toxicity.isPetSafe, compact: true)
                        .padding(6)
                }

            VStack(alignment: .leading, spacing: 7) {
                Text(plant.commonName)
                    .font(.claudeSerif(size: 19, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)
                    .lineLimit(2)

                Text(plant.botanicalName)
                    .font(.claudeSans(size: 12))
                    .italic()
                    .foregroundStyle(Color.claudeSecondaryText)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(plant.careGuide.difficulty, systemImage: "leaf.fill")
                    Label(waterSummary, systemImage: "drop.fill")
                }
                .font(.claudeSans(size: 11, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
                .lineLimit(1)

                Text(plant.careGuide.light)
                    .font(.claudeSans(size: 11))
                    .foregroundStyle(Color.claudeSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
                .accessibilityHidden(true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .indiePaperCard(cornerRadius: 2, shadowOffset: 4)
        .padding(.trailing, 4)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.commonName), \(plant.botanicalName)")
        .accessibilityValue("\(plant.careGuide.difficulty) care, \(plant.toxicity.isPetSafe ? "pet safe" : "toxic to pets")")
        .accessibilityHint("Opens plant details")
    }

    private var waterSummary: String {
        if let days = plant.careGuide.wateringFrequencyDays {
            return days == 1 ? "Daily" : "Every \(days)d"
        }
        return "Care guide"
    }
}

private struct PetSafetyMark: View {
    let isSafe: Bool
    var compact = false

    var body: some View {
        Group {
            if compact {
                Image(systemName: isSafe ? "pawprint.fill" : "exclamationmark.triangle.fill")
            } else {
                Label(
                    isSafe ? "Pet safe" : "Toxic",
                    systemImage: isSafe ? "pawprint.fill" : "exclamationmark.triangle.fill"
                )
            }
        }
            .font(.system(size: compact ? 10 : 11, weight: .black))
            .foregroundStyle(IndieHousePalette.ink)
            .frame(minWidth: compact ? 28 : nil, minHeight: 28)
            .padding(.horizontal, compact ? 0 : 8)
            .background(isSafe ? IndieHousePalette.green : IndieHousePalette.yellow)
            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1))
            .accessibilityLabel(isSafe ? "Pet safe" : "Toxic to pets")
    }
}

struct ModernCategoryPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let icon {
                    Group {
                        if icon.count == 1 {
                            Text(icon).font(.caption)
                        } else {
                            Image(systemName: icon).font(.caption)
                        }
                    }
                    // The glyph tips and swells on selection so the active pill has a
                    // hand-stuck-on feel rather than just a colour change.
                    .rotationEffect(.degrees(isSelected ? -8 : 0))
                    .scaleEffect(isSelected ? 1.15 : 1)
                }
                Text(title)
                    .font(.claudeSans(size: 13, weight: .bold))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 42)
            .background {
                if isSelected {
                    Rectangle()
                        .fill(IndieHousePalette.blue)
                        .matchedGeometryEffect(id: "catalog_category", in: namespace)
                } else {
                    Rectangle()
                        .fill(Color.claudeSecondaryBackground)
                        .overlay(Rectangle().stroke(Color.claudeBorder, lineWidth: 1.5))
                }
            }
            .foregroundStyle(isSelected ? .white : Color.claudePrimaryText)
            .motion(Motion.bouncy, value: isSelected)
        }
        .buttonStyle(PaperPressButtonStyle(shadowOffset: 3, haptic: false))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Filters the catalog by \(title)")
    }
}

struct DifficultyBadge: View {
    let difficulty: String
    var compact = false

    private var color: Color {
        switch difficulty.lowercased() {
        case "very easy", "easy": return IndieHousePalette.green
        case "medium", "moderate": return IndieHousePalette.orange
        case "hard", "hard (indoors)": return IndieHousePalette.red
        default: return Color.claudeAccent
        }
    }

    private var icon: String {
        switch difficulty.lowercased() {
        case "very easy": return "sparkles"
        case "easy": return "leaf.fill"
        case "hard", "hard (indoors)": return "exclamationmark.triangle.fill"
        default: return "gauge.medium"
        }
    }

    var body: some View {
        if compact {
            Label(difficulty, systemImage: icon)
                .labelStyle(.titleOnly)
                .font(.claudeSans(size: 10, weight: .black))
                .foregroundStyle(Color.claudePrimaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(color.opacity(0.24))
                .overlay(Rectangle().stroke(Color.claudePrimaryText, lineWidth: 1))
        } else {
            ClaudeBadge(text: difficulty, icon: icon, color: color)
        }
    }
}
