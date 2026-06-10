import Foundation
import SwiftUI

/// The "Lucky Comet": appears at unpredictable intervals and vanishes after a
/// few seconds if ignored. Variable-interval rewards plus a short decision
/// window — the strongest attention hook in the game, and the natural home
/// for a rewarded-ad offer.
@MainActor
final class RandomEventManager: ObservableObject {
    @Published var cometVisible = false
    @Published var offerPresented = false
    @Published var cometPosition = CGPoint(x: 0.5, y: 0.3) // unit coordinates

    private var task: Task<Void, Never>?
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        scheduleNext(initial: true)
    }

    private func scheduleNext(initial: Bool = false) {
        task?.cancel()
        let delay = Double.random(in: initial ? Balance.cometFirstDelay : Balance.cometDelay)
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.cometPosition = CGPoint(x: .random(in: 0.15...0.85),
                                         y: .random(in: 0.15...0.45))
            withAnimation { self.cometVisible = true }
            try? await Task.sleep(nanoseconds: UInt64(Balance.cometLifetime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if self.cometVisible {
                withAnimation { self.cometVisible = false }
                self.scheduleNext()
            }
        }
    }

    func cometTapped() {
        task?.cancel()
        task = nil
        cometVisible = false
        offerPresented = true
        Haptics.medium()
    }

    func offerResolved() {
        offerPresented = false
        scheduleNext()
    }
}
