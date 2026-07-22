import SwiftUI
import Testing
@testable import AppDesignComponents

@Test("Coach mark flow preserves unique steps")
func coachMarkFlowConstruction() {
    let step = CoachMarkStep(
        id: "create",
        targetID: "home.create",
        title: "Create",
        message: "Start here"
    )
    let flow = CoachMarkFlow(id: "home.v1", steps: [step])

    #expect(flow.steps.count == 1)
    #expect(flow.steps[0].targetID.rawValue == "home.create")
    #expect(flow.steps[0].preferredPlacement == .automatic)
}

@Test("Action prompt preserves action roles")
func actionPromptConstruction() {
    let prompt = ActionPromptState(
        style: .destructive,
        title: "Delete item?",
        actions: [
            ActionPromptAction("Cancel", role: .cancel),
            ActionPromptAction("Delete", role: .destructive)
        ]
    )

    #expect(prompt.actions.count == 2)
    #expect(prompt.actions[0].role == .cancel)
    #expect(prompt.actions[1].role == .destructive)
    #expect(prompt.style.defaultIconSystemName == "exclamationmark.triangle.fill")
}
