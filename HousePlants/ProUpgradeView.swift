import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var proManager = ProManager.shared
    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0D1B2A"), Color(hex: "112233"), Color(hex: "0A3D2B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        heroSection
                        featuresSection
                        ctaSection
                    }
                    .padding(.bottom, 48)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .alert("Purchase Failed", isPresented: Binding(
                get: { purchaseError != nil },
                set: { if !$0 { purchaseError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseError ?? "")
            }
            .task { await proManager.loadProductIfNeeded() }
            .onChange(of: proManager.isPro) { _, nowPro in
                if nowPro { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(Color.green.opacity(0.25), lineWidth: 1)
                    .frame(width: 148, height: 148)
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "2ECC71"), .green],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.5), radius: 24)
            }
            .padding(.top, 36)

            Text("HousePlants Pro")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("The complete toolkit for serious plant parents.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ProFeatureRow(
                icon: "leaf.fill", color: .green,
                title: "Unlimited Plants",
                detail: "Free tier caps at \(ProManager.freePlantLimit). Pro removes the limit entirely."
            )
            ProFeatureRow(
                icon: "camera.viewfinder", color: Color(hex: "16A085"),
                title: "Instant Plant ID",
                detail: "Bundled Pl@ntNet access — no API key setup, just point and identify."
            )
            ProFeatureRow(
                icon: "bell.badge.fill", color: .orange,
                title: "Advanced Reminders",
                detail: "Fertilizer, misting, repotting & bloom countdown notifications."
            )
            ProFeatureRow(
                icon: "doc.richtext.fill", color: .pink,
                title: "Sitter Card Templates",
                detail: "Rich or minimal PDF design for your plant sitter care cards."
            )
            ProFeatureRow(
                icon: "sensor.tag.radiowaves.forward.fill", color: .cyan,
                title: "HomeKit Automation",
                detail: "Alerts when sensors detect bad conditions for your plants."
            )
            ProFeatureRow(
                icon: "calendar.badge.plus", color: .blue,
                title: "Apple Calendar Sync",
                detail: "Export repotting, fertilising and bloom events automatically."
            )
            ProFeatureRow(
                icon: "chart.xyaxis.line", color: .purple,
                title: "Growth Analytics",
                detail: "Health timeline, watering adherence & journal stats per plant."
            )
        }
        .padding(.horizontal, 20)
    }

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button(action: {
                Task {
                    do {
                        try await proManager.purchase()
                    } catch {
                        purchaseError = error.localizedDescription
                    }
                }
            }) {
                HStack(spacing: 10) {
                    if proManager.purchaseInProgress {
                        ProgressView().tint(.black)
                    }
                    Text(upgradeButtonTitle)
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "2ECC71"), Color(hex: "27AE60")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.45), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(proManager.purchaseInProgress)
            .padding(.horizontal, 20)

            Button(action: {
                Task { await proManager.restorePurchases() }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Text("One-time purchase. Billed through your App Store account.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var upgradeButtonTitle: String {
        if let price = proManager.product?.displayPrice {
            return "Upgrade to Pro — \(price)"
        }
        return "Upgrade to Pro"
    }
}

// MARK: - Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green.opacity(0.65))
                .padding(.top, 2)
        }
        .padding(14)
        .background(.white.opacity(0.05))
        .cornerRadius(14)
    }
}

#Preview {
    ProUpgradeView()
}
