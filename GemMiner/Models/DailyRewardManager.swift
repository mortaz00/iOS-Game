import Foundation

struct DailyReward {
    let day: Int
    let gems: Int
    let productionMinutes: Double
}

/// Daily login rewards on a 7-day escalating cycle. Missing a day resets the
/// streak — the habit-forming loop (and its loss-aversion hook) of the game.
@MainActor
final class DailyRewardManager: ObservableObject {
    static let table: [DailyReward] = [
        .init(day: 1, gems: 5, productionMinutes: 10),
        .init(day: 2, gems: 10, productionMinutes: 15),
        .init(day: 3, gems: 15, productionMinutes: 20),
        .init(day: 4, gems: 20, productionMinutes: 30),
        .init(day: 5, gems: 30, productionMinutes: 45),
        .init(day: 6, gems: 40, productionMinutes: 60),
        .init(day: 7, gems: 80, productionMinutes: 120),
    ]

    @Published var presentSheet = false
    @Published private(set) var streak: Int
    @Published private(set) var claimedToday: Bool

    private let defaults = UserDefaults.standard
    private static let streakKey = "daily.streak"
    private static let lastClaimKey = "daily.lastClaim"

    init() {
        streak = defaults.integer(forKey: Self.streakKey)
        let last = defaults.object(forKey: Self.lastClaimKey) as? Date
        claimedToday = last.map { Calendar.current.isDateInToday($0) } ?? false
    }

    /// Index into `table` for the reward shown as "today".
    var todayIndex: Int {
        let cal = Calendar.current
        let last = defaults.object(forKey: Self.lastClaimKey) as? Date
        if let last, cal.isDateInToday(last) { return max(streak - 1, 0) % 7 }
        if let last, cal.isDateInYesterday(last) { return streak % 7 }
        return 0
    }

    /// True if skipping today would break an active streak.
    var streakAtRisk: Bool { !claimedToday && streak > 0 }

    func checkOnAppear() {
        if !claimedToday { presentSheet = true }
    }

    func claim(game: GameState) {
        guard !claimedToday else { return }
        let cal = Calendar.current
        let last = defaults.object(forKey: Self.lastClaimKey) as? Date
        if let last, cal.isDateInYesterday(last) {
            streak += 1
        } else {
            streak = 1
        }
        defaults.set(streak, forKey: Self.streakKey)
        defaults.set(Date(), forKey: Self.lastClaimKey)
        claimedToday = true

        let reward = Self.table[(streak - 1) % 7]
        game.addGems(reward.gems)
        // Scale the crystal reward with the player's economy so it always feels big.
        let crystals = max(game.productionPerSecond * reward.productionMinutes * 60,
                           Double(reward.day) * 50)
        game.earn(crystals)
        Haptics.success()
    }
}
