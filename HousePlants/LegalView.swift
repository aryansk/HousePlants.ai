import SwiftUI

private struct LegalSection {
    let heading: String
    let body: String
}

private struct LegalDocumentView: View {
    let title: String
    let lastUpdated: String
    let intro: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.claudeSerif(size: 28, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)

                Text("Last updated: \(lastUpdated)")
                    .font(.footnote)
                    .foregroundStyle(Color.claudeSecondaryText)

                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(Color.claudePrimaryText)

                ForEach(sections.indices, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sections[idx].heading)
                            .font(.claudeSerif(size: 18, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                        Text(sections[idx].body)
                            .font(.subheadline)
                            .foregroundStyle(Color.claudePrimaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }

                Divider().padding(.vertical, 8)

                Text("Questions? Contact us at support@houseplants.io")
                    .font(.footnote)
                    .foregroundStyle(Color.claudeSecondaryText)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.claudeBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(
            title: "Privacy Policy",
            lastUpdated: "May 18, 2026",
            intro: "HousePlants.ai (\"we\", \"our\", \"the app\") respects your privacy. This policy explains what data the app collects, how it is used, and the choices you have.",
            sections: [
                LegalSection(
                    heading: "Information We Collect",
                    body: """
                    • Profile data you provide: username, city, country, and an optional profile photo.
                    • Plant collection data: plants you add, watering history, journal entries, photos of your plants, and care preferences.
                    • Device data: notification preferences, app settings, and locally cached weather and location information used for care recommendations.
                    • Approximate location (city level) if you grant permission, used to tailor seasonal and climate-based care tips.
                    """
                ),
                LegalSection(
                    heading: "How We Use Your Information",
                    body: """
                    • To provide personalized plant care reminders, identification, and recommendations.
                    • To power AI features such as plant identification, health diagnosis, and skincare/toxicity checks. Photos you submit to these features may be processed by trusted third-party AI providers strictly to return a result to you.
                    • To improve the app and fix bugs.
                    We do not sell your personal information. We do not use your photos or content to train third-party AI models without your consent.
                    """
                ),
                LegalSection(
                    heading: "Data Storage",
                    body: """
                    Your profile, plant collection, journal, and photos are stored locally on your device. When iCloud sync is available, collection details, favorites, preferences, and streak data are mirrored through your private iCloud account; journal and profile photos remain on this device. Photos sent to AI features are transmitted over encrypted connections and are not retained by us after processing.
                    """
                ),
                LegalSection(
                    heading: "Third-Party Services",
                    body: """
                    The app may use the following categories of third-party services:
                    • AI providers (for plant identification and diagnosis).
                    • Weather data providers (for climate-aware recommendations).
                    • Apple services (iCloud, HealthKit/HomeKit where you opt in, Notifications).
                    These providers handle data under their own privacy terms.
                    """
                ),
                LegalSection(
                    heading: "Your Choices",
                    body: """
                    • You can edit or remove your profile information at any time in Profile → Edit Profile.
                    • You can delete all data stored by the app via Profile → Delete All My Data. This is irreversible.
                    • You can disable notifications, location, and photo permissions in iOS Settings.
                    """
                ),
                LegalSection(
                    heading: "Children's Privacy",
                    body: "The app is not directed at children under 13, and we do not knowingly collect personal information from children."
                ),
                LegalSection(
                    heading: "Changes To This Policy",
                    body: "We may update this policy. Material changes will be highlighted in-app or via a notification. Continued use after an update constitutes acceptance of the revised policy."
                ),
                LegalSection(
                    heading: "Contact",
                    body: "For questions or data requests, contact support@houseplants.io."
                )
            ]
        )
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(
            title: "Terms of Service",
            lastUpdated: "May 18, 2026",
            intro: "By using HousePlants.ai you agree to these Terms of Service. Please read them carefully.",
            sections: [
                LegalSection(
                    heading: "Use of the App",
                    body: "HousePlants.ai is provided for personal, non-commercial use to help you care for houseplants. You agree not to misuse the app, attempt to reverse-engineer it, or use it in violation of applicable law."
                ),
                LegalSection(
                    heading: "No Professional Advice",
                    body: "Content in the app — including plant identification, health diagnosis, toxicity information, and skincare suggestions — is provided for informational purposes only. It is not a substitute for advice from a qualified botanist, veterinarian, doctor, or other professional. Always verify critical information (such as pet toxicity or allergic reactions) with a professional."
                ),
                LegalSection(
                    heading: "AI Features",
                    body: "AI-generated results may be inaccurate or incomplete. You are responsible for evaluating results before acting on them. Do not rely on the app for any safety-critical decision."
                ),
                LegalSection(
                    heading: "User Content",
                    body: "You retain ownership of photos and content you create in the app. By using AI features that require uploading content, you grant us a limited right to process that content solely to deliver the requested result."
                ),
                LegalSection(
                    heading: "Subscriptions and Purchases",
                    body: "If the app offers paid features, purchases are processed by Apple and governed by the Apple Media Services Terms. Refunds are handled by Apple."
                ),
                LegalSection(
                    heading: "Disclaimer of Warranties",
                    body: "The app is provided \"as is\" without warranty of any kind. To the maximum extent permitted by law, we disclaim all warranties, express or implied."
                ),
                LegalSection(
                    heading: "Limitation of Liability",
                    body: "To the maximum extent permitted by law, we are not liable for indirect, incidental, or consequential damages arising from your use of the app, including damage to plants, pets, or property."
                ),
                LegalSection(
                    heading: "Termination",
                    body: "You may stop using the app at any time. We may suspend or discontinue the app or any features at our discretion."
                ),
                LegalSection(
                    heading: "Changes",
                    body: "We may update these Terms. Continued use of the app after an update constitutes acceptance of the revised Terms."
                ),
                LegalSection(
                    heading: "Contact",
                    body: "Questions about these Terms can be sent to support@houseplants.io."
                )
            ]
        )
    }
}

struct AcknowledgementsView: View {
    private struct Library: Identifiable {
        let id = UUID()
        let name: String
        let purpose: String
        let license: String
    }

    private let libraries: [Library] = [
        Library(name: "SwiftUI", purpose: "User interface framework", license: "Apple SDK License"),
        Library(name: "WeatherKit", purpose: "Climate-aware care recommendations", license: "Apple SDK License"),
        Library(name: "PhotosUI", purpose: "Profile and plant photo selection", license: "Apple SDK License")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Acknowledgements")
                    .font(.claudeSerif(size: 28, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)

                Text("HousePlants.ai is built with the help of the following technologies and open-source contributions. We are grateful to their authors.")
                    .font(.subheadline)
                    .foregroundStyle(Color.claudeSecondaryText)

                ForEach(libraries) { lib in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lib.name)
                            .font(.claudeSerif(size: 17, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                        Text(lib.purpose)
                            .font(.subheadline)
                            .foregroundStyle(Color.claudePrimaryText)
                        Text(lib.license)
                            .font(.caption)
                            .foregroundStyle(Color.claudeSecondaryText)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            .padding(20)
        }
        .background(Color.claudeBackground.ignoresSafeArea())
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Privacy") { NavigationStack { PrivacyPolicyView() } }
#Preview("Terms") { NavigationStack { TermsOfServiceView() } }
#Preview("Acks") { NavigationStack { AcknowledgementsView() } }
