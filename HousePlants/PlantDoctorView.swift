import SwiftUI

struct PlantDoctorView: View {
    @State private var showInfoSheet = false
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
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Plant Doctor",
                    subtitle: "Diagnose and treat your plants",
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
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                        
                        // Hero Diagnostic Wizard Link
                        NavigationLink(destination: DiagnosticWizardView(allSymptoms: symptoms)) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Discovery Wizard")
                                        .font(.claudeSerif(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Step-by-step assistance to identify issues")
                                        .font(.claudeSans(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(24)
                            .background(
                                LinearGradient(colors: [Color.purple, Color(hex: "9D50BB")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(24)
                            .shadow(color: Color.purple.opacity(0.2), radius: 15, x: 0, y: 10)
                        }
                        .buttonStyle(InteractiveCardButtonStyle())
                        .padding(.horizontal, 20)
                        
                        // Browse Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Browse by Symptom")
                                .font(.claudeSans(size: 13, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .textCase(.uppercase)
                                .tracking(1.5)
                            
                            VStack(spacing: 12) {
                                ForEach(PlantPart.allCases, id: \.self) { part in
                                    let partSymptoms = symptoms.filter { $0.part == part }
                                    if !partSymptoms.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: partIcon(for: part))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.claudeSecondaryText)
                                                Text(part.rawValue)
                                                    .font(.claudeSans(size: 11, weight: .bold))
                                                    .foregroundColor(.claudeSecondaryText)
                                            }
                                            
                                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                                ForEach(partSymptoms) { symptom in
                                                    NavigationLink(destination: SymptomDetailView(symptom: symptom)) {
                                                        VStack(alignment: .leading, spacing: 12) {
                                                            Image(systemName: symptom.icon)
                                                                .font(.system(size: 20))
                                                                .foregroundColor(symptom.color)
                                                            
                                                            Text(symptom.name)
                                                                .font(.claudeSans(size: 14, weight: .bold))
                                                                .foregroundColor(.claudePrimaryText)
                                                                .multilineTextAlignment(.leading)
                                                        }
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .padding(16)
                                                        .background(Color.claudeSecondaryBackground)
                                                        .cornerRadius(18)
                                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.claudeBorder, lineWidth: 1))
                                                    }
                                                    .buttonStyle(InteractiveCardButtonStyle())
                                                }
                                            }
                                        }
                                        .padding(.bottom, 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        }
                        .frame(width: geometry.size.width)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            PlantDoctorInfoSheet()
        }
    }
    
    func partIcon(for part: PlantPart) -> String {
        switch part {
        case .leaves: return "leaf.fill"
        case .stems: return "laurel.leading"
        case .wholePlant: return "tree.fill"
        case .pests: return "ant.fill"
        }
    }
}

// MARK: - Diagnostic Wizard
struct DiagnosticWizardView: View {
    @Environment(\.dismiss) var dismiss
    let allSymptoms: [Symptom]
    @State private var selectedPart: PlantPart?
    
    var filteredSymptoms: [Symptom] {
        guard let selectedPart else { return [] }
        return allSymptoms.filter { $0.part == selectedPart }
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.claudeSecondaryText)
                            .padding(10)
                            .background(Circle().fill(Color.claudeSecondaryBackground))
                    }
                    Spacer()
                    Text("DIAGNOSTIC WIZARD")
                        .font(.claudeSans(size: 12, weight: .bold))
                        .foregroundColor(.claudeSecondaryText)
                        .tracking(1.5)
                    Spacer()
                    Spacer().frame(width: 34) // Balance
                }
                .padding(24)
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 40) {
                        VStack(spacing: 12) {
                            Text("Where is the sign?")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            Text("Selective diagnosis for better accuracy")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            PartSelectionCard(part: .leaves, icon: "leaf.fill", color: .green, selected: selectedPart == .leaves) {
                                withAnimation(.spring()) { selectedPart = .leaves }
                            }
                            PartSelectionCard(part: .stems, icon: "laurel.leading", color: .brown, selected: selectedPart == .stems) {
                                withAnimation(.spring()) { selectedPart = .stems }
                            }
                            PartSelectionCard(part: .wholePlant, icon: "tree.fill", color: .orange, selected: selectedPart == .wholePlant) {
                                withAnimation(.spring()) { selectedPart = .wholePlant }
                            }
                            PartSelectionCard(part: .pests, icon: "ant.fill", color: .red, selected: selectedPart == .pests) {
                                withAnimation(.spring()) { selectedPart = .pests }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if selectedPart != nil {
                            VStack(alignment: .leading, spacing: 20) {
                                Divider()
                                
                                Text("SELECT OBSERVATION")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(2)
                                
                                VStack(spacing: 12) {
                                    ForEach(filteredSymptoms) { symptom in
                                        NavigationLink(destination: SymptomDetailView(symptom: symptom)) {
                                            HStack(spacing: 16) {
                                                Image(systemName: symptom.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(symptom.color)
                                                    .frame(width: 44, height: 44)
                                                    .background(symptom.color.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                Text(symptom.name)
                                                    .font(.claudeSans(size: 16, weight: .bold))
                                                    .foregroundColor(.claudePrimaryText)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.claudeBorder)
                                            }
                                            .padding(12)
                                            .background(Color.claudeSecondaryBackground)
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                                        }
                                        .buttonStyle(InteractiveCardButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
            .background(selected ? color : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: selected ? color.opacity(0.4) : Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.clear : color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Models & Detail View

struct SymptomDetailView: View {
    @Environment(\.dismiss) var dismiss
    let symptom: Symptom
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Back")
                                .font(.claudeSans(size: 14, weight: .medium))
                        }
                        .foregroundColor(.claudePrimaryText)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                        // Symptom Title Banner
                        HStack(spacing: 14) {
                            Image(systemName: symptom.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(symptom.color)
                            Text(symptom.name)
                                .font(.claudeSerif(size: 30, weight: .bold))
                                .foregroundStyle(Color.claudePrimaryText)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(symptom.color.opacity(0.08))
                        )
                        .padding(.horizontal, 20)
                        
                        // Section Label
                        Text("Possible Causes")
                            .font(.claudeSans(size: 11, weight: .bold))
                            .foregroundColor(.claudeSecondaryText)
                            .textCase(.uppercase)
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        // Cause Cards
                        VStack(spacing: 16) {
                            ForEach(symptom.possibleCauses) { cause in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(cause.title)
                                        .font(.claudeSans(size: 18, weight: .bold))
                                        .foregroundColor(.claudePrimaryText)
                                    
                                    Text(cause.description)
                                        .font(.claudeSans(size: 15))
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.orange)
                                        Text(cause.fix)
                                            .font(.claudeSans(size: 14))
                                            .foregroundColor(.claudePrimaryText)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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

// MARK: - Info Sheet View
struct PlantDoctorInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Plant Doctor Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Identify problems by browsing symptoms or using the guided diagnostic wizard to narrow down exactly what's ailing your plant.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "wand.and.stars", title: "Diagnostic Wizard", text: "Start by selecting the affected plant part — leaves, stems, or whole plant — then match visual symptoms for an accurate diagnosis.", color: .purple)
                            
                            InfoRow(icon: "leaf.fill", title: "Symptom Browser", text: "Browse the full symptom library organized by plant part. Each symptom lists possible causes and actionable treatment steps.", color: .green)
                            
                            InfoRow(icon: "ant.fill", title: "Pest Identification", text: "From spider mites to fungus gnats, learn to identify common houseplant pests and get effective, organic treatment advice.", color: .red)
                            
                            InfoRow(icon: "lightbulb.fill", title: "Treatment Tips", text: "Every diagnosis includes a recommended fix with specific steps you can take immediately to save your plant.", color: .orange)
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
        PlantDoctorView()
    }
}
