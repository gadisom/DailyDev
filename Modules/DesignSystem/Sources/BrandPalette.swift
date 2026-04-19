import SwiftUI

public enum BrandPalette {
    public static let accent = Color(red: 0.13, green: 0.47, blue: 0.87)
    public static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
    public static let card = Color.white
    public static let textPrimary = Color(red: 0.10, green: 0.12, blue: 0.16)
    public static let textSecondary = Color(red: 0.38, green: 0.43, blue: 0.50)
}

public extension Font {
    static let dailyDevTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let dailyDevHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let dailyDevBody = Font.system(size: 16, weight: .regular, design: .default)
}
