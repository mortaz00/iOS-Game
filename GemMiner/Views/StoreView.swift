import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var ads: AdsManager
    @EnvironmentObject var store: StoreManager

    @AppStorage("freeGemsAvailableAt") private var freeGemsAvailableAt: Double = 0
    @State private var now = Date()
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    freeSection
                    gemSpendSection
                    starterPackCard
                    iapSection
                    restoreButton
                }
                .padding()
            }
            .navigationTitle("Shop")
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(.stack)
        .onReceive(clock) { now = $0 }
    }

    // MARK: - Free (rewarded ads)

    private var freeGemsReady: Bool {
        now.timeIntervalSince1970 >= freeGemsAvailableAt
    }

    private var freeSection: some View {
        sectionCard("Free Rewards", icon: "gift.fill", color: .green) {
            adRow(
                title: "Free Gems",
                subtitle: freeGemsReady
                    ? "Watch an ad → \(Balance.freeGemsAmount) gems"
                    : "Next free gems in \((freeGemsAvailableAt - now.timeIntervalSince1970).shortDuration)",
                enabled: freeGemsReady
            ) {
                ads.showRewarded {
                    game.addGems(Balance.freeGemsAmount)
                    freeGemsAvailableAt = Date().timeIntervalSince1970 + Balance.freeGemsCooldown
                }
            }
            if !game.boostActive {
                adRow(title: "Production Boost",
                      subtitle: "Watch an ad → ×2 everything for 4h",
                      enabled: true) {
                    ads.showRewarded { game.activateBoost() }
                }
            }
        }
    }

    private func adRow(title: String, subtitle: String, enabled: Bool,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(enabled ? .green : .gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Spend gems

    private var gemSpendSection: some View {
        sectionCard("Time Warps (gems)", icon: "clock.arrow.circlepath", color: .pink) {
            gemRow(title: "2-hour Time Warp",
                   subtitle: "Instantly earn \((game.productionPerSecond * 7200).compact) crystals",
                   gems: 50) {
                game.earn(game.productionPerSecond * 7200)
            }
            gemRow(title: "8-hour Time Warp",
                   subtitle: "Instantly earn \((game.productionPerSecond * 28800).compact) crystals",
                   gems: 150) {
                game.earn(game.productionPerSecond * 28800)
            }
        }
    }

    private func gemRow(title: String, subtitle: String, gems: Int,
                        onPurchase: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button {
                if game.spendGems(gems) {
                    onPurchase()
                    Haptics.success()
                }
            } label: {
                Label("\(gems)", systemImage: "diamond.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(game.data.gems >= gems ? Color.pink : Color.gray.opacity(0.4)))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(game.data.gems < gems)
        }
    }

    // MARK: - Starter pack (limited time)

    private var starterPackExpiry: Date {
        game.data.firstLaunch.addingTimeInterval(Balance.starterPackWindow)
    }

    @ViewBuilder
    private var starterPackCard: some View {
        if !game.data.starterPackPurchased, now < starterPackExpiry {
            VStack(spacing: 8) {
                Text("⭐️ STARTER PACK ⭐️")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("300 gems + 24h of ×2 production")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text("Offer ends in \(starterPackExpiry.timeIntervalSince(now).shortDuration)")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                purchaseButton(for: .starterPack, fallbackTitle: "Buy Starter Pack")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.purple, .indigo],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
    }

    // MARK: - IAP

    private var iapSection: some View {
        sectionCard("Gem Packs & Upgrades", icon: "bag.fill", color: .blue) {
            if store.products.isEmpty {
                Text("Store unavailable. In Xcode, select the Products.storekit configuration in your scheme to test purchases locally.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.products.filter { $0.id != StoreManager.ProductID.starterPack.rawValue },
                        id: \.id) { product in
                    iapRow(product)
                }
            }
            if let error = store.lastError {
                Text(error).font(.caption2).foregroundColor(.red)
            }
        }
    }

    private func iapRow(_ product: Product) -> some View {
        let owned = isOwned(product)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline)
                Text(product.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button {
                Task { await store.purchase(product) }
            } label: {
                Text(owned ? "Owned" : product.displayPrice)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(owned ? Color.gray.opacity(0.4) : Color.blue))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(owned || store.purchaseInFlight)
        }
    }

    private func isOwned(_ product: Product) -> Bool {
        switch StoreManager.ProductID(rawValue: product.id) {
        case .removeAds: return game.data.hasRemoveAds
        case .doubler: return game.data.hasPermanentDoubler
        case .starterPack: return game.data.starterPackPurchased
        default: return false
        }
    }

    private func purchaseButton(for id: StoreManager.ProductID,
                                fallbackTitle: String) -> some View {
        Button {
            if let product = store.product(id) {
                Task { await store.purchase(product) }
            }
        } label: {
            Text(store.product(id)?.displayPrice ?? fallbackTitle)
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.yellow))
                .foregroundColor(.black)
        }
        .buttonStyle(.plain)
        .disabled(store.product(id) == nil || store.purchaseInFlight)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await store.restore() }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(_ title: String, icon: String, color: Color,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(color)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}
