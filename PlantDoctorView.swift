import SwiftUI

struct PlantDoctorView: View {
    // Expanded Symptom Database
    let symptoms = [
        // Leaves
        Symptom(name: "Yellow Leaves", part: .leaves, icon: "leaf.arrow.triangle.pullpath", color: .yellow, possibleCauses: [
            Cause(title: "Overwatering", description: "Soil is constantly wet. Roots may be rotting.", fix: "Let soil dry out completely. Check drainage."),
            Cause(title: "Underwatering", description: "Leaves are crispy and dry.", fix: "Water thoroughly until water drains out bottom."),
            Cause(title: "Nutrient Deficiency", description: "Yellowing between veins (Chlorosis).", fix: "Apply balanced fertilizer with iron.")
        ]),
        Symptom(name: "Brown Tips/Edges", part: .leaves, icon: "leaf.fill", color: .brown, possibleCauses: [
            Cause(title: "Low Humidity", description: "Air is too dry for the plant.", fix: "Mist leaves or use a pebble tray/humidifier."),
            Cause(title: "Chemical Burn", description: "Tap water chemicals accumulating.", fix: "Use distilled or rain water."),
            Cause(title: "Fertilizer Burn", description: "Too much fertilizer salts.", fix: "Flush soil with water.")
        ]),
        Symptom(name: "White Spots/Powder", part: .leaves, icon: "cloud.snow.fill", color: .gray, possibleCauses: [
            Cause(title: "Powdery Mildew", description: "Fungal infection looking like flour.", fix: "Wipe off. Improve airflow. Use fungicide."),
            Cause(title: "Mealybugs", description: "White cottony fluff masses.", fix: "Dab with rubbing alcohol on a q-tip.")
        ]),
        Symptom(name: "Curling Leaves", part: .leaves, icon: "arrow.turn.right.up", color: .green, possibleCauses: [
            Cause(title: "Heat Stress", description: "Too hot or too much direct sun.", fix: "Move to a cooler, shadier spot."),
            Cause(title: "Pests", description: "Sucking insects hiding under leaves.", fix: "Inspect undersides and treat with neem oil.")
        ]),
        
        // Stems
        Symptom(name: "Mushy Stems", part: .stems, icon: "drop.triangle.fill", color: .black, possibleCauses: [
            Cause(title: "Root Rot", description: "Advanced rot traveling up stem.", fix: "Immediate emergency repotting. Cut away rot."),
            Cause(title: "Cold Damage", description: "Exposure to freezing temps.", fix: "Trim damaged parts. Keep warm.")
        ]),
        Symptom(name: "Leggy/Stretched", part: .stems, icon: "arrow.up.and.down", color: .green, possibleCauses: [
            Cause(title: "Low Light", description: "Reaching for light.", fix: "Move closer to a window or use grow lights.")
        ]),
        
        // Whole Plant
        Symptom(name: "Drooping/Wilting", part: .wholePlant, icon: "arrow.down", color: .green, possibleCauses: [
            Cause(title: "Thirsty", description: "Plant lacks turgor pressure.", fix: "Water immediately."),
            Cause(title: "Root Rot", description: "Roots damaged and can't drink.", fix: "Check roots. If mushy, treat for rot.")
        ]),
        Symptom(name: "Stunted Growth", part: .wholePlant, icon: "arrow.down.to.line", color: .orange, possibleCauses: [
            Cause(title: "Root Bound", description: "Roots have no room to grow.", fix: "Repot into a larger pot."),
            Cause(title: "Dormancy", description: "Natural winter resting phase.", fix: "Normal. Reduce water/fertilizer until spring.")
        ]),
        
        // Pests (General)
        Symptom(name: "Visible Pests", part: .pests, icon: "ant.fill", color: .red, possibleCauses: [
            Cause(title: "Spider Mites", description: "Tiny webs and stippling.", fix: "Shower plant. Use miticide."),
            Cause(title: "Scale", description: "Brown bumps on stems/leaves.", fix: "Scrape off. Use horticultural oil."),
            Cause(title: "Fungus Gnats", description: "Tiny flies around soil.", fix: "Let soil dry. Use sticky traps.")
        ])
    ]
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: DiagnosticWizardView(allSymptoms: symptoms)) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.title)
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading) {
                            Text("Start Diagnostic Wizard")
                                .font(.headline)
                                .foregroundStyle(.purple)
                            Text("Step-by-step help")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Browse by Symptom")) {
                ForEach(symptoms) { symptom in
                    NavigationLink(destination: SymptomDetailView(symptom: symptom)) {
                        HStack {
                            Image(systemName: symptom.icon)
                                .foregroundStyle(symptom.color)
                                .frame(width: 30)
                            Text(symptom.name)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Plant Doctor")
    }
}

// MARK: - Diagnostic Wizard
struct DiagnosticWizardView: View {
    let allSymptoms: [Symptom]
    @State private var selectedPart: PlantPart?
    
    var filteredSymptoms: [Symptom] {
        guard let part = selectedPart else { return [] }
        return allSymptoms.filter { $0.part == part }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple)
                    Text("Diagnostic Wizard")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Where do you see the problem?")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Part Selection Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    PartSelectionCard(part: .leaves, icon: "leaf.fill", color: .green, selected: selectedPart == .leaves) {
                        selectedPart = .leaves
                    }
                    PartSelectionCard(part: .stems, icon: "laurel.leading", color: .brown, selected: selectedPart == .stems) {
                        selectedPart = .stems
                    }
                    PartSelectionCard(part: .wholePlant, icon: "tree.fill", color: .orange, selected: selectedPart == .wholePlant) {
                        selectedPart = .wholePlant
                    }
                    PartSelectionCard(part: .pests, icon: "ant.fill", color: .red, selected: selectedPart == .pests) {
                        selectedPart = .pests
                    }
                }
                .padding()
                
                if selectedPart != nil {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Symptom")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredSymptoms) { symptom in
                            NavigationLink(destination: SymptomDetailView(symptom: symptom)) {
                                HStack {
                                    Image(systemName: symptom.icon)
                                        .font(.title2)
                                        .foregroundStyle(symptom.color)
                                        .frame(width: 40)
                                    
                                    Text(symptom.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: selectedPart)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PartSelectionCard: View {
    let part: PlantPart
    let icon: String
    let color: Color
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(selected ? .white : color)
                
                Text(part.rawValue)
                    .font(.headline)
                    .foregroundStyle(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selected ? color : Color.white)
            .cornerRadius(16)
            .shadow(color: selected ? color.opacity(0.4) : .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.clear : color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Models & Detail View

struct SymptomDetailView: View {
    let symptom: Symptom
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: symptom.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(symptom.color)
                    Text(symptom.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(symptom.color.opacity(0.1))
                
                Text("Possible Causes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ForEach(symptom.possibleCauses) { cause in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(cause.title)
                            .font(.headline)
                        
                        Text(cause.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .top) {
                            Image(systemName: "wrench.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(cause.fix)
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(symptom.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Symptom: Identifiable {
    let id = UUID()
    let name: String
    let part: PlantPart
    let icon: String
    let color: Color
    let possibleCauses: [Cause]
}

enum PlantPart: String, CaseIterable {
    case leaves = "Leaves"
    case stems = "Stems"
    case wholePlant = "Whole Plant"
    case pests = "Pests"
}

struct Cause: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let fix: String
}

#Preview {
    NavigationView {
        PlantDoctorView()
    }
}
