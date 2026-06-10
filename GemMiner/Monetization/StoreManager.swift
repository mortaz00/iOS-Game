import Foundation
import StoreKit

/// StoreKit 2 wrapper: loads products, processes purchases, grants rewards,
/// and keeps non-consumable entitlements (remove ads, permanent 2x) in sync.
@MainActor
final class StoreManager: ObservableObject {
    enum ProductID: String, CaseIterable {
        case gemsFistful = "com.example.gemminer.gems.fistful"   // 120 gems
        case gemsSack    = "com.example.gemminer.gems.sack"      // 700 gems
        case gemsVault   = "com.example.gemminer.gems.vault"     // 4000 gems
        case starterPack = "com.example.gemminer.starterpack"
        case removeAds   = "com.example.gemminer.removeads"
        case doubler     = "com.example.gemminer.permanent2x"
    }

    @Published private(set) var products: [Product] = []
    @Published var purchaseInFlight = false
    @Published var lastError: String?

    private weak var game: GameState?
    private var updatesTask: Task<Void, Never>?

    func start(game: GameState) {
        guard self.game == nil else { return }
        self.game = game
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func product(_ id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func loadProducts() async {
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            lastError = "Store unavailable: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    grant(productID: transaction.productID)
                    await transaction.finish()
                    Haptics.success()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                grant(productID: transaction.productID, isEntitlementRefresh: true)
            }
        }
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = update {
            grant(productID: transaction.productID)
            await transaction.finish()
        }
    }

    /// `isEntitlementRefresh` re-applies flags for non-consumables without
    /// re-granting one-time bonuses like gems.
    private func grant(productID: String, isEntitlementRefresh: Bool = false) {
        guard let game, let id = ProductID(rawValue: productID) else { return }
        switch id {
        case .gemsFistful:
            if !isEntitlementRefresh { game.addGems(120) }
        case .gemsSack:
            if !isEntitlementRefresh { game.addGems(700) }
        case .gemsVault:
            if !isEntitlementRefresh { game.addGems(4000) }
        case .starterPack:
            game.data.starterPackPurchased = true
            if !isEntitlementRefresh {
                game.addGems(300)
                game.activateBoost(duration: 24 * 3600)
            }
        case .removeAds:
            game.data.hasRemoveAds = true
        case .doubler:
            game.data.hasPermanentDoubler = true
        }
        game.save()
    }
}
