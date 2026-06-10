import SwiftUI

struct UpgradesView: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        NavigationView {
            List {
                Section("Tap Power") {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.title2)
                            .foregroundColor(.cyan)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tap Power  Lv \(game.data.tapLevel)")
                                .font(.headline)
                            Text("\(game.tapValue.compact) per tap")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        buyButton(cost: game.tapUpgradeCost) {
                            game.buyTapUpgrade()
                        }
                    }
                }

                Section("Miners") {
                    ForEach(GeneratorDef.all) { def in
                        generatorRow(def)
                    }
                }
            }
            .navigationTitle("Upgrades")
        }
        .navigationViewStyle(.stack)
    }

    private func generatorRow(_ def: GeneratorDef) -> some View {
        let level = game.level(of: def)
        let toMilestone = Balance.milestoneEvery - (level % Balance.milestoneEvery)
        return HStack {
            Image(systemName: def.icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(def.name)  Lv \(level)")
                    .font(.headline)
                if level > 0 {
                    Text("\(game.rate(of: def).compact)/sec • ×2 in \(toMilestone) levels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Produces \(def.baseRate.compact)/sec per level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            buyButton(cost: game.cost(of: def)) {
                game.buyGenerator(def)
            }
        }
    }

    private func buyButton(cost: Double, action: @escaping () -> Void) -> some View {
        let affordable = game.data.crystals >= cost
        return Button(action: action) {
            Text(cost.compact)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(affordable ? Color.green : Color.gray.opacity(0.4))
                )
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
    }
}
