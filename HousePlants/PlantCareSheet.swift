import SwiftUI

struct PlantCareSheet: View {
    let plant: Plant
    @EnvironmentObject var dataLoader: DataLoader
    @Environment(\.dismiss) var dismiss
    
    @State private var nickname: String = ""
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var healthScore: Double = 80
    @State private var showWateredMessage = false
    
    var myPlant: MyPlant? {
        dataLoader.userProfile?.myJungle.first(where: { $0.plantId == plant.id })
    }
    
    var wateringHistory: [Date] {
        guard let history = myPlant?.wateringHistory else { return [] }
        return history.compactMap { ISO8601DateFormatter().date(from: $0) }
            .sorted(by: >)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Plant Image
                    ZStack {
                        if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color.gray.opacity(0.1)
                                }
                            }
                        } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                            Image(String(imageName))
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.green.opacity(0.2)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        Button(action: {
                            dataLoader.waterPlant(plantId: plant.id)
                            withAnimation {
                                showWateredMessage = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showWateredMessage = false
                            }
                        }) {
                            Label("Water Now", systemImage: "drop.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                        
                        Button(action: {
                            dataLoader.updatePlantHealth(plantId: plant.id, healthScore: Int(healthScore))
                        }) {
                            Label("Update Health", systemImage: "heart.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                    
                    if showWateredMessage {
                        Text("✓ Plant watered!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    // Nickname
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nickname")
                            .font(.headline)
                        TextField("Enter nickname", text: $nickname)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                dataLoader.updatePlantNickname(plantId: plant.id, nickname: nickname)
                            }
                    }
                    .padding(.horizontal)
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location in Home")
                            .font(.headline)
                        TextField("e.g., Living Room", text: $location)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                dataLoader.updatePlantLocation(plantId: plant.id, location: location)
                            }
                    }
                    .padding(.horizontal)
                    
                    // Health Score
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Health Score")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(healthScore))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(healthColor)
                        }
                        
                        Slider(value: $healthScore, in: 0...100, step: 5)
                            .tint(healthColor)
                        
                        HStack {
                            Text("Poor")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Excellent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: notes) { oldValue, newValue in
                                dataLoader.updatePlantNotes(plantId: plant.id, notes: newValue)
                            }
                    }
                    .padding(.horizontal)
                    
                    // Watering History
                    if !wateringHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Watering History")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(wateringHistory.prefix(5), id: \.self) { date in
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(.blue)
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                    Spacer()
                                    Text(timeAgo(from: date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Care Guide Quick Reference
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Care Guide")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            CareInfoRow(icon: "sun.max.fill", title: "Light", value: plant.careGuide.light, color: .orange)
                            CareInfoRow(icon: "drop.fill", title: "Water", value: plant.careGuide.water, color: .blue)
                            CareInfoRow(icon: "humidity.fill", title: "Humidity", value: plant.careGuide.humidity, color: .cyan)
                            CareInfoRow(icon: "thermometer", title: "Temperature", value: plant.careGuide.temperatureRange, color: .red)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: "F2F7F2"))
            .navigationTitle(plant.commonName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let myPlant = myPlant {
                nickname = myPlant.nickname
                notes = myPlant.notes ?? ""
                location = myPlant.locationInHome ?? ""
                healthScore = Double(myPlant.healthScore ?? 80)
            }
        }
    }
    
    var healthColor: Color {
        let health = Int(healthScore)
        if health >= 80 { return .green }
        else if health >= 60 { return .yellow }
        else if health >= 40 { return .orange }
        else { return .red }
    }
    
    func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s") ago"
        }
    }
}

struct CareInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
}
