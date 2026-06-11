import Foundation
import Combine

/// Central authority for Pro tier status. Every feature gate reads from this singleton.
///
/// TODO: Replace the UserDefaults stub with StoreKit 2 once products are configured in
/// App Store Connect. Implement Transaction.currentEntitlements to verify on launch and
/// set isPro accordingly.
final class ProManager: ObservableObject {
    static let shared = ProManager()

    /// Free-tier plant cap. Exceed this without Pro and the paywall shows.
    static let freePlantLimit = 5

    private static let defaultsKey = "pro_is_unlocked"

    @Published var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: Self.defaultsKey) }
    }

    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: Self.defaultsKey)
    }

    /// Revoke Pro (for testing / logout flows).
    func revokePro() { isPro = false }
}
