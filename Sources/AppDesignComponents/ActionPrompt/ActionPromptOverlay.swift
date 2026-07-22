import AppCore
import AppDesignTokens
import SwiftUI

struct ActionPromptOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @AccessibilityFocusState private var titleIsFocused: Bool

    let prompt: ActionPromptState
    let dismiss: @MainActor () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backdrop

                ActionPromptCard(
                    prompt: prompt,
                    maxHeight: cardMaxHeight(in: proxy),
                    titleIsFocused: $titleIsFocused,
                    dismiss: dismiss
                )
                .frame(maxWidth: 460)
                .padding(.horizontal, AppSpacing.medium)
                .padding(
                    .bottom,
                    max(proxy.safeAreaInsets.bottom, AppSpacing.medium)
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: cardAlignment
                )
                .transition(transition)
            }
            .ignoresSafeArea()
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            titleIsFocused = true
            feedbackForPresentation()
        }
    }

    private var backdrop: some View {
        Color.black
            .opacity(colorScheme == .dark ? 0.28 : 0.36)
            .contentShape(Rectangle())
            .onTapGesture {
                guard prompt.dismissOnBackdropTap else { return }
                dismiss()
            }
            .accessibilityHidden(true)
    }

    private func cardMaxHeight(in proxy: GeometryProxy) -> CGFloat {
        min(
            560,
            max(
                0,
                proxy.size.height
                    - proxy.safeAreaInsets.top
                    - proxy.safeAreaInsets.bottom
                    - AppSpacing.large * 2
            )
        )
    }

    private var cardAlignment: Alignment {
        #if os(macOS) || targetEnvironment(macCatalyst)
        .center
        #else
        .bottom
        #endif
    }

    private var transition: AnyTransition {
        reduceMotion
            ? .opacity
            : .move(edge: .bottom).combined(with: .opacity)
    }

    @MainActor
    private func feedbackForPresentation() {
        switch prompt.style {
        case .destructive, .warning:
            HapticFeedback.notification(.warning)
        case .completion:
            HapticFeedback.notification(.success)
        case .info, .replacement:
            HapticFeedback.selection()
        }
    }
}
