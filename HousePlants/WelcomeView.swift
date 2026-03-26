import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var username: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var showError: Bool = false
    @Binding var isCompleted: Bool
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.3), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo/Icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    Text("🌿")
                        .font(.system(size: 60))
                }
                .padding(.bottom, 20)
                
                // Title
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("HousePlants")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.bottom, 10)
                
                Text("Your personal plant care companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 40)
                
                // Input Form
                VStack(spacing: 20) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should we call you?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        TextField("Enter your name", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    // City Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where are you located?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 12) {
                            TextField("City", text: $city)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            TextField("Country", text: $country)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    if showError {
                        Text("Please fill in all fields")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // Get Started Button
                Button(action: {
                    if username.isEmpty || city.isEmpty || country.isEmpty {
                        withAnimation {
                            showError = true
                        }
                    } else {
                        saveUserInfo()
                        withAnimation(.spring()) {
                            isCompleted = true
                        }
                    }
                }) {
                    HStack {
                        Text("Get Started")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                Spacer()
            }
        }
    }
    
    func saveUserInfo() {
        // Update user profile in DataLoader
        if var profile = dataLoader.userProfile {
            profile.username = username
            profile.locationSettings.city = city
            profile.locationSettings.country = country
            dataLoader.userProfile = profile
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(city, forKey: "city")
        UserDefaults.standard.set(country, forKey: "country")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    WelcomeView(isCompleted: .constant(false))
        .environmentObject(DataLoader())
}
