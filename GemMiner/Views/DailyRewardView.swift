import SwiftUI

struct DailyRewardView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var daily: DailyRewardManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Reward")
                .font(.largeTitle.bold())
                .padding(.top, 28)

            if daily.streak > 0 {
                Text("🔥 \(daily.streak)-day streak")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                      spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    dayCell(index)
                }
            }
            .padding(.horizontal)

            Button {
                daily.claim(game: game)
                dismiss()
            } label: {
                Text(daily.claimedToday ? "Claimed — see you tomorrow!" : "Claim")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(daily.claimedToday
                                  ? AnyShapeStyle(Color.gray.opacity(0.4))
                                  : AnyShapeStyle(LinearGradient(colors: [.orange, .pink],
                                                                 startPoint: .leading,
                                                                 endPoint: .trailing)))
                    )
                    .foregroundColor(.white)
            }
            .disabled(daily.claimedToday)
            .padding(.horizontal)

            Text("Come back every day to keep your streak — miss a day and it resets!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .presentationDetents([.medium, .large])
    }

    private func dayCell(_ index: Int) -> some View {
        let reward = DailyRewardManager.table[index]
        let isToday = index == daily.todayIndex
        let isPast = index < daily.todayIndex
        return VStack(spacing: 4) {
            Text("Day \(reward.day)")
                .font(.caption2)
                .foregroundColor(.secondary)
            Image(systemName: isPast ? "checkmark.circle.fill" : "diamond.fill")
                .foregroundColor(isPast ? .green : .pink)
            Text("\(reward.gems)")
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color.orange.opacity(0.25) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}
