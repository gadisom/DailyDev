import CoreGraphics

// 4pt grid spacing scale — all layout padding/gap values should pull from here.
public enum Spacing {
    public static let xxs: CGFloat  =  4
    public static let xs: CGFloat   =  8
    public static let sm: CGFloat   = 12
    public static let md: CGFloat   = 16
    public static let lg: CGFloat   = 20
    public static let xl: CGFloat   = 24
    public static let xxl: CGFloat  = 32
    public static let xxxl: CGFloat = 40
    public static let section: CGFloat = 48

    // Component-specific named values derived from the above
    public static let cardPadding: CGFloat   = md    // 16
    public static let cardPaddingLg: CGFloat = xl    // 24
    public static let screenEdge: CGFloat    = lg    // 20
    public static let tabBarHeight: CGFloat  = 68
    public static let tabBarBottom: CGFloat  = 18
    public static let statusBarHeight: CGFloat = 54
    public static let navBarHeight: CGFloat  = 64
}
