import Foundation
import SwiftUI

@MainActor
protocol AdProvider: AnyObject {
    var isReady: Bool { get }
    func start()
    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void)
}

/// Fronts all rewarded-ad placements. Uses AdMob when the SDK is linked and an
/// ad is loaded; otherwise falls back to a simulated 3-second ad so the whole
/// game loop is testable in the simulator with no network or SDK.
@MainActor
final class AdsManager: ObservableObject {
    @Published var simulatedAdVisible = false
    @Published var simulatedSecondsLeft = 0

    /// Flip to true to always use the simulated ad (useful in development).
    var forceSimulated = false

    private var provider: AdProvider?

    init() {
        #if canImport(GoogleMobileAds)
        provider = AdMobProvider()
        #endif
    }

    func start() {
        provider?.start()
    }

    func showRewarded(onReward: @escaping () -> Void) {
        if !forceSimulated, let provider, provider.isReady {
            provider.showRewarded(onReward: onReward, onDismiss: {})
        } else {
            runSimulated(onReward)
        }
    }

    private func runSimulated(_ onReward: @escaping () -> Void) {
        guard !simulatedAdVisible else { return }
        simulatedSecondsLeft = 3
        withAnimation { simulatedAdVisible = true }
        Task { [weak self] in
            for second in stride(from: 3, through: 1, by: -1) {
                self?.simulatedSecondsLeft = second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard let self else { return }
            withAnimation { self.simulatedAdVisible = false }
            onReward()
            Haptics.success()
        }
    }
}

/// Overlay shown while a simulated ad "plays". Attach to any view that can
/// trigger a rewarded ad (sheets included, since they cover the root).
struct SimulatedAdOverlay: View {
    @EnvironmentObject var ads: AdsManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "play.tv.fill")
                    .font(.system(size: 56))
                Text("Simulated ad \u{2022} \(ads.simulatedSecondsLeft)s")
                    .font(.title3.bold())
                Text("Real builds play a rewarded video here (AdMob).")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .foregroundColor(.white)
        }
        .transition(.opacity)
    }
}

extension View {
    /// Hosts the simulated-ad overlay above this view.
    func adOverlay(_ ads: AdsManager) -> some View {
        ZStack {
            self
            if ads.simulatedAdVisible {
                SimulatedAdOverlay()
            }
        }
    }
}
