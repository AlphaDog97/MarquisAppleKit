import AppDesignTokens
import SwiftUI

private struct ActionPromptModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var prompt: ActionPromptState?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let prompt {
                    ActionPromptOverlay(prompt: prompt) {
                        dismiss()
                    }
                    .zIndex(10_000)
                }
            }
            .animation(
                reduceMotion
                    ? .easeInOut(duration: 0.15)
                    : .spring(response: 0.32, dampingFraction: 0.86),
                value: prompt?.id
            )
    }

    @MainActor
    private func dismiss() {
        prompt = nil
    }
}

public extension View {
    func actionPrompt(
        _ prompt: Binding<ActionPromptState?>
    ) -> some View {
        modifier(ActionPromptModifier(prompt: prompt))
    }
}
