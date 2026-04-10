import SwiftUI
import MapKit

struct OriginExplorerView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var selectedPlant: Plant?
    @State private var selectedRegion: String?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showInfoSheet = false
    
    var regions: [String] {
        let allRegions = dataLoader.plants.map { $0.origin.region }
        return Array(Set(allRegions)).sorted()
    }
    
    var filteredPlants: [Plant] {
        if let region = selectedRegion {
            return dataLoader.plants.filter { $0.origin.region == region }
        }
        return dataLoader.plants
    }
    
    var regionStats: [(region: String, count: Int)] {
        var stats: [String: Int] = [:]
        for plant in dataLoader.plants {
            stats[plant.origin.region, default: 0] += 1
        }
        return stats.map { (region: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Origin Explorer",
                    subtitle: "Discover where your plants call home",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.claudeAccent.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Interactive Map
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BOTANICAL MAP")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            Map(position: $mapPosition) {
                                ForEach(filteredPlants) { plant in
                                    Annotation(plant.commonName, coordinate: CLLocationCoordinate2D(
                                        latitude: plant.origin.coordinates.lat,
                                        longitude: plant.origin.coordinates.lng
                                    )) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedPlant = plant
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.claudeAccent)
                                                    .frame(width: 28, height: 28)
                                                    .shadow(color: Color.claudeAccent.opacity(0.4), radius: 4, x: 0, y: 2)
                                                
                                                Image(systemName: "leaf.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                            .mapStyle(.standard(elevation: .realistic))
                            .frame(height: 280)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Selected Plant Info Card
                        if let plant = selectedPlant {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("SELECTED SPECIMEN")
                                        .font(.claudeSans(size: 11, weight: .bold))
                                        .foregroundColor(.claudeSecondaryText)
                                        .tracking(1.5)
                                    Spacer()
                                    Button(action: {
                                        withAnimation { selectedPlant = nil }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.claudeSecondaryText)
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.teal.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.system(size: 26))
                                            .foregroundColor(.teal)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plant.commonName)
                                            .font(.claudeSerif(size: 20, weight: .bold))
                                            .foregroundColor(.claudePrimaryText)
                                        Text(plant.botanicalName)
                                            .font(.claudeSans(size: 13))
                                            .foregroundColor(.claudeSecondaryText)
                                            .italic()
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Origin Details
                                VStack(spacing: 10) {
                                    OriginInfoRow(icon: "map.fill", label: "Region", value: plant.origin.region)
                                    
                                    if let countries = plant.origin.countries, !countries.isEmpty {
                                        OriginInfoRow(icon: "flag.fill", label: "Countries", value: countries.joined(separator: ", "))
                                    }
                                    
                                    OriginInfoRow(icon: "location.fill", label: "Coordinates", value: String(format: "%.2f°, %.2f°", plant.origin.coordinates.lat, plant.origin.coordinates.lng))
                                    
                                    OriginInfoRow(icon: "thermometer.medium", label: "Climate", value: plant.careGuide.temperatureRange)
                                }
                                
                                // Navigate to plant
                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("View Full Profile")
                                    }
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.claudeAccent)
                                    .cornerRadius(16)
                                }
                                .buttonStyle(BubblingButtonStyle())
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        // Region Filter
                        VStack(alignment: .leading, spacing: 16) {
                            Text("FILTER BY REGION")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // All button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedRegion = nil
                                            mapPosition = .automatic
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "globe")
                                                .font(.system(size: 12))
                                            Text("All")
                                                .font(.claudeSans(size: 13, weight: .bold))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedRegion == nil ? Color.teal : Color.claudeSecondaryBackground)
                                        .foregroundColor(selectedRegion == nil ? .white : .claudePrimaryText)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(selectedRegion == nil ? Color.teal : Color.claudeBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(BubblingButtonStyle())
                                    
                                    ForEach(regions, id: \.self) { region in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedRegion = region
                                                // Zoom to region
                                                if let firstPlant = dataLoader.plants.first(where: { $0.origin.region == region }) {
                                                    mapPosition = .region(MKCoordinateRegion(
                                                        center: CLLocationCoordinate2D(
                                                            latitude: firstPlant.origin.coordinates.lat,
                                                            longitude: firstPlant.origin.coordinates.lng
                                                        ),
                                                        span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
                                                    ))
                                                }
                                            }
                                        }) {
                                            Text(region)
                                                .font(.claudeSans(size: 13, weight: .bold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedRegion == region ? Color.teal : Color.claudeSecondaryBackground)
                                                .foregroundColor(selectedRegion == region ? .white : .claudePrimaryText)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(selectedRegion == region ? Color.teal : Color.claudeBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(BubblingButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Region Statistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BIODIVERSITY BY REGION")
                                .font(.claudeSans(size: 11, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(regionStats.enumerated()), id: \.offset) { index, stat in
                                    HStack(spacing: 14) {
                                        // Rank
                                        Text("#\(index + 1)")
                                            .font(.claudeSans(size: 14, weight: .bold))
                                            .foregroundColor(.claudeSecondaryText)
                                            .frame(width: 30)
                                        
                                        // Region icon
                                        ZStack {
                                            Circle()
                                                .fill(regionColor(for: stat.region).opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: regionIcon(for: stat.region))
                                                .font(.system(size: 14))
                                                .foregroundColor(regionColor(for: stat.region))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stat.region)
                                                .font(.claudeSans(size: 15, weight: .bold))
                                                .foregroundColor(.claudePrimaryText)
                                                .lineLimit(1)
                                            
                                            // Progress bar
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(Color.claudeBorder)
                                                        .frame(height: 4)
                                                    
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(regionColor(for: stat.region))
                                                        .frame(
                                                            width: geo.size.width * CGFloat(stat.count) / CGFloat(regionStats.first?.count ?? 1),
                                                            height: 4
                                                        )
                                                }
                                            }
                                            .frame(height: 4)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(stat.count)")
                                            .font(.claudeSerif(size: 18, weight: .bold))
                                            .foregroundColor(regionColor(for: stat.region))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    
                                    if index < regionStats.count - 1 {
                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                            }
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Plants from selected region
                        if let region = selectedRegion {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PLANTS FROM \(region.uppercased())")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 10) {
                                    ForEach(filteredPlants) { plant in
                                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                                            HStack(spacing: 14) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.teal.opacity(0.1))
                                                        .frame(width: 44, height: 44)
                                                    Image(systemName: "leaf.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.teal)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(plant.commonName)
                                                        .font(.claudeSans(size: 15, weight: .bold))
                                                        .foregroundColor(.claudePrimaryText)
                                                        .lineLimit(1)
                                                    
                                                    if let countries = plant.origin.countries, !countries.isEmpty {
                                                        Text(countries.prefix(3).joined(separator: ", "))
                                                            .font(.claudeSans(size: 12))
                                                            .foregroundColor(.claudeSecondaryText)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.claudeBorder)
                                            }
                                            .padding(14)
                                            .background(Color.claudeSecondaryBackground)
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                                        }
                                        .buttonStyle(InteractiveCardButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
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
        .sheet(isPresented: $showInfoSheet) {
            OriginExplorerInfoSheet()
        }
    }
    
    func regionColor(for region: String) -> Color {
        let regionLower = region.lowercased()
        if regionLower.contains("tropical") || regionLower.contains("south america") || regionLower.contains("central america") {
            return .green
        } else if regionLower.contains("africa") || regionLower.contains("madagascar") {
            return .orange
        } else if regionLower.contains("asia") || regionLower.contains("china") || regionLower.contains("japan") {
            return .red
        } else if regionLower.contains("america") || regionLower.contains("mexico") || regionLower.contains("caribbean") {
            return .blue
        } else if regionLower.contains("europe") || regionLower.contains("mediterranean") {
            return .purple
        } else if regionLower.contains("australia") || regionLower.contains("oceania") {
            return .teal
        } else if regionLower.contains("arid") || regionLower.contains("desert") {
            return .brown
        } else {
            return .gray
        }
    }
    
    func regionIcon(for region: String) -> String {
        let regionLower = region.lowercased()
        if regionLower.contains("tropical") {
            return "leaf.fill"
        } else if regionLower.contains("africa") {
            return "sun.max.fill"
        } else if regionLower.contains("asia") {
            return "mountain.2.fill"
        } else if regionLower.contains("america") {
            return "globe.americas.fill"
        } else if regionLower.contains("europe") || regionLower.contains("mediterranean") {
            return "globe.europe.africa.fill"
        } else if regionLower.contains("desert") || regionLower.contains("arid") {
            return "sun.dust.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Info Sheet View

struct OriginExplorerInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What is Origin Explorer?")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Discover the native habitats of your plant collection and learn how their natural environment influences their care needs.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "map.fill", title: "Botanical Mapping", text: "Every plant in our database is pinned to its primary region of origin, helping you visualize the global biodiversity of your home.", color: .teal)
                            
                            InfoRow(icon: "thermometer.medium", title: "Climate Insight", text: "Understanding a plant's origin tells you about its humidity and temperature requirements. Tropical plants crave moisture, while arid species prefer dry air.", color: .orange)
                            
                            InfoRow(icon: "chart.bar.fill", title: "Biodiversity Stats", text: "Explore which regions contribute most to your indoor jungle and see how different continents are represented in your collection.", color: .purple)
                            
                            InfoRow(icon: "leaf.fill", title: "Care Connection", text: "Matching your home environment to a plant's native conditions is the secret to thriving greenery and long-term health.", color: .green)
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

// MARK: - Origin Info Row

struct OriginInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.teal)
                .frame(width: 24)
            
            Text(label)
                .font(.claudeSans(size: 13, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.claudeSans(size: 14))
                .foregroundColor(.claudePrimaryText)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationView {
        OriginExplorerView()
    }
}
