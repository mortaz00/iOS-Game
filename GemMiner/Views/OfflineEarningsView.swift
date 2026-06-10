import SwiftUI

/// Welcome-back sheet: the payoff of the appointment mechanic, and the
/// highest-converting rewarded-ad placement ("double it").
struct OfflineEarningsView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var ads: AdsManager

    var body: some View {
        VStack(spacing: 18) {
            Text("Welcome back! ⛏️")
                .font(.largeTitle.bold())
                .padding(.top, 32)

            Text("While you were away, your miners produced")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text((game.pendingOfflineEarnings ?? 0).compact)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple],
                                   startPoint: .top, endPoint: .bottom)
                )

            Button {
                ads.showRewarded {
                    game.claimOfflineEarnings(doubled: true)
                }
            } label: {
                Label("Claim ×2  (watch ad)", systemImage: "play.rectangle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [.orange, .pink],
                                                 startPoint: .leading, endPoint: .trailing))
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            Button("Claim") {
                game.claimOfflineEarnings(doubled: false)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(ads.simulatedAdVisible)
        .adOverlay(ads)
    }
}
