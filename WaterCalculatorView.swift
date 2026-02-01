import SwiftUI

struct WaterCalculatorView: View {
    @State private var selectedPlantType = PlantType.tropical
    @State private var potSize = PotSize.medium
    @State private var season = Season.summer
    
    enum PlantType: String, CaseIterable {
        case tropical = "Tropical"
        case succulent = "Succulent/Cactus"
        case fern = "Fern"
        case herb = "Herb"
        
        var baseWateringDays: Int {
            switch self {
            case .tropical: return 7
            case .succulent: return 14
            case .fern: return 4
            case .herb: return 3
            }
        }
    }
    
    enum PotSize: String, CaseIterable {
        case small = "Small (4-6\")"
        case medium = "Medium (8-10\")"
        case large = "Large (12\"+)"
        
        var multiplier: Double {
            switch self {
            case .small: return 0.8
            case .medium: return 1.0
            case .large: return 1.5
            }
        }
        
        var volume: String {
            switch self {
            case .small: return "100-200ml"
            case .medium: return "300-500ml"
            case .large: return "1-1.5 Liters"
            }
        }
    }
    
    enum Season: String, CaseIterable {
        case summer = "Spring/Summer"
        case winter = "Fall/Winter"
        
        var dayModifier: Int {
            switch self {
            case .summer: return 0
            case .winter: return 4 // Add days between watering in winter
            }
        }
    }
    
    var calculatedFrequency: String {
        let base = Double(selectedPlantType.baseWateringDays)
        let sizeMod = potSize.multiplier
        let seasonMod = Double(season.dayModifier)
        
        let days = Int((base * sizeMod) + seasonMod)
        return "Every \(days)-\(days + 2) days"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("Water Calculator")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Estimate watering needs based on plant type and conditions.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Input Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Plant Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading) {
                        Text("Plant Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Plant Type", selection: $selectedPlantType) {
                            ForEach(PlantType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pot Size")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Pot Size", selection: $potSize) {
                            ForEach(PotSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Season")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Season", selection: $season) {
                            ForEach(Season.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Result Card
                VStack(spacing: 16) {
                    Text("Recommended Schedule")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(calculatedFrequency)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    
                    Divider()
                    
                    HStack {
                        VStack {
                            Text("Amount")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(potSize.volume)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("Method")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Soil Soak")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Text("Note: Always check soil moisture before watering. These are estimates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Water Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        WaterCalculatorView()
    }
}
