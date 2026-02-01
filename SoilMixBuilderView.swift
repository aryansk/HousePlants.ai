import SwiftUI

struct SoilMixBuilderView: View {
    @State private var selectedPreset = SoilPreset.aroid
    @State private var components = SoilComponents()
    @State private var savedRecipes: [SavedRecipe] = []
    @State private var showSaveAlert = false
    @State private var newRecipeName = ""
    
    enum SoilPreset: String, CaseIterable, Identifiable {
        case aroid = "Aroid Mix"
        case succulent = "Succulent/Cactus"
        case fern = "Fern/Calathea"
        case custom = "Custom Build"
        var id: String { self.rawValue }
    }
    
    struct SoilComponents: Equatable {
        var base: Double = 40 // Peat/Coco Coir
        var aeration: Double = 30 // Perlite/Pumice
        var drainage: Double = 20 // Bark/Chips
        var additive: Double = 10 // Charcoal/Castings
    }
    
    struct SavedRecipe: Identifiable, Codable {
        let id = UUID()
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
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Soil Mix Builder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Craft the perfect substrate for your plants.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Soil Jar Visualization
                SoilJarView(components: components)
                    .frame(height: 250)
                    .padding(.horizontal)
                
                // Stats Card
                VStack(spacing: 16) {
                    Text("Mix Properties")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 20) {
                        DetailStat(icon: "drop.fill", title: "Retention", value: mixStats.retention)
                        DetailStat(icon: "wind", title: "Aeration", value: mixStats.aeration)
                        DetailStat(icon: "arrow.down.to.line.alt", title: "Drainage", value: mixStats.drainage)
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.green)
                        Text("Ideal for: ")
                            .foregroundStyle(.secondary) +
                        Text(mixStats.idealFor)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Controls
                VStack(spacing: 24) {
                    // Presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SoilPreset.allCases) { preset in
                                Button(action: {
                                    selectedPreset = preset
                                    applyPreset(preset)
                                }) {
                                    Text(preset.rawValue)
                                        .fontWeight(.medium)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(selectedPreset == preset ? Color.brown : Color.brown.opacity(0.1))
                                        .foregroundStyle(selectedPreset == preset ? .white : .brown)
                                        .cornerRadius(25)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sliders
                    VStack(spacing: 24) {
                        ComponentSlider(title: "Base (Coco/Peat)", value: $components.base, color: .brown, icon: "square.fill")
                        ComponentSlider(title: "Aeration (Perlite)", value: $components.aeration, color: .gray, icon: "circle.grid.hex.fill")
                        ComponentSlider(title: "Drainage (Bark)", value: $components.drainage, color: Color(UIColor.systemBrown), icon: "hexagon.fill")
                        ComponentSlider(title: "Additives (Charcoal)", value: $components.additive, color: .black, icon: "star.fill")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .onChange(of: components) { _ in
                        if selectedPreset != .custom {
                            // Only switch to custom if values don't match the current preset
                            // This is a simplification; ideally we'd check against preset values
                            selectedPreset = .custom
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: { showSaveAlert = true }) {
                        Label("Save Recipe", systemImage: "heart.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(16)
                    }
                    
                    Button(action: {}) {
                        Label("Shop Ingredients", systemImage: "cart.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                
                // Saved Recipes List
                if !savedRecipes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Saved Recipes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(savedRecipes) { recipe in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(recipe.name)
                                        .font(.headline)
                                    Text(recipe.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Soil Builder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { applyPreset(.aroid) }
        .alert("Save Recipe", isPresented: $showSaveAlert) {
            TextField("Recipe Name", text: $newRecipeName)
            Button("Save", action: saveRecipe)
            Button("Cancel", role: .cancel) { }
        }
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
                // Jar Shape Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                // Layers
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    // Additive Layer
                    if components.additive > 0 {
                        SoilLayer(color: .black, height: height(for: components.additive, in: geometry), texture: "star.fill")
                    }
                    
                    // Drainage Layer
                    if components.drainage > 0 {
                        SoilLayer(color: Color(UIColor.systemBrown), height: height(for: components.drainage, in: geometry), texture: "hexagon.fill")
                    }
                    
                    // Aeration Layer
                    if components.aeration > 0 {
                        SoilLayer(color: .gray, height: height(for: components.aeration, in: geometry), texture: "circle.fill")
                    }
                    
                    // Base Layer
                    if components.base > 0 {
                        SoilLayer(color: .brown, height: height(for: components.base, in: geometry), texture: "square.fill")
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(2)
                
                // Jar Lid
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray)
                        .frame(width: geometry.size.width * 0.8, height: 10)
                    Spacer()
                }
                .offset(y: -10)
            }
        }
    }
    
    func height(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let availableHeight = geometry.size.height
        // Normalize to ensure it fits if total > 100 (though sliders cap at 100 each, total can exceed)
        // But for visual, let's assume total is roughly 100-150 range and scale
        let scale = total > 0 ? availableHeight / total : 0
        return CGFloat(value) * scale
    }
}

struct SoilLayer: View {
    let color: Color
    let height: CGFloat
    let texture: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
            
            // Texture Pattern
            GeometryReader { geo in
                HStack(spacing: 10) {
                    ForEach(0..<Int(geo.size.width / 20), id: \.self) { _ in
                        VStack(spacing: 10) {
                            ForEach(0..<Int(geo.size.height / 20), id: \.self) { _ in
                                Image(systemName: texture)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.2))
                            }
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
        .frame(height: height)
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
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(value))%")
                    .font(.headline)
                    .foregroundStyle(color)
            }
            
            Slider(value: $value, in: 0...100, step: 5)
                .tint(color)
        }
    }
}

#Preview {
    NavigationView {
        SoilMixBuilderView()
    }
}
