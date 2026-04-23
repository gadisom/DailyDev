import CoreGraphics

public enum Radius {
    public static let sm: CGFloat   =  8
    public static let md: CGFloat   = 12
    public static let lg: CGFloat   = 16
    public static let xl: CGFloat   = 20
    public static let xxl: CGFloat  = 22
    public static let pill: CGFloat = 999

    // Component-specific aliases
    public static let chip: CGFloat    = pill
    public static let card: CGFloat    = lg
    public static let cardLg: CGFloat  = xl
    public static let button: CGFloat  = md
    public static let iconBox: CGFloat = sm + 4  // 12 → 14
    public static let tabBar: CGFloat  = 34
}
