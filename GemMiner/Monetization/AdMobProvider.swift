import Foundation

// AdMob adapter, compiled only when the GoogleMobileAds SwiftPM package is
// linked (project.yml adds it). Written against the v11 API; if you bump to
// v12+ the types lose their GAD prefix (GADRewardedAd -> RewardedAd, etc.).
//
// Uses Google's official TEST ad unit IDs — replace with your own units from
// the AdMob console before shipping, and replace GADApplicationIdentifier in
// project.yml with your real app ID.
#if canImport(GoogleMobileAds) && canImport(UIKit)
import GoogleMobileAds
import UIKit
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

@MainActor
final class AdMobProvider: NSObject, AdProvider, GADFullScreenContentDelegate {
    static let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313" // Google test ID

    private var rewarded: GADRewardedAd?
    private var onDismiss: (() -> Void)?

    var isReady: Bool { rewarded != nil }

    func start() {
        let begin = { @MainActor in
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            self.loadRewarded()
        }
        #if canImport(AppTrackingTransparency)
        // App Tracking Transparency consent must be requested before
        // personalized ads are served (App Store requirement).
        ATTrackingManager.requestTrackingAuthorization { _ in
            Task { @MainActor in begin() }
        }
        #else
        begin()
        #endif
    }

    private func loadRewarded() {
        GADRewardedAd.load(withAdUnitID: Self.rewardedUnitID,
                           request: GADRequest()) { [weak self] ad, _ in
            self?.rewarded = ad
            ad?.fullScreenContentDelegate = self
        }
    }

    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        guard let ad = rewarded, let root = Self.rootViewController() else {
            onDismiss()
            return
        }
        self.onDismiss = onDismiss
        rewarded = nil
        ad.present(fromRootViewController: root) {
            onReward()
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.onDismiss?()
            self.onDismiss = nil
            self.loadRewarded()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd,
                        didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.onDismiss?()
            self.onDismiss = nil
            self.loadRewarded()
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
#endif
