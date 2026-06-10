import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false

    var body: some View {
        NavigationView {
            List {
                Section("Feedback") {
                    Toggle("Haptics", isOn: $game.data.hapticsEnabled)
                        .onChange(of: game.data.hapticsEnabled) { value in
                            Haptics.enabled = value
                            game.save()
                        }
                }

                Section("Purchases") {
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                }

                Section("Stats") {
                    LabeledContent("Lifetime crystals", value: game.data.lifetimeCrystals.compact)
                    LabeledContent("Prestige shards", value: "✦ \(game.data.prestigeShards)")
                    LabeledContent("Total prestiges", value: "\(game.data.totalPrestiges)")
                }

                Section {
                    Button("Reset all progress", role: .destructive) {
                        confirmingReset = true
                    }
                } footer: {
                    Text("Gem Miner is designed to be fun in short sessions. Take breaks, and never spend more than you're comfortable with.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Erase ALL progress? This cannot be undone.",
                                isPresented: $confirmingReset,
                                titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    game.resetAll()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
