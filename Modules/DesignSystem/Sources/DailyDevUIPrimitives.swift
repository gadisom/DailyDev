import SwiftUI

public struct DailyDevSectionTitle: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .tracking(1.3)
            .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))
    }
}

public struct DailyDevTagChip: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.94, green: 0.97, blue: 1.0))
            .clipShape(Capsule())
    }
}
