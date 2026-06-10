import Foundation

/// Every tunable number in the game lives here so the economy can be
/// rebalanced without touching gameplay code.
enum Balance {
    // Generators
    static let costGrowth = 1.15            // classic idle-game cost curve
    static let milestoneEvery = 25          // every N levels a generator doubles output

    // Tapping
    static let tapBase = 1.0
    static let tapGrowth = 1.6
    static let tapCostBase = 25.0
    static let tapCostGrowth = 2.2
    static let critChance = 0.05            // variable-ratio reward: 5% chance of a crit
    static let critMultiplier = 10.0

    // Offline earnings (appointment mechanic)
    static let offlineEfficiency = 0.5      // offline earns 50% of live rate...
    static let offlineCapHours = 8.0        // ...capped, so players come back

    // Prestige (long-term goal / renewal loop)
    static let prestigeUnlock = 1_000_000.0
    static let shardBonusPerShard = 0.10    // +10% production per shard, forever

    // Boosts
    static let adBoostMultiplier = 2.0
    static let adBoostDuration: TimeInterval = 4 * 3600
    static let frenzyMultiplier = 7.0
    static let frenzyDuration: TimeInterval = 77

    // Comet event (random surprise reward)
    static let cometFirstDelay: ClosedRange<Double> = 25...60
    static let cometDelay: ClosedRange<Double> = 90...240
    static let cometLifetime: TimeInterval = 12
    static let cometGems = 15

    // Free gems via rewarded ad
    static let freeGemsAmount = 25
    static let freeGemsCooldown: TimeInterval = 15 * 60

    // Starter pack scarcity window
    static let starterPackWindow: TimeInterval = 48 * 3600
}

struct GeneratorDef: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let baseCost: Double
    let baseRate: Double

    static let all: [GeneratorDef] = [
        .init(id: 0, name: "Pickaxe Gnome", icon: "hammer.fill", baseCost: 15, baseRate: 0.5),
        .init(id: 1, name: "Mine Cart", icon: "cart.fill", baseCost: 120, baseRate: 4),
        .init(id: 2, name: "Drill Rig", icon: "gearshape.2.fill", baseCost: 1_500, baseRate: 35),
        .init(id: 3, name: "Crystal Golem", icon: "figure.strengthtraining.traditional", baseCost: 25_000, baseRate: 320),
        .init(id: 4, name: "Laser Excavator", icon: "bolt.fill", baseCost: 400_000, baseRate: 3_000),
        .init(id: 5, name: "Quantum Tunneler", icon: "atom", baseCost: 8_000_000, baseRate: 30_000),
        .init(id: 6, name: "Black Hole Siphon", icon: "circle.circle.fill", baseCost: 150_000_000, baseRate: 350_000),
    ]
}
