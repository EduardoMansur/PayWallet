import SwiftUI

public struct DSAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String

    public func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message)
            }
    }
}

public extension View {
    func dsAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(DSAlertModifier(isPresented: isPresented, title: title, message: message))
    }
}
