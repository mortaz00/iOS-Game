#if canImport(UIKit)
import UIKit

/// Tactile feedback on every reward — cheap "juice" that makes earning feel good.
enum Haptics {
    static var enabled = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
#else
enum Haptics {
    static var enabled = true
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func success() {}
}
#endif
