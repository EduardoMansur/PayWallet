import SwiftUI

public struct DSTextField: View {
    private let title: String
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool

    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(DSTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(DSTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }
}

struct DSTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}
