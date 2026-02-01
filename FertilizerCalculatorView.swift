import SwiftUI

struct FertilizerCalculatorView: View {
    @State private var fertilizerType = FertilizerType.liquid
    @State private var plantType = PlantType.foliage
    @State private var season = Season.springSummer
    
    enum FertilizerType: String, CaseIterable, Identifiable {
        case liquid = "Liquid"
        case granular = "Granular"
        case slowRelease = "Slow Release"
        var id: String { self.rawValue }
    }
    
    enum PlantType: String, CaseIterable, Identifiable {
        case foliage = "Foliage (Aroids, Ferns)"
        case flowering = "Flowering"
        case succulent = "Succulent/Cactus"
        var id: String { self.rawValue }
    }
    
    enum Season: String, CaseIterable, Identifiable {
        case springSummer = "Spring/Summer (Growing)"
        case fallWinter = "Fall/Winter (Dormant)"
        var id: String { self.rawValue }
    }
    
    var recommendation: (dilution: String, frequency: String, note: String) {
        if season == .fallWinter {
            return ("None", "Pause Fertilizing", "Most plants rest in winter. Avoid fertilizing to prevent salt buildup and leggy growth.")
        }
        
        switch (fertilizerType, plantType) {
        case (.liquid, .succulent):
            return ("1/4 Strength", "Every 4-6 weeks", "Succulents are light feeders. Dilute heavily.")
        case (.liquid, .foliage):
            return ("1/2 Strength", "Every 2-3 weeks", "Consistent feeding supports lush leaf growth.")
        case (.liquid, .flowering):
            return ("Full Strength", "Every 2 weeks", "Flowering takes energy. Ensure fertilizer is high in Phosphorus.")
            
        case (.granular, .succulent):
            return ("1/4 Recommended Amount", "Once per season", "Top dress lightly. Avoid touching the stem.")
        case (.granular, .foliage):
            return ("1/2 Recommended Amount", "Monthly", "Mix into topsoil and water thoroughly.")
        case (.granular, .flowering):
            return ("Recommended Amount", "Monthly", "Follow package instructions closely.")
            
        case (.slowRelease, .succulent):
            return ("Low Dose", "Once in Spring", "Pellets last a long time. Don't overdo it.")
        case (.slowRelease, .foliage):
            return ("Standard Dose", "Every 3-6 months", "Great for consistent, low-maintenance feeding.")
        case (.slowRelease, .flowering):
            return ("Standard Dose", "Every 3 months", "Refresh as blooms appear.")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "drop.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("Fertilizer Calculator")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Find the right balance for your plants.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Inputs
                VStack(spacing: 20) {
                    InputSection(title: "Fertilizer Type", icon: "flask.fill", color: .blue) {
                        Picker("Type", selection: $fertilizerType) {
                            ForEach(FertilizerType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    InputSection(title: "Plant Type", icon: "leaf.fill", color: .green) {
                        Picker("Plant", selection: $plantType) {
                            ForEach(PlantType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.green)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    InputSection(title: "Season", icon: "sun.max.fill", color: .orange) {
                        Picker("Season", selection: $season) {
                            ForEach(Season.allCases) { season in
                                Text(season.rawValue).tag(season)
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
                    Text("Recommendation")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 20) {
                        ResultStat(title: "Dilution", value: recommendation.dilution, icon: "drop.fill", color: .blue)
                        Divider()
                        ResultStat(title: "Frequency", value: recommendation.frequency, icon: "calendar", color: .purple)
                    }
                    
                    Divider()
                    
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text(recommendation.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Fertilizer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InputSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .fontWeight(.medium)
            }
            content()
        }
    }
}

struct ResultStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationView {
        FertilizerCalculatorView()
    }
}
