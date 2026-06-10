import SwiftUI

@main
struct GemMinerApp: App {
    @StateObject private var game = GameState()
    @StateObject private var ads = AdsManager()
    @StateObject private var store = StoreManager()
    @StateObject private var events = RandomEventManager()
    @StateObject private var daily = DailyRewardManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainGameView()
                .environmentObject(game)
                .environmentObject(ads)
                .environmentObject(store)
                .environmentObject(events)
                .environmentObject(daily)
                .onAppear {
                    store.start(game: game)
                    ads.start()
                    events.start()
                    game.computeOfflineEarnings()
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                game.computeOfflineEarnings()
            case .background, .inactive:
                game.save()
            @unknown default:
                break
            }
        }
    }
}
