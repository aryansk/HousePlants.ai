import SwiftUI

struct SkincareLabView: View {
    @Environment(DataLoader.self) var dataLoader
    @State private var selectedCategory: String = "All"
    @State private var showDisclaimer: Bool = true
    @State private var showInfoSheet = false
    @Namespace private var animation
    
    var skincarePlants: [Plant] {
        let all = dataLoader.plants.filter { $0.skincarePotential?.enabled == true }
        if selectedCategory == "All" {
            return all
        }
        return all.filter { plant in
            plant.skincarePotential?.categories?.contains(selectedCategory) ?? false
        }
    }
    
    var categories: [String] {
        let allCategories = dataLoader.plants
            .compactMap { $0.skincarePotential?.categories }
            .flatMap { $0 }
        return ["All"] + Array(Set(allCategories)).sorted()
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Skincare Lab",
                    subtitle: "Discover botanical remedies from your garden",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.purple.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                        // Safety Disclaimer
                        if showDisclaimer {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Safety Notice")
                                        .font(.claudeSans(size: 14, weight: .bold))
                                        .foregroundColor(.claudePrimaryText)
                                    Text("These recipes are for educational purposes only. Always perform a patch test before applying any recipe. Consult a dermatologist if you have allergies or sensitive skin.")
                                        .font(.claudeSans(size: 13))
                                        .foregroundColor(.claudeSecondaryText)
                                        .lineSpacing(3)
                                }
                                
                                Button(action: { withAnimation { showDisclaimer = false } }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.claudeSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }

                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        Text(category)
                                            .font(.claudeSans(size: 14, weight: .medium))
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .foregroundStyle(selectedCategory == category ? .white : .purple)
                                            .background {
                                                if selectedCategory == category {
                                                    Capsule()
                                                        .fill(Color.purple)
                                                        .matchedGeometryEffect(id: "categoryBackground", in: animation)
                                                } else {
                                                    Capsule()
                                                        .fill(Color.purple.opacity(0.08))
                                                }
                                            }
                                    }
                                    .buttonStyle(BubblingButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if skincarePlants.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "leaf.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.claudeBorder)
                                Text("No recipes found for this category.")
                                    .font(.claudeSans(size: 16))
                                    .foregroundStyle(Color.claudeSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(skincarePlants) { plant in
                                    NavigationLink(destination: RecipeDetailView(plant: plant)) {
                                        RecipeCard(plant: plant)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        }
                        .frame(width: geometry.size.width, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            SkincareLabInfoSheet()
        }
    }
}

struct RecipeCard: View {
    let plant: Plant
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(plant.commonName)
                    .font(.claudeSerif(size: 20, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                
                if let benefits = plant.skincarePotential?.benefits {
                    Text(benefits)
                        .font(.claudeSans(size: 14))
                        .foregroundColor(.claudeSecondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack(spacing: 8) {
                    if let difficulty = plant.skincarePotential?.difficulty {
                        Text(difficulty.uppercased())
                            .font(.claudeSans(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(6)
                    }
                    
                    if let time = plant.skincarePotential?.prepTime {
                        Text(time.uppercased())
                            .font(.claudeSans(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.claudeBorder)
        }
        .padding(20)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

struct RecipeDetailView: View {
    @Environment(\.dismiss) var dismiss
    let plant: Plant
    var skincare: SkincarePotential? { plant.skincarePotential }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (No ClaudeHeader here to keep it simplified for details)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.claudePrimaryText)
                            .padding(10)
                            .background(Circle().fill(Color.claudeSecondaryBackground))
                    }
                    Spacer()
                }
                .padding(24)
                
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                        // Header Section
                        VStack(alignment: .center, spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.08))
                                    .frame(width: 90, height: 90)
                                Image(systemName: "flask.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.purple)
                            }
                            
                            VStack(spacing: 8) {
                                Text(plant.commonName)
                                    .font(.claudeSerif(size: 32, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                                
                                HStack(spacing: 12) {
                                    Label(skincare?.difficulty ?? "Unknown", systemImage: "gauge")
                                    Text("•")
                                    Label(skincare?.prepTime ?? "Unknown", systemImage: "clock")
                                }
                                .font(.claudeSans(size: 14))
                                .foregroundColor(.claudeSecondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Botanical Benefits")
                                .font(.claudeSans(size: 12, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .textCase(.uppercase)
                                .tracking(2)
                            
                            Text(skincare?.benefits ?? "No specific benefits listed.")
                                .font(.claudeSerif(size: 20, weight: .regular))
                                .lineSpacing(6)
                                .foregroundColor(.claudePrimaryText)
                        }
                        .padding(.horizontal, 24)
                        
                        // Ingredients
                        if let ingredients = skincare?.ingredients, !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("The Formula")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(2)
                                
                                VStack(spacing: 0) {
                                    ForEach(ingredients, id: \.self) { ingredient in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.purple)
                                            Text(ingredient.amount)
                                                .font(.claudeSans(size: 16, weight: .bold))
                                                .foregroundColor(.claudePrimaryText)
                                            Text(ingredient.name)
                                                .font(.claudeSans(size: 16))
                                                .foregroundColor(.claudePrimaryText)
                                            Spacer()
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        
                                        if ingredient != ingredients.last {
                                            Divider().padding(.leading, 50)
                                        }
                                    }
                                }
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Instructions
                        if let steps = skincare?.instructions, !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Preparation Guide")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(2)
                                
                                VStack(alignment: .leading, spacing: 24) {
                                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                        HStack(alignment: .top, spacing: 16) {
                                            Text("\(index + 1)")
                                                .font(.claudeSerif(size: 20, weight: .bold))
                                                .foregroundColor(.purple.opacity(0.3))
                                                .frame(width: 24)
                                            
                                            Text(step)
                                                .font(.claudeSans(size: 15))
                                                .foregroundColor(.claudePrimaryText)
                                                .lineSpacing(4)
                                        }
                                    }
                                }
                                .padding(24)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(24)
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            .padding(.horizontal, 24)
                        }
                        }
                        .frame(width: geometry.size.width, alignment: .leading)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Info Sheet View
struct SkincareLabInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Skincare Lab Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Discover botanical skincare recipes using plants from your own collection, with step-by-step preparation guides and ingredient lists.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "flask.fill", title: "Curated Recipes", text: "Each recipe is crafted using the natural skincare properties of specific houseplants, from aloe vera gels to lavender toners.", color: .purple)
                            
                            InfoRow(icon: "tag.fill", title: "Category Filters", text: "Browse recipes by skin concern — moisturizing, soothing, anti-aging, or cleansing — to find exactly what you need.", color: .blue)
                            
                            InfoRow(icon: "clock.fill", title: "Difficulty & Time", text: "Every recipe shows preparation difficulty and time required, so you can choose quick remedies or weekend projects.", color: .orange)
                            
                            InfoRow(icon: "exclamationmark.triangle.fill", title: "Safety First", text: "Always patch test before applying any botanical recipe. Consult a dermatologist if you have sensitive skin or allergies.", color: .red)
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
