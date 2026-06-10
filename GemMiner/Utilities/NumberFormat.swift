import Foundation

extension Double {
    /// Idle-game style compact notation: 1.2K, 45.6M, 7.89B...
    var compact: String {
        let n = abs(self)
        let sign = self < 0 ? "-" : ""
        let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
        if n < 1000 {
            if n < 10, n != n.rounded() {
                return sign + String(format: "%.1f", n)
            }
            return sign + String(format: "%.0f", n)
        }
        var value = n
        var idx = 0
        while value >= 1000 && idx < suffixes.count - 1 {
            value /= 1000
            idx += 1
        }
        let digits = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
        return sign + String(format: "%.\(digits)f", value) + suffixes[idx]
    }
}

extension TimeInterval {
    /// "2h 13m", "4m 05s", "45s"
    var shortDuration: String {
        let s = max(Int(self), 0)
        if s >= 3600 { return "\(s / 3600)h \((s % 3600) / 60)m" }
        if s >= 60 { return String(format: "%dm %02ds", s / 60, s % 60) }
        return "\(s)s"
    }
}
