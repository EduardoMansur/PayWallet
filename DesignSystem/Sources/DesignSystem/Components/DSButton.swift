import SwiftUI

public struct DSButton: View {
    private let title: String
    private let style: DSButtonStyle
    private let isLoading: Bool
    private let action: () -> Void

    public enum DSButtonStyle {
        case primary
        case secondary
        case destructive

        var backgroundColor: Color {
            switch self {
            case .primary:
                return DSColors.buttonPrimary
            case .secondary:
                return DSColors.buttonSecondary
            case .destructive:
                return DSColors.buttonDestructive
            }
        }

        var foregroundColor: Color {
            return .white
        }
    }

    public init(
        title: String,
        style: DSButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}
