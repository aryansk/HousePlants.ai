import SwiftUI

struct PlantDoctorView: View {
    @State private var showInfoSheet = false
    // Expanded Symptom Database
    // Expanded Symptom Database
    let symptoms = [
        // Leaves
        Symptom(name: "Yellow Leaves", part: .leaves, icon: "leaf.arrow.triangle.pullpath", color: .yellow, possibleCauses: [
            Cause(title: "Overwatering", description: "Soil is constantly wet. Roots may be rotting and unable to function.", fix: "Let soil dry out completely. Improve drainage. Check for root rot."),
            Cause(title: "Underwatering", description: "Leaves are crispy and dry. The plant is sacrificing older leaves for survival.", fix: "Water thoroughly until water drains out of the bottom."),
            Cause(title: "Nutrient Deficiency", description: "Yellowing between veins (Chlorosis) often means iron or magnesium deficiency.", fix: "Apply balanced fertilizer or specific micronutrients."),
            Cause(title: "Natural Shedding", description: "Older bottom leaves yellowing naturally as the plant grows.", fix: "Normal process. Prune once fully yellow to conserve plant energy."),
            Cause(title: "Poor Lighting", description: "Insufficient light prevents chlorophyll production.", fix: "Gradually move to a brighter location with indirect light.")
        ]),
        Symptom(name: "Brown Tips/Edges", part: .leaves, icon: "leaf.fill", color: .brown, possibleCauses: [
            Cause(title: "Low Humidity", description: "Dry indoor air is pulling moisture from leaf tips faster than roots can supply it.", fix: "Use a humidifier, pebble tray, or group plants together."),
            Cause(title: "Mineral Build-up", description: "Tap water chemicals (fluoride/chlorine) or fertilizer salts accumulating.", fix: "Use distilled, rain, or filtered water. Flush soil thoroughly."),
            Cause(title: "Sunburn", description: "Direct sunlight through glass magnifying heat and scorching edges.", fix: "Move away from direct midday sun or use a sheer curtain."),
            Cause(title: "Boric Acid Toxicity", description: "Rare but possible from certain fertilizers or soil supplements.", fix: "Flush soil with large amounts of clean water.")
        ]),
        Symptom(name: "White Spots/Powder", part: .leaves, icon: "cloud.snow.fill", color: .gray, possibleCauses: [
            Cause(title: "Powdery Mildew", description: "A common fungal infection that looks like a dusting of flour.", fix: "Remove affected leaves. Improve air circulation. Use Neem Oil."),
            Cause(title: "Hard Water Residue", description: "Mineral spots left behind after tap water evaporates from leaves.", fix: "Wipe leaves with a damp cloth. Avoid overhead watering."),
            Cause(title: "Early Pest Activity", description: "Small white clusters could be early mealybug or whitefly nests.", fix: "Inspect closely. Wipe with alcohol and treat with insecticidal soap.")
        ]),
        Symptom(name: "Curling/Distorted Leaves", part: .leaves, icon: "arrow.turn.right.up", color: .green, possibleCauses: [
            Cause(title: "Heat/Light Stress", description: "Plant curls leaves to reduce surface area and moisture loss in high heat.", fix: "Move to a cooler spot and check moisture levels."),
            Cause(title: "Thrip/Pest Damage", description: "Sap-sucking pests cause new growth to emerge twisted or curled.", fix: "Inspect new growth with a magnifying glass. Treat with Neem Oil."),
            Cause(title: "Extreme Underwatering", description: "Loss of turgor pressure causes leaves to curl and sag.", fix: "Deep water immediately (bottom watering recommended).")
        ]),
        Symptom(name: "Black/Dark Spots", part: .leaves, icon: "circle.dotted", color: .black, possibleCauses: [
            Cause(title: "Fungal Leaf Spot", description: "Black spots with yellow halos typically indicate a fungal pathogen.", fix: "Remove infected leaves. Apply copper fungicide. Keep foliage dry."),
            Cause(title: "Bacterial Blight", description: "Spreading dark, water-soaked spots.", fix: "Prune infected stems. Avoid misting. Improve ventilation."),
            Cause(title: "Cold Damage", description: "Soft, dark patches from exposure to freezing temperatures.", fix: "Move to a warm area. Do not prune until new growth appears.")
        ]),
        Symptom(name: "Sticky 'Honeydew'", part: .leaves, icon: "drop.fill", color: .blue, possibleCauses: [
            Cause(title: "Scale or Aphids", description: "Pests excrete a sticky substance called honeydew as they feed.", fix: "Inspect stems and leaf undersides. Wash plant and apply Neem Oil."),
            Cause(title: "Guttation", description: "Normal moisture release from leaves, though sticky gutation can happen.", fix: "Wipe with a damp cloth. Reduce watering frequency slightly.")
        ]),
        
        // Stems
        Symptom(name: "Mushy/Soft Stems", part: .stems, icon: "drop.triangle.fill", color: .black, possibleCauses: [
            Cause(title: "Root & Stem Rot", description: "Overwatering has caused rot to progress from roots into the main stem.", fix: "Immediate emergency repotting. Cut away all mushy parts."),
            Cause(title: "Bacterial Soft Rot", description: "Pathogens entering through wounds in the stem.", fix: "Prune well below the soft area with sterilized shears.")
        ]),
        Symptom(name: "Leggy/Stretched", part: .stems, icon: "arrow.up.and.down", color: .green, possibleCauses: [
            Cause(title: "Etiolation (Low Light)", description: "The plant is rapidly growing 'weak' stems to reach for more light.", fix: "Move to a much brighter location. Prune leggy growth."),
            Cause(title: "Incorrect Temperature", description: "Too much warmth combined with low light causes rapid, weak growth.", fix: "Lower the ambient temperature or increase light exposure.")
        ]),
        Symptom(name: "White Fuzz on Stems", part: .stems, icon: "fossil.shell.fill", color: .gray, possibleCauses: [
            Cause(title: "Mealybugs", description: "Cottony masses usually found in stem crothes and nodes.", fix: "Remove with rubbing alcohol. Treat with systemic insecticide."),
            Cause(title: "Sooty Mold", description: "A black/gray fungus that grows on sticky pest residue.", fix: "Clean the plant and treat for the underlying pest infestation.")
        ]),
        Symptom(name: "Woody/Corky Stems", part: .stems, icon: "shield.fill", color: .brown, possibleCauses: [
            Cause(title: "Lignification", description: "Natural aging where older stems become bark-like for support.", fix: "Normal behavior for many older plants. No treatment needed."),
            Cause(title: "Corking", description: "Scarring from previous pest damage or environmental stress.", fix: "Aesthetic change only. Ensure stable conditions moving forward.")
        ]),
        
        // Whole Plant
        Symptom(name: "Drooping/Wilting", part: .wholePlant, icon: "arrow.down", color: .green, possibleCauses: [
            Cause(title: "Critical Thirst", description: "The most common cause. Soil is bone dry and leaves have collapsed.", fix: "Water thoroughly. Consider bottom-soaking the pot."),
            Cause(title: "Advanced Root Rot", description: "Roots are so damaged they can no longer absorb water, causing wilt.", fix: "If soil is wet but plant is wilting, check roots immediately."),
            Cause(title: "Temperature Stress", description: "Sudden hot or cold drafts cause cellular collapse.", fix: "Move to a stable environment away from AC or heating vents.")
        ]),
        Symptom(name: "Stunted Growth", part: .wholePlant, icon: "arrow.down.to.line", color: .orange, possibleCauses: [
            Cause(title: "Root Bound", description: "Roots have filled the pot, leaving no room for new growth or nutrients.", fix: "Repot into a container 1-2 inches larger in diameter."),
            Cause(title: "Winter Dormancy", description: "Many plants stop growing during cooler months with shorter days.", fix: "Reduce watering and stop fertilizing until spring growth resumes."),
            Cause(title: "Nutrient Exhaustion", description: "Soil has been depleted of essential minerals over several years.", fix: "Repot with fresh soil or begin a regular fertilization schedule.")
        ]),
        Symptom(name: "Sudden Leaf Drop", part: .wholePlant, icon: "arrow.down.square", color: .red, possibleCauses: [
            Cause(title: "Environmental Shock", description: "Major changes in light, temperature, or humidity cause stress.", fix: "Keep conditions consistent. Avoid moving the plant frequently."),
            Cause(title: "Chlorine Sensitivity", description: "Some sensitive plants drop leaves when watered with chlorinated tap water.", fix: "Let tap water sit out for 24 hours or use distilled water.")
        ]),
        
        // Pests (Specific)
        Symptom(name: "Fine Webbing", part: .pests, icon: "sparkles", color: .gray, possibleCauses: [
            Cause(title: "Spider Mites", description: "Microscopic mites that thrive in dry conditions and spin tiny webs.", fix: "Isolate. Shower foliage. Apply Neem Oil or Miticide weekly.")
        ]),
        Symptom(name: "Hard Brown Bumps", part: .pests, icon: "shield.lefthalf.filled", color: .brown, possibleCauses: [
            Cause(title: "Scale Insects", description: "Armored pests that look like part of the plant but don't move.", fix: "Scrape off with a dull knife or brush with alcohol. Use Neem Oil.")
        ]),
        Symptom(name: "Tiny Flying Traps", part: .pests, icon: "tornado", color: .black, possibleCauses: [
            Cause(title: "Fungus Gnats", description: "Tiny black flies that emerge from moist soil surface.", fix: "Let top 2 inches of soil dry completely. Use yellow sticky traps.")
        ]),
        Symptom(name: "Cottony Clusters", part: .pests, icon: "cloud.fill", color: .white, possibleCauses: [
            Cause(title: "Mealybugs", description: "White, waxy insects that hide in crevices and suck plant sap.", fix: "Dab with alcohol. Spray with insecticidal soap every 5 days.")
        ]),
        Symptom(name: "Silver/Grey Scars", part: .pests, icon: "bandage.fill", color: .gray, possibleCauses: [
            Cause(title: "Thrips", description: "Very small, slender insects that rasp leaf surfaces leaving scars.", fix: "Use blue sticky traps. Spray with Spinosad or Systemic granules.")
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text("Step-by-step assistance to identify issues")
                                        .font(.claudeSans(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
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
                                withMotion(Motion.bouncy) { selectedPart = .leaves }
                            }
                            PartSelectionCard(part: .stems, icon: "laurel.leading", color: .brown, selected: selectedPart == .stems) {
                                withMotion(Motion.bouncy) { selectedPart = .stems }
                            }
                            PartSelectionCard(part: .wholePlant, icon: "tree.fill", color: .orange, selected: selectedPart == .wholePlant) {
                                withMotion(Motion.bouncy) { selectedPart = .wholePlant }
                            }
                            PartSelectionCard(part: .pests, icon: "ant.fill", color: .red, selected: selectedPart == .pests) {
                                withMotion(Motion.bouncy) { selectedPart = .pests }
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
                                    ForEach(Array(filteredSymptoms.enumerated()), id: \.element.id) { index, symptom in
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
                                        .staggeredAppear(index: index, step: 0.04, cap: 8, offset: 10, tilt: 0)
                                    }
                                }
                                // Re-keyed per body part so switching selection re-deals the
                                // symptom list instead of swapping rows silently.
                                .id(selectedPart)
                            }
                            .padding(.horizontal, 20)
                            .transition(.popOpen)
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
                    // The chosen part's glyph grows and tips, so the selected card is
                    // obvious from the corner of the eye as well as by colour.
                    .scaleEffect(selected ? 1.14 : 1)
                    .rotationEffect(.degrees(selected ? -7 : 0))

                Text(part.rawValue)
                    .font(.headline)
                    .foregroundStyle(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selected ? color : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: selected ? color.opacity(0.4) : Color.primary.opacity(0.05), radius: selected ? 10 : 5, x: 0, y: selected ? 4 : 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.clear : color.opacity(0.2), lineWidth: 1)
            )
            .motion(Motion.playful, value: selected)
        }
        .buttonStyle(SquishButtonStyle(scale: 0.94, rotation: -2, haptic: false))
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
                                .minimumScaleFactor(0.6)
                                .lineLimit(2)
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
                            InfoRow(icon: "wand.and.stars", title: "Diagnostic Wizard", text: "Start by selecting the affected plant part — leaves, stems, whole plant, or pests — then match visual symptoms for an accurate diagnosis.", color: .purple)
                            
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
