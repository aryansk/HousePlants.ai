import SwiftUI

struct SoilMixBuilderView: View {
    @State private var selectedPreset = SoilPreset.aroid
    @State private var components = SoilComponents()
    @State private var savedRecipes: [SavedRecipe] = []
    @State private var showSaveAlert = false
    @State private var newRecipeName = ""
    @State private var showShopAlert = false
    @State private var showInfoSheet = false
    @Namespace private var animation
    
    enum SoilPreset: String, CaseIterable, Identifiable {
        case aroid = "Aroid Mix"
        case succulent = "Succulent"
        case fern = "Tropical"
        case custom = "Custom"
        var id: String { self.rawValue }
    }
    
    struct SoilComponents: Equatable {
        var base: Double = 40 // Peat/Coco Coir
        var aeration: Double = 30 // Perlite/Pumice
        var drainage: Double = 20 // Bark/Chips
        var additive: Double = 10 // Charcoal/Castings
    }
    
    struct SavedRecipe: Identifiable, Codable {
        var id = UUID()
        let name: String
        let date: Date
        let components: [String: Double]
    }
    
    var mixStats: (drainage: String, retention: String, aeration: String, idealFor: String) {
        let drainageScore = (components.aeration + components.drainage) / 2
        let retentionScore = components.base
        
        let dText = drainageScore > 40 ? "High" : (drainageScore > 20 ? "Medium" : "Low")
        let rText = retentionScore > 50 ? "High" : (retentionScore > 30 ? "Medium" : "Low")
        let aText = components.aeration > 30 ? "Excellent" : "Standard"
        
        var ideal = "General Houseplants"
        if drainageScore > 45 { ideal = "Cacti & Succulents" }
        else if retentionScore > 50 { ideal = "Ferns & Calatheas" }
        else if components.drainage > 25 && components.aeration > 25 { ideal = "Aroids & Epiphytes" }
        
        return (dText, rText, aText, ideal)
    }
    
    func applyPreset(_ preset: SoilPreset) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            switch preset {
            case .aroid:
                components = SoilComponents(base: 30, aeration: 30, drainage: 30, additive: 10)
            case .succulent:
                components = SoilComponents(base: 20, aeration: 50, drainage: 30, additive: 0)
            case .fern:
                components = SoilComponents(base: 60, aeration: 20, drainage: 10, additive: 10)
            case .custom:
                break
            }
        }
    }
    
    func saveRecipe() {
        let recipe = SavedRecipe(name: newRecipeName.isEmpty ? "My Mix" : newRecipeName, date: Date(), components: [
            "Base": components.base,
            "Aeration": components.aeration,
            "Drainage": components.drainage,
            "Additive": components.additive
        ])
        savedRecipes.append(recipe)
        newRecipeName = ""
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Soil Mixologist",
                    subtitle: "Craft bespoke substrates for specific species",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.brown.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                        
                        // Soil Jar Visualization
                        VStack(spacing: 16) {
                            SoilJarView(components: components)
                                .frame(height: 280)
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 15)
                            
                            HStack(alignment: .center) {
                                Text("IDEAL FOR: ")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                Text(mixStats.idealFor)
                                    .font(.claudeSerif(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        // Mix Properties Cards
                        HStack(spacing: 12) {
                            MixPropertyCard(title: "Retention", value: mixStats.retention, icon: "drop.fill", color: .blue)
                             MixPropertyCard(title: "Aeration", value: mixStats.aeration, icon: "wind", color: .teal)
                             MixPropertyCard(title: "Drainage", value: mixStats.drainage, icon: "arrow.down.to.line.alt", color: .brown)
                        }
                        .padding(.horizontal, 20)
                        
                        // Presets Selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Starter Presets", icon: "sparkles")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(SoilPreset.allCases) { preset in
                                        Button(action: {
                                            selectedPreset = preset
                                            applyPreset(preset)
                                        }) {
                                            Text(preset.rawValue)
                                                .font(.claudeSans(size: 14, weight: .bold))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(selectedPreset == preset ? Color.brown : Color.claudeSecondaryBackground)
                                                .foregroundColor(selectedPreset == preset ? .white : .claudePrimaryText)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(selectedPreset == preset ? Color.brown : Color.claudeBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(BubblingButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Component Sliders
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Fine-tune Ingredients", icon: "slider.horizontal.3")
                            
                            VStack(spacing: 24) {
                                ComponentSlider(title: "Base (Coco/Peat)", value: $components.base, color: .brown, icon: "square.fill")
                                ComponentSlider(title: "Aeration (Perlite)", value: $components.aeration, color: .gray, icon: "circle.grid.hex.fill")
                                ComponentSlider(title: "Drainage (Bark)", value: $components.drainage, color: Color(hex: "8B4513"), icon: "hexagon.fill")
                                ComponentSlider(title: "Additives (Charcoal)", value: $components.additive, color: .black, icon: "star.fill")
                            }
                            .padding(24)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(28)
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Recipe Actions
                        VStack(spacing: 16) {
                            Button(action: { showSaveAlert = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Capture Recipe")
                                }
                                .font(.claudeSans(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.claudeAccent)
                                .cornerRadius(18)
                                .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            
                            Button(action: { showShopAlert = true }) {
                                HStack {
                                    Image(systemName: "cart.fill")
                                    Text("Order Fresh Ingredients")
                                }
                                .font(.claudeSans(size: 15, weight: .bold))
                                .foregroundColor(.claudeAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.claudeAccent.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Saved Recipes
                        if !savedRecipes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Your Archive", icon: "archivebox.fill")
                                
                                ForEach(savedRecipes) { recipe in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.name)
                                                .font(.claudeSerif(size: 18, weight: .bold))
                                                .foregroundColor(.claudePrimaryText)
                                            Text(recipe.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.claudeSans(size: 12))
                                                .foregroundColor(.claudeSecondaryText)
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
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Save Recipe", isPresented: $showSaveAlert) {
            TextField("Recipe Name", text: $newRecipeName)
            Button("Save", action: saveRecipe)
            Button("Cancel", role: .cancel) { }
        }
        .alert("Shopping", isPresented: $showShopAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Look for these soil components at your local garden center or boutique nursery for the freshest quality.")
        }
        .sheet(isPresented: $showInfoSheet) {
            SoilMixologistInfoSheet()
        }
    }
}

struct MixPropertyCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(title.uppercased())
                    .font(.claudeSans(size: 9, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
                    .tracking(1)
                Text(value)
                    .font(.claudeSans(size: 14, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

struct SoilJarView: View {
    let components: SoilMixBuilderView.SoilComponents
    
    var total: Double {
        components.base + components.aeration + components.drainage + components.additive
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Glass Jar Container
                RoundedRectangle(cornerRadius: 35)
                    .fill(
                        LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .background(BlurView(style: .systemThinMaterial).clipShape(RoundedRectangle(cornerRadius: 35)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    )
                
                // Content Layers
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    if components.additive > 0 {
                        SoilLayer(color: .black, height: height(for: components.additive, in: geometry), texture: "star.fill", opacity: 0.8)
                    }
                    
                    if components.drainage > 0 {
                        SoilLayer(color: Color(hex: "5C4033"), height: height(for: components.drainage, in: geometry), texture: "hexagon.fill", opacity: 0.9)
                    }
                    
                    if components.aeration > 0 {
                        SoilLayer(color: Color(hex: "E5E4E2"), height: height(for: components.aeration, in: geometry), texture: "circle.fill", opacity: 0.95)
                    }
                    
                    if components.base > 0 {
                        SoilLayer(color: Color(hex: "3D2B1F"), height: height(for: components.base, in: geometry), texture: "square.fill", opacity: 1.0)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 33))
                .padding(4)
                
                // Reflections
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4)
                        .padding(.leading, 20)
                        .padding(.vertical, 60)
                    Spacer()
                }
                
                // Jar Lid (Wooden Style)
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [Color(hex: "A0522D"), Color(hex: "8B4513")], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: geometry.size.width * 0.85, height: 24)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    Spacer()
                }
                .offset(y: -12)
            }
        }
        .frame(width: 180)
        .frame(maxWidth: .infinity)
    }
    
    func height(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let availableHeight = geometry.size.height - 20 // Account for lid
        let scale = total > 0 ? availableHeight / max(100, total) : 0
        return CGFloat(value) * scale
    }
}

struct SoilLayer: View {
    let color: Color
    let height: CGFloat
    let texture: String
    let opacity: Double
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(opacity))
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.1), .clear, .white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                )
            
            // Subtle Texture
            Canvas { context, size in
                for _ in 0..<Int(height * 2) {
                    let rect = CGRect(x: Double.random(in: 0...size.width), y: Double.random(in: 0...size.height), width: 2, height: 2)
                    context.fill(Path(rect), with: .color(Color.white.opacity(0.1)))
                }
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: height)
    }
}

struct ComponentSlider: View {
    let title: String
    @Binding var value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.claudeSans(size: 15, weight: .medium))
                        .foregroundColor(.claudePrimaryText)
                }
                Spacer()
                Text("\(Int(value))%")
                    .font(.claudeSans(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: 0...100, step: 5)
                .tint(color)
        }
    }
}

// MARK: - Info Sheet View
struct SoilMixologistInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Soil Mixologist Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Create custom soil blends tailored to your plant species by adjusting the ratio of base, aeration, drainage, and additive components.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "square.fill", title: "Base Layer", text: "Coco coir or peat moss forms the foundation, retaining moisture and providing structure for root development.", color: .brown)
                            
                            InfoRow(icon: "circle.grid.hex.fill", title: "Aeration", text: "Perlite or pumice creates air pockets in the soil, allowing roots to breathe and preventing compaction over time.", color: .gray)
                            
                            InfoRow(icon: "hexagon.fill", title: "Drainage", text: "Orchid bark or chips ensure excess water flows through freely, protecting roots from sitting in waterlogged soil.", color: Color(hex: "8B4513"))
                            
                            InfoRow(icon: "star.fill", title: "Additives", text: "Activated charcoal filters impurities while worm castings add slow-release nutrients for sustained growth.", color: .black)
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
        SoilMixBuilderView()
    }
}
