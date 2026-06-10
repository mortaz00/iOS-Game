import SwiftUI

struct MainGameView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var ads: AdsManager
    @EnvironmentObject var events: RandomEventManager
    @EnvironmentObject var daily: DailyRewardManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView {
                    MineView()
                        .tabItem { Label("Mine", systemImage: "diamond.fill") }
                    UpgradesView()
                        .tabItem { Label("Upgrades", systemImage: "arrow.up.circle.fill") }
                    StoreView()
                        .tabItem { Label("Shop", systemImage: "bag.fill") }
                    PrestigeView()
                        .tabItem { Label("Prestige", systemImage: "sparkles") }
                }

                if events.cometVisible {
                    CometButton()
                        .position(x: geo.size.width * events.cometPosition.x,
                                  y: geo.size.height * events.cometPosition.y)
                        .transition(.scale.combined(with: .opacity))
                }

                if ads.simulatedAdVisible {
                    SimulatedAdOverlay()
                }
            }
        }
        .sheet(isPresented: $daily.presentSheet) {
            DailyRewardView()
        }
        .sheet(isPresented: offlineSheetBinding) {
            OfflineEarningsView()
        }
        .sheet(isPresented: $events.offerPresented, onDismiss: { events.offerResolved() }) {
            CometOfferView()
        }
        .onAppear { daily.checkOnAppear() }
    }

    /// Dismissing the sheet without choosing still claims the base amount,
    /// so swiping it away never silently destroys the player's earnings.
    private var offlineSheetBinding: Binding<Bool> {
        Binding(
            get: { game.pendingOfflineEarnings != nil },
            set: { shown in
                if !shown, game.pendingOfflineEarnings != nil {
                    game.claimOfflineEarnings(doubled: false)
                }
            }
        )
    }
}

struct CometButton: View {
    @EnvironmentObject var events: RandomEventManager
    @State private var pulsing = false

    var body: some View {
        Button(action: { events.cometTapped() }) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 72, height: 72)
                    .shadow(color: .yellow.opacity(0.8), radius: 18)
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(pulsing ? 1.15 : 0.92)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}
