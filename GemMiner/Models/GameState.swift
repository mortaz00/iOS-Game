import Foundation
import SwiftUI

/// Everything that gets persisted between sessions.
struct SaveData: Codable {
    var crystals: Double = 0
    var gems: Int = 25
    var lifetimeCrystals: Double = 0
    var runCrystals: Double = 0
    var generatorLevels: [Int: Int] = [:]
    var tapLevel: Int = 1
    var prestigeShards: Int = 0
    var totalPrestiges: Int = 0
    var boostExpiry: Date?
    var frenzyExpiry: Date?
    var hasRemoveAds = false
    var hasPermanentDoubler = false
    var starterPackPurchased = false
    var hapticsEnabled = true
    var lastActive = Date()
    var firstLaunch = Date()
}

@MainActor
final class GameState: ObservableObject {
    @Published var data = SaveData()
    @Published var pendingOfflineEarnings: Double?

    private var loopTask: Task<Void, Never>?
    private var lastTick = Date()
    private var lastSave = Date()

    private static var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gemminer-save.json")
    }

    init() {
        load()
        Haptics.enabled = data.hapticsEnabled
        startLoop()
    }

    // MARK: - Derived values

    var boostActive: Bool { (data.boostExpiry ?? .distantPast) > Date() }
    var frenzyActive: Bool { (data.frenzyExpiry ?? .distantPast) > Date() }

    var globalMultiplier: Double {
        var m = 1.0 + Double(data.prestigeShards) * Balance.shardBonusPerShard
        if boostActive { m *= Balance.adBoostMultiplier }
        if data.hasPermanentDoubler { m *= 2 }
        return m
    }

    func level(of def: GeneratorDef) -> Int { data.generatorLevels[def.id] ?? 0 }

    func rate(of def: GeneratorDef) -> Double {
        let lvl = level(of: def)
        guard lvl > 0 else { return 0 }
        let milestones = pow(2.0, Double(lvl / Balance.milestoneEvery))
        return def.baseRate * Double(lvl) * milestones * globalMultiplier
    }

    var productionPerSecond: Double {
        GeneratorDef.all.reduce(0) { $0 + rate(of: $1) }
    }

    var tapValue: Double {
        Balance.tapBase * pow(Balance.tapGrowth, Double(data.tapLevel - 1))
            * globalMultiplier
            * (frenzyActive ? Balance.frenzyMultiplier : 1)
    }

    func cost(of def: GeneratorDef) -> Double {
        def.baseCost * pow(Balance.costGrowth, Double(level(of: def)))
    }

    var tapUpgradeCost: Double {
        Balance.tapCostBase * pow(Balance.tapCostGrowth, Double(data.tapLevel - 1))
    }

    // MARK: - Actions

    @discardableResult
    func mine() -> (amount: Double, isCrit: Bool) {
        let crit = Double.random(in: 0..<1) < Balance.critChance
        let amount = tapValue * (crit ? Balance.critMultiplier : 1)
        earn(amount)
        return (amount, crit)
    }

    func earn(_ amount: Double) {
        data.crystals += amount
        data.lifetimeCrystals += amount
        data.runCrystals += amount
    }

    func buyGenerator(_ def: GeneratorDef) {
        let c = cost(of: def)
        guard data.crystals >= c else { return }
        data.crystals -= c
        data.generatorLevels[def.id] = level(of: def) + 1
        Haptics.light()
    }

    func buyTapUpgrade() {
        let c = tapUpgradeCost
        guard data.crystals >= c else { return }
        data.crystals -= c
        data.tapLevel += 1
        Haptics.light()
    }

    @discardableResult
    func spendGems(_ amount: Int) -> Bool {
        guard data.gems >= amount else { return false }
        data.gems -= amount
        return true
    }

    func addGems(_ amount: Int) { data.gems += amount }

    func activateBoost(duration: TimeInterval = Balance.adBoostDuration) {
        let base = max(Date(), data.boostExpiry ?? Date())
        data.boostExpiry = base.addingTimeInterval(duration)
    }

    func activateFrenzy() {
        data.frenzyExpiry = Date().addingTimeInterval(Balance.frenzyDuration)
    }

    // MARK: - Prestige

    var shardsOnPrestige: Int {
        guard data.runCrystals >= Balance.prestigeUnlock else { return 0 }
        return Int(pow(data.runCrystals / Balance.prestigeUnlock, 0.5).rounded(.down))
    }

    func prestige() {
        let gained = shardsOnPrestige
        guard gained > 0 else { return }
        data.prestigeShards += gained
        data.totalPrestiges += 1
        data.crystals = 0
        data.runCrystals = 0
        data.generatorLevels = [:]
        data.tapLevel = 1
        data.boostExpiry = nil
        data.frenzyExpiry = nil
        save()
    }

    // MARK: - Offline earnings

    func computeOfflineEarnings() {
        let away = Date().timeIntervalSince(data.lastActive)
        guard away > 60 else { return }
        let capped = min(away, Balance.offlineCapHours * 3600)
        let earned = productionPerSecond * capped * Balance.offlineEfficiency
        data.lastActive = Date()
        if earned >= 1 { pendingOfflineEarnings = earned }
    }

    func claimOfflineEarnings(doubled: Bool) {
        guard let earned = pendingOfflineEarnings else { return }
        earn(earned * (doubled ? 2 : 1))
        pendingOfflineEarnings = nil
        save()
    }

    // MARK: - Loop & persistence

    private func startLoop() {
        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                self?.tick()
            }
        }
    }

    private func tick() {
        let now = Date()
        // Cap dt so a suspended app doesn't double-count time that the
        // offline-earnings path is responsible for.
        let dt = min(now.timeIntervalSince(lastTick), 2)
        lastTick = now
        if dt > 0 { earn(productionPerSecond * dt) }
        data.lastActive = now
        if now.timeIntervalSince(lastSave) > 30 { save() }
    }

    func save() {
        lastSave = Date()
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: Self.saveURL, options: .atomic)
        }
    }

    private func load() {
        guard let raw = try? Data(contentsOf: Self.saveURL),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: raw) else { return }
        data = decoded
    }

    func resetAll() {
        data = SaveData()
        pendingOfflineEarnings = nil
        save()
    }
}
