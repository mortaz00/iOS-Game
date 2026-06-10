import SwiftUI

struct PrestigeView: View {
    @EnvironmentObject var game: GameState
    @State private var confirming = false

    private var gain: Int { game.shardsOnPrestige }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .pink],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .padding(.top, 24)

                    Text("Trade your run for Prestige Shards.\nEach shard boosts ALL production by +\(Int(Balance.shardBonusPerShard * 100))% — forever.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    statsCard

                    if gain == 0 {
                        VStack(spacing: 8) {
                            ProgressView(value: min(game.data.runCrystals / Balance.prestigeUnlock, 1))
                                .tint(.purple)
                            Text("Earn \(Balance.prestigeUnlock.compact) crystals this run to unlock prestige (\(game.data.runCrystals.compact) so far)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        confirming = true
                    } label: {
                        Text(gain > 0 ? "Prestige for +\(gain) ✦" : "Locked")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(gain > 0
                                          ? AnyShapeStyle(LinearGradient(colors: [.purple, .pink],
                                                                         startPoint: .leading, endPoint: .trailing))
                                          : AnyShapeStyle(Color.gray.opacity(0.4)))
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(gain == 0)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Prestige")
            .confirmationDialog(
                "Reset this run for +\(gain) shards (+\(gain * Int(Balance.shardBonusPerShard * 100))% production, forever)?",
                isPresented: $confirming,
                titleVisibility: .visible
            ) {
                Button("Prestige ✦", role: .destructive) {
                    game.prestige()
                    Haptics.success()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var statsCard: some View {
        VStack(spacing: 10) {
            statRow("Current shards", "✦ \(game.data.prestigeShards)")
            statRow("Current bonus", "+\(Int(Double(game.data.prestigeShards) * Balance.shardBonusPerShard * 100))%")
            statRow("Crystals this run", game.data.runCrystals.compact)
            statRow("Shards on prestige", "✦ \(gain)")
            statRow("Total prestiges", "\(game.data.totalPrestiges)")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
    }
}
