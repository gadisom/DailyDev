import SwiftUI

public enum DailyDevAnimation {
    // Durations (seconds)
    public static let fast:   Double = 0.15
    public static let normal: Double = 0.22
    public static let slow:   Double = 0.35

    // Spring presets
    public static let snappy  = Animation.spring(response: 0.30, dampingFraction: 0.75)
    public static let smooth  = Animation.spring(response: 0.45, dampingFraction: 0.80)
    public static let bouncy  = Animation.spring(response: 0.40, dampingFraction: 0.60)

    // Eased presets
    public static let easeOut = Animation.easeOut(duration: normal)
    public static let easeIn  = Animation.easeIn(duration: fast)

    // Tap feedback — scales a tapped element down slightly
    public static let tapScale: CGFloat = 0.97
}
