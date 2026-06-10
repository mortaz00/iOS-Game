import SwiftUI

/// Choice sheet after catching the Lucky Comet: a big ad-gated reward vs. a
/// small instant one. The contrast makes the ad option feel like a win.
struct CometOfferView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var ads: AdsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("✨ Lucky Comet! ✨")
                .font(.largeTitle.bold())
                .padding(.top, 32)

            Text("You caught it! Choose your reward:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                ads.showRewarded {
                    game.activateFrenzy()
                    game.addGems(Balance.cometGems)
                    dismiss()
                }
            } label: {
                VStack(spacing: 4) {
                    Label("MEGA REWARD  (watch ad)", systemImage: "play.rectangle.fill")
                        .font(.headline)
                    Text("⚡️ ×\(Int(Balance.frenzyMultiplier)) tap frenzy for \(Int(Balance.frenzyDuration))s  +  \(Balance.cometGems) gems")
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.yellow, .orange],
                                             startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.black)
            }
            .padding(.horizontal)

            Button {
                game.earn(game.productionPerSecond * 60)
                Haptics.medium()
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Text("Small reward")
                        .font(.headline)
                    Text("Instantly earn \((game.productionPerSecond * 60).compact) crystals")
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Spacer()
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(ads.simulatedAdVisible)
        .adOverlay(ads)
    }
}
