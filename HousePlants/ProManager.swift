import Foundation
import Combine
import StoreKit
import os

enum ProPurchaseError: LocalizedError {
    case productUnavailable

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "The Pro upgrade isn't available right now. Check your connection and try again."
        }
    }
}

/// Central authority for Pro tier status. Every feature gate reads from this singleton.
///
/// Source of truth is StoreKit 2: `Transaction.currentEntitlements` is checked on launch and
/// after every purchase/transaction update. The UserDefaults flag is only a cache so gated UI
/// renders correctly in the instant before the first entitlement check completes — it is
/// always overwritten by the StoreKit result and is never trusted on its own.
@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()

    /// Free-tier plant cap. Exceed this without Pro and the paywall shows.
    static let freePlantLimit = 5

    /// Non-consumable lifetime unlock. Must match the product configured in App Store Connect.
    static let productID = "RocketGames.HousePlants.pro.lifetime"

    private static let cacheKey = "pro_is_unlocked"

    @Published private(set) var isPro: Bool
    @Published private(set) var product: Product?
    @Published private(set) var purchaseInProgress = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: Self.cacheKey)

        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }

        Task { [weak self] in
            await self?.loadProductIfNeeded()
            await self?.refreshEntitlements()
        }
    }

    func loadProductIfNeeded() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            Logger.data.error("Pro product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Re-derives Pro status from the App Store's signed entitlements.
    func refreshEntitlements() async {
        var entitled = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.productID == Self.productID, transaction.revocationDate == nil {
                entitled = true
            }
        }
        setPro(entitled)
    }

    func purchase() async throws {
        guard !purchaseInProgress else { return }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        await loadProductIfNeeded()
        guard let product else { throw ProPurchaseError.productUnavailable }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            // payloadValue throws if the transaction fails StoreKit's signature verification.
            let transaction = try verification.payloadValue
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// Clears the local cache (testing / logout). The next entitlement refresh re-grants
    /// Pro if the App Store account still owns it.
    func revokePro() { setPro(false) }

    private func setPro(_ value: Bool) {
        if isPro != value { isPro = value }
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
