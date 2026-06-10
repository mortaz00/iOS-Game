import SwiftUI

struct MineView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var ads: AdsManager
    @EnvironmentObject var daily: DailyRewardManager

    @State private var gemScale: CGFloat = 1
    @State private var floaters: [Floater] = []
    @State private var showSettings = false
    @State private var now = Date()

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    struct Floater: Identifiable {
        let id = UUID()
        let text: String
        let crit: Bool
        let xOffset: CGFloat
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            statusChips
            Spacer()
            ZStack {
                gemButton
                ForEach(floaters) { FloatingTextView(floater: $0) }
            }
            Spacer()
            boostButton
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.16),
                                    Color(red: 0.12, green: 0.04, blue: 0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onReceive(clock) { now = $0 }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(game.data.crystals.compact)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("\(game.productionPerSecond.compact) / sec")
                    .font(.subheadline)
                    .foregroundColor(.cyan)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill").foregroundColor(.pink)
                    Text("\(game.data.gems)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                if daily.streak > 0 {
                    Text("🔥 \(daily.streak)-day streak")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var statusChips: some View {
        HStack(spacing: 8) {
            if game.frenzyActive, let expiry = game.data.frenzyExpiry {
                chip("⚡️ FRENZY ×\(Int(Balance.frenzyMultiplier)) \(expiry.timeIntervalSince(now).shortDuration)",
                     color: .yellow)
            }
            if game.boostActive, let expiry = game.data.boostExpiry {
                chip("🚀 ×2 \(expiry.timeIntervalSince(now).shortDuration)", color: .cyan)
            }
            if game.data.prestigeShards > 0 {
                chip("✦ +\(Int(Double(game.data.prestigeShards) * Balance.shardBonusPerShard * 100))%",
                     color: .purple)
            }
        }
        .frame(height: 28)
    }

    private func chip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.25)))
            .foregroundColor(color)
    }

    private var gemButton: some View {
        Button {
            let result = game.mine()
            result.isCrit ? Haptics.heavy() : Haptics.light()
            spawnFloater(result)
            gemScale = 0.86
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                gemScale = 1
            }
        } label: {
            Image(systemName: "diamond.fill")
                .font(.system(size: 160))
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .cyan.opacity(0.7), radius: game.frenzyActive ? 44 : 18)
                .scaleEffect(gemScale)
        }
        .buttonStyle(.plain)
    }

    private func spawnFloater(_ result: (amount: Double, isCrit: Bool)) {
        let floater = Floater(
            text: (result.isCrit ? "CRIT! +" : "+") + result.amount.compact,
            crit: result.isCrit,
            xOffset: .random(in: -70...70)
        )
        floaters.append(floater)
        Task {
            try? await Task.sleep(nanoseconds: 950_000_000)
            floaters.removeAll { $0.id == floater.id }
        }
    }

    @ViewBuilder
    private var boostButton: some View {
        if !game.boostActive {
            Button {
                ads.showRewarded {
                    game.activateBoost()
                }
            } label: {
                Label("Watch ad: ×2 everything for 4h", systemImage: "play.rectangle.fill")
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
        } else {
            Text("Boost active — keep mining! 🚀")
                .font(.subheadline)
                .foregroundColor(.cyan)
                .padding(.vertical, 12)
        }
    }
}

struct FloatingTextView: View {
    let floater: MineView.Floater
    @State private var risen = false

    var body: some View {
        Text(floater.text)
            .font(floater.crit ? .title.bold() : .headline.bold())
            .foregroundColor(floater.crit ? .yellow : .white)
            .shadow(radius: 3)
            .offset(x: floater.xOffset, y: risen ? -160 : -60)
            .opacity(risen ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { risen = true }
            }
            .allowsHitTesting(false)
    }
}
