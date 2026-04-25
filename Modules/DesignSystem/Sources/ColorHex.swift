import SwiftUI

public extension Color {
    init(hexString value: String) {
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6, let rgb = UInt64(hex, radix: 16) else {
            self = .gray
            return
        }

        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
