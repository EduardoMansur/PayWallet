import SwiftUI

/// A reusable authentication header component displaying an icon, app name, and subtitle
public struct DSAuthHeader: View {
    enum Layout {
        static let vStackSpacing: CGFloat = 12
        static let subtitleOpacity = 0.9
        static let bottomPadding: CGFloat = 32
    }

    private let iconName: String
    private let title: String
    private let subtitle: String
    private let iconSize: CGFloat

    /// Creates an authentication header
    /// - Parameters:
    ///   - iconName: SF Symbol name for the icon
    ///   - title: Main title text (app name)
    ///   - subtitle: Subtitle text (tagline or description)
    ///   - iconSize: Size of the icon (default: 70)
    public init(
        iconName: String,
        title: String,
        subtitle: String,
        iconSize: CGFloat = 70
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: Layout.vStackSpacing) {
            Image(systemName: iconName)
                .font(.system(size: iconSize))
                .foregroundColor(DSColors.textOnGradient)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(DSColors.textOnGradient)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(DSColors.textOnGradient.opacity(Layout.subtitleOpacity))
        }
        .padding(.bottom, Layout.bottomPadding)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                DSColors.gradientBlue.opacity(0.6),
                DSColors.gradientPurple.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        DSAuthHeader(
            iconName: "wallet.pass.fill",
            title: "PayWallet",
            subtitle: "Secure Payment Solutions"
        )
    }
}
