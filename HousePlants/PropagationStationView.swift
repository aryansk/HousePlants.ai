import SwiftUI

struct PropagationStationView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMethod: PropMethodFilter = .all
    @State private var searchText = ""
    @State private var animateHero = false
    @State private var showInfoSheet = false
    
    enum PropMethodFilter: String, CaseIterable {
        case all = "All"
        case stemCutting = "Stem Cutting"
        case division = "Division"
        case leafCutting = "Leaf Cutting"
        case airLayering = "Air Layering"
        case offsets = "Offsets"
        case water = "Water"
    }
    
    var propagatablePlants: [Plant] {
        dataLoader.plants
    }
    
    var filteredPlants: [Plant] {
        var result = propagatablePlants
        
        if selectedMethod != .all {
            result = result.filter { plant in
                plant.effectivePropagation.methods.contains(where: {
                    $0.lowercased().contains(selectedMethod.rawValue.lowercased())
                })
            }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.commonName.localizedCaseInsensitiveContains(searchText) ||
                $0.botanicalName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var availableMethods: [PropMethodFilter] {
        var methods: Set<String> = []
        for plant in propagatablePlants {
            let propMethods = plant.effectivePropagation.methods
            for method in propMethods {
                methods.insert(method.lowercased())
            }
        }
        
        var filters: [PropMethodFilter] = [.all]
        for filter in PropMethodFilter.allCases where filter != .all {
            if methods.contains(where: { $0.contains(filter.rawValue.lowercased()) }) {
                filters.append(filter)
            }
        }
        // If we only found .all, show all methods as options anyway
        if filters.count <= 1 {
            return PropMethodFilter.allCases
        }
        return filters
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Propagation",
                    subtitle: "Multiply your botanical collection",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color(hex: "8E44AD").opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Hero Illustration
                        VStack(spacing: 16) {
                            ZStack {
                                // Ripple rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(Color.green.opacity(0.15), lineWidth: 2)
                                        .frame(width: 100 + CGFloat(i * 35), height: 100 + CGFloat(i * 35))
                                        .scaleEffect(animateHero ? 1.08 : 1.0)
                                        .opacity(animateHero ? 0.4 : 0.15)
                                        .animation(reduceMotion ? nil : .easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(i) * 0.25), value: animateHero)
                                }
                                
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "scissors")
                                    .font(.system(size: 44))
                                    .foregroundColor(.green)
                                    .rotationEffect(.degrees(-30))
                                    .shadow(color: .green.opacity(0.3), radius: 8)
                            }
                            .onAppear { animateHero = !reduceMotion }
                            
                            Text("From one, many.")
                                .font(.claudeSans(size: 15))
                                .foregroundColor(.claudeSecondaryText)
                                .italic()
                        }
                        .padding(.top, 10)
                        
                        // Search
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.claudeSecondaryText)
                            TextField("Search plants...", text: $searchText)
                                .font(.claudeSans(size: 15))
                                .foregroundColor(.claudePrimaryText)
                        }
                        .padding(14)
                        .background(Color.claudeSecondaryBackground)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Method Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableMethods, id: \.self) { method in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedMethod = method
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: iconForMethod(method))
                                                .font(.system(size: 12))
                                            Text(method.rawValue)
                                                .font(.claudeSans(size: 13, weight: .bold))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedMethod == method ? Color.green : Color.claudeSecondaryBackground)
                                        .foregroundColor(selectedMethod == method ? .white : .claudePrimaryText)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(selectedMethod == method ? Color.green : Color.claudeBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(BubblingButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Results Count
                        HStack {
                            Text("\(filteredPlants.count) PROPAGATABLE SPECIES")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Plant Cards
                        VStack(spacing: 14) {
                            ForEach(filteredPlants) { plant in
                                NavigationLink(destination: PropagationDetailView(plant: plant)) {
                                    PropagationPlantCard(plant: plant)
                                }
                                .buttonStyle(InteractiveCardButtonStyle())
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
            PropagationInfoSheet()
        }
    }
    
    func iconForMethod(_ method: PropMethodFilter) -> String {
        switch method {
        case .all: return "square.grid.2x2.fill"
        case .stemCutting: return "scissors"
        case .division: return "arrow.triangle.branch"
        case .leafCutting: return "leaf.fill"
        case .airLayering: return "wind"
        case .offsets: return "plus.circle.fill"
        case .water: return "drop.fill"
        }
    }
}

// MARK: - Propagation Plant Card

struct PropagationPlantCard: View {
    let plant: Plant
    
    var difficultyColor: Color {
        switch plant.effectivePropagation.difficulty.lowercased() {
        case "easy", "beginner": return .green
        case "moderate", "medium", "intermediate": return .orange
        case "hard", "difficult", "advanced", "expert": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Plant icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(.claudeSerif(size: 17, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    let methods = plant.effectivePropagation.methods
                    Text(methods.prefix(2).joined(separator: ", "))
                        .font(.claudeSans(size: 12))
                        .foregroundColor(.claudeSecondaryText)
                        .lineLimit(1)
                }
                
                let difficulty = plant.effectivePropagation.difficulty
                HStack(spacing: 4) {
                    Circle()
                        .fill(difficultyColor)
                        .frame(width: 6, height: 6)
                    Text(difficulty)
                        .font(.claudeSans(size: 11, weight: .bold))
                        .foregroundColor(difficultyColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.claudeBorder)
        }
        .padding(16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

// MARK: - Propagation Detail View

struct PropagationDetailView: View {
    @Environment(\.dismiss) var dismiss
    let plant: Plant
    @State private var completedSteps: Set<Int> = []
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: plant.commonName,
                    subtitle: plant.botanicalName,
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Summary Card
                        let prop = plant.effectivePropagation
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                PropStatBubble(
                                    icon: "gauge.medium",
                                    label: "Difficulty",
                                    value: prop.difficulty,
                                    color: difficultyColor(prop.difficulty)
                                )
                                PropStatBubble(
                                    icon: "arrow.triangle.branch",
                                    label: "Methods",
                                    value: "\(prop.methods.count)",
                                    color: .green
                                )
                                PropStatBubble(
                                    icon: "list.number",
                                    label: "Steps",
                                    value: "\(prop.instructions.count)",
                                    color: .blue
                                )
                            }
                            
                            // Methods Tags
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PROPAGATION METHODS")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(prop.methods, id: \.self) { method in
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 10))
                                            Text(method)
                                                .font(.claudeSans(size: 13, weight: .bold))
                                        }
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.claudeSecondaryBackground)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Step-by-Step Instructions
                        if !prop.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("STEP-BY-STEP GUIDE")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(prop.instructions.enumerated()), id: \.offset) { index, instruction in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                if completedSteps.contains(index) {
                                                    completedSteps.remove(index)
                                                } else {
                                                    completedSteps.insert(index)
                                                }
                                            }
                                        }) {
                                            HStack(alignment: .top, spacing: 16) {
                                                // Step Number / Completion
                                                ZStack {
                                                    Circle()
                                                        .fill(completedSteps.contains(index) ? Color.green : Color.claudeAccent.opacity(0.1))
                                                        .frame(width: 36, height: 36)
                                                    
                                                    if completedSteps.contains(index) {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.white)
                                                    } else {
                                                        Text("\(index + 1)")
                                                            .font(.claudeSans(size: 15, weight: .bold))
                                                            .foregroundColor(.claudeAccent)
                                                    }
                                                }
                                                
                                                // Vertical line connector
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text(instruction)
                                                        .font(.claudeSans(size: 15))
                                                        .foregroundColor(completedSteps.contains(index) ? .claudeSecondaryText : .claudePrimaryText)
                                                        .strikethrough(completedSteps.contains(index))
                                                        .multilineTextAlignment(.leading)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    
                                                    if index < prop.instructions.count - 1 {
                                                        Rectangle()
                                                            .fill(Color.claudeBorder)
                                                            .frame(width: 2, height: 16)
                                                            .padding(.leading, -33)
                                                            .offset(x: 17)
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(24)
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                                .padding(.horizontal, 20)
                                
                                // Progress
                                let total = prop.instructions.count
                                let completed = completedSteps.count
                                
                                HStack {
                                    Text("Progress")
                                        .font(.claudeSans(size: 13, weight: .bold))
                                        .foregroundColor(.claudeSecondaryText)
                                    Spacer()
                                    Text("\(completed)/\(total) steps")
                                        .font(.claudeSans(size: 13, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 24)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.claudeBorder)
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.green)
                                            .frame(width: total > 0 ? geo.size.width * CGFloat(completed) / CGFloat(total) : 0, height: 8)
                                            .animation(.spring(response: 0.4), value: completed)
                                    }
                                }
                                .frame(height: 8)
                                .padding(.horizontal, 24)
                            }
                        }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy", "beginner": return .green
        case "moderate", "medium", "intermediate": return .orange
        case "hard", "difficult", "advanced", "expert": return .red
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct PropStatBubble: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.claudeSans(size: 14, weight: .bold))
                .foregroundColor(.claudePrimaryText)
            Text(label.uppercased())
                .font(.claudeSans(size: 9, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

// MARK: - Info Sheet View
struct PropagationInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How Propagation Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Learn to multiply your plant collection using proven propagation techniques, with step-by-step instructions for each species.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "scissors", title: "Stem Cuttings", text: "The most common method. Snip below a node, remove lower leaves, and root in water or moist soil. Works for pothos, philodendrons, and more.", color: .green)
                            
                            InfoRow(icon: "arrow.triangle.branch", title: "Division", text: "Separate a mature plant into smaller sections, each with its own root system. Ideal for ferns, peace lilies, and snake plants.", color: .blue)
                            
                            InfoRow(icon: "leaf.fill", title: "Leaf Cuttings", text: "Some species can grow entirely new plants from a single leaf. Popular for succulents, begonias, and African violets.", color: .purple)
                            
                            InfoRow(icon: "wind", title: "Air Layering", text: "Encourage roots to grow on an attached stem before cutting. Best for woody plants like fiddle leaf figs and rubber trees.", color: .orange)
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
        PropagationStationView()
    }
}
