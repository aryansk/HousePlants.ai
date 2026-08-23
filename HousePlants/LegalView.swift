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

                Text("Questions? Contact us at indiehouseapps@gmail.com")
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
            lastUpdated: "August 14, 2026",
            intro: "HousePlants.ai (\"we\", \"our\", \"the app\") is a local-first plant-care app. We do not operate user accounts or sell personal information. This policy explains the optional data flows used by the app.",
            sections: [
                LegalSection(
                    heading: "Information We Collect",
                    body: """
                    • Information you enter in the app, such as a username, city, plant collection, watering history, journal entries, care preferences, and optional photos. This information is stored on your device.
                    • A plant photo only when you choose to use Plant Identifier. The selected image is sent over HTTPS to the Pl@ntNet service to return identification results.
                    • Approximate location only when you grant Location permission and use climate-aware care. The app uses it to request a weather forecast from Apple WeatherKit.
                    """
                ),
                LegalSection(
                    heading: "How We Use Your Information",
                    body: """
                    • To provide plant-care reminders, local recommendations, health calculations, and journal features.
                    • To return plant identification results when you submit a photo to Pl@ntNet. Pl@ntNet processes that request under its own terms and privacy policy.
                    • To calculate climate-aware care adjustments from an Apple WeatherKit forecast when you enable location access.
                    • To synchronize a limited set of plant state and preferences through Apple's private iCloud key-value store when iCloud is available.
                    We do not use analytics or advertising tracking, and we do not sell your personal information.
                    """
                ),
                LegalSection(
                    heading: "Data Storage",
                    body: """
                    Your profile, plant collection, journal, and photos are stored locally on your device. When iCloud sync is available, selected collection details, favorites, preferences, and streak data are mirrored through your private iCloud account; journal and profile photos remain on this device. The Pl@ntNet API key you provide is stored in the iOS Keychain. Photos sent to Pl@ntNet are transmitted over an encrypted connection and are handled under Pl@ntNet's own privacy terms.
                    """
                ),
                LegalSection(
                    heading: "Third-Party Services",
                    body: """
                    The app may use:
                    • Pl@ntNet, when you request plant identification. You provide and control the API key used for this request.
                    • Apple WeatherKit, when you enable location access and use climate-aware recommendations.
                    • Apple services such as iCloud key-value storage, HomeKit, Calendar, and Notifications when you opt in or use the related feature.
                    These providers handle data under their own privacy terms and service agreements.
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
                    body: "For questions or data requests, contact indiehouseapps@gmail.com."
                )
            ]
        )
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(
            title: "Terms of Service",
            lastUpdated: "August 14, 2026",
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
                    body: "Questions about these Terms can be sent to indiehouseapps@gmail.com."
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
