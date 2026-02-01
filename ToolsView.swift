import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: SunSeekerARView()) {
                        ToolRow(icon: "sun.max.fill", title: "Sun Seeker", description: "Measure light levels for your plants.")
                    }
                    
                    NavigationLink(destination: WaterCalculatorView()) {
                        ToolRow(icon: "drop.fill", title: "Water Calculator", description: "Calculate watering schedules.")
                    }
                    
                    NavigationLink(destination: PlantDoctorView()) {
                        ToolRow(icon: "cross.case.fill", title: "Plant Doctor", description: "Diagnose common plant issues.")
                    }
                    
                    NavigationLink(destination: SkincareLabView()) {
                        ToolRow(icon: "flask.fill", title: "Skincare Lab", description: "Discover DIY skincare recipes.")
                    }
                    
                    NavigationLink(destination: PotSizeCalculatorView()) {
                        ToolRow(icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Pot Size Calculator", description: "Find the perfect pot size.")
                    }
                    
                    NavigationLink(destination: MoonPhaseView()) {
                        ToolRow(icon: "moon.stars.fill", title: "Moon Gardening", description: "Plant by the lunar cycle.")
                    }
                    
                    NavigationLink(destination: FertilizerCalculatorView()) {
                        ToolRow(icon: "drop.triangle.fill", title: "Fertilizer Calculator", description: "Calculate dosage & frequency.")
                    }
                    
                    NavigationLink(destination: SoilMixBuilderView()) {
                        ToolRow(icon: "square.stack.3d.up.fill", title: "Soil Mix Builder", description: "Create custom soil recipes.")
                    }
                } header: {
                    Text("Available Tools")
                }
            }
            .navigationTitle("Tools")
        }
    }
}

struct ToolRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SunSeekerARView: View {
    @State private var isScanning = false
    @State private var lightLevel: Double = 0.5
    @State private var showCamera = false
    
    var lightStatus: (String, Color) {
        if lightLevel < 0.3 {
            return ("Low Light", .blue)
        } else if lightLevel < 0.7 {
            return ("Medium Light", .green)
        } else {
            return ("Bright Light", .orange)
        }
    }
    
    var body: some View {
        VStack {
            if showCamera {
                ZStack {
                    Color.black
                    
                    // Simulated Camera Feed
                    VStack {
                        Spacer()
                        Image(systemName: "camera.metering.center.weighted")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                    }
                    
                    // Overlay
                    VStack {
                        HStack {
                            Button("Close") {
                                showCamera = false
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                            Spacer()
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Meter
                        VStack(spacing: 20) {
                            Text(lightStatus.0)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(lightStatus.1)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                            
                            VStack {
                                Text("Simulated Light Level")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                                Slider(value: $lightLevel)
                                    .tint(lightStatus.1)
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                            .padding()
                        }
                        .padding(.bottom, 50)
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "sun.max.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.orange)
                            .padding(.top)
                        
                        Text("Sun Seeker")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Use your camera to measure light intensity in your room. Find the perfect spot for your plants.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Start Light Meter")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Light Guide")
                                .font(.headline)
                            
                            LightGuideRow(title: "Low Light", desc: "North-facing windows, corners away from windows.", color: .blue)
                            LightGuideRow(title: "Medium Light", desc: "East/West windows, filtered light.", color: .green)
                            LightGuideRow(title: "Bright Light", desc: "South-facing windows, direct sun.", color: .orange)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding()
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationBarHidden(showCamera)
    }
}

struct LightGuideRow: View {
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(.top, 4)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PotSizeCalculatorView: View {
    @State private var currentDiameter: Double = 4
    @State private var isRootBound = false
    @State private var growthRate = 1 // 0: Slow, 1: Moderate, 2: Fast
    
    var recommendedSize: Double {
        var increase = 1.0
        if isRootBound { increase += 1.0 }
        if growthRate == 2 { increase += 1.0 }
        if growthRate == 0 { increase = max(0.5, increase - 0.5) }
        return currentDiameter + increase
    }
    
    var body: some View {
        Form {
            Section(header: Text("Current Pot")) {
                HStack {
                    Text("Diameter")
                    Spacer()
                    Text("\(Int(currentDiameter)) inches")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $currentDiameter, in: 2...20, step: 1) {
                    Text("Diameter")
                }
                
                Toggle("Is the plant root-bound?", isOn: $isRootBound)
            }
            
            Section(header: Text("Plant Details")) {
                Picker("Growth Rate", selection: $growthRate) {
                    Text("Slow").tag(0)
                    Text("Moderate").tag(1)
                    Text("Fast").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Recommendation")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("New Pot Size")
                            .font(.headline)
                        Text("Recommended diameter")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(recommendedSize)) inches")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Text(isRootBound ? "Since your plant is root-bound, give it some extra space to expand." : "A moderate increase will prevent waterlogging.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pot Calculator")
    }
}

struct MoonPhaseView: View {
    // Simulated Moon Phase for Demo
    let phaseName = "Waxing Gibbous"
    let illumination = "78%"
    let advice = "Great time for planting above-ground crops and leafy greens."
    
    var body: some View {
        ZStack {
            Color(hex: "0B0F19").ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Moon Graphic
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(
                            RadialGradient(gradient: Gradient(colors: [.white, .gray]), center: .center, startRadius: 50, endRadius: 100)
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: .white.opacity(0.5), radius: 20, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        )
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text(phaseName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Illumination: \(illumination)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                VStack(spacing: 16) {
                    Text("Gardening Advice")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text(advice)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("Moon Phase")
        .navigationBarTitleDisplayMode(.inline)
    }
}



struct SkincareLabView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var selectedCategory: String = "All"
    
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flask.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.purple)
                        Text("Skincare Lab")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Discover natural remedies from your garden.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .fontWeight(.medium)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == category ? Color.purple : Color.purple.opacity(0.1))
                                    .foregroundStyle(selectedCategory == category ? .white : .purple)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if skincarePlants.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("No recipes found for this category.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(skincarePlants) { plant in
                            NavigationLink(destination: RecipeDetailView(plant: plant)) {
                                RecipeCard(plant: plant)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RecipeCard: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plant.commonName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if let benefits = plant.skincarePotential?.benefits {
                        Text(benefits)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: 8) {
                        if let difficulty = plant.skincarePotential?.difficulty {
                            Label(difficulty, systemImage: "chart.bar.fill")
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if let time = plant.skincarePotential?.prepTime {
                            Label(time, systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecipeDetailView: View {
    let plant: Plant
    
    var skincare: SkincarePotential? {
        plant.skincarePotential
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "flask.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.purple)
                    }
                    
                    VStack(spacing: 8) {
                        Text(plant.commonName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let skinTypes = skincare?.skinTypes {
                            Text("Best for: " + skinTypes.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                // Quick Stats
                HStack(spacing: 20) {
                    DetailStat(icon: "clock.fill", title: "Time", value: skincare?.prepTime ?? "--")
                    DetailStat(icon: "chart.bar.fill", title: "Level", value: skincare?.difficulty ?? "--")
                    DetailStat(icon: "hourglass", title: "Shelf Life", value: skincare?.shelfLife ?? "--")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Ingredients
                if let ingredients = skincare?.ingredients {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(ingredients, id: \.name) { ingredient in
                            HStack {
                                Text("•")
                                    .foregroundStyle(.purple)
                                Text(ingredient.amount)
                                    .fontWeight(.medium)
                                Text(ingredient.name)
                                Spacer()
                                if let purpose = ingredient.purpose {
                                    Text(purpose)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Instructions
                if let instructions = skincare?.instructions {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.purple))
                                
                                Text(step)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Tips & Warnings
                VStack(spacing: 16) {
                    if let tips = skincare?.tips {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Pro Tips", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            ForEach(tips, id: \.self) { tip in
                                Text("• " + tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if let warning = skincare?.warnings {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Caution", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.red)
                            
                            Text(warning)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailStat: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.purple)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
