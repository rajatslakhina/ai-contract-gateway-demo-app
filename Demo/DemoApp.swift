import ContractGateway
import ContractGatewayUI
import SwiftUI

/// The fleet this app has shipped: one recorded request per App Store build that is
/// still in the field. The demo app owns this list for the same reason a real team
/// would: it is *your* release history, not the gateway's.
enum ShippedFleet {
    static let sonnet = "claude-sonnet-4-6"   // honours non-default sampling
    static let opus = "claude-opus-4-7"       // samples with defaults only

    static func doc(_ title: String) -> ContentBlock { .document(DocumentRef(id: title.lowercased(), title: title)) }

    static let fixtures: [Fixture] = [
        Fixture(name: "Receipt classifier, temperature 0.2",
                request: AppRequest(schema: .v1, build: 412, installationID: "ios-412-a", model: sonnet,
                                    messages: [Message(role: .user, content: [.text("Classify this receipt line: 'UBER *TRIP 23.10'")])],
                                    sampling: SamplingParameters(temperature: 0.2))),
        Fixture(name: "Smart reply on Opus 4.7, default temperature",
                request: AppRequest(schema: .v1, build: 431, installationID: "ios-431-a", model: opus,
                                    messages: [Message(role: .user, content: [.text("Suggest a short reply")])],
                                    sampling: SamplingParameters(temperature: 1.0))),
        Fixture(name: "Summary card echoed back in the assistant turn",
                request: AppRequest(schema: .v1, build: 455, installationID: "ios-455-a", model: sonnet,
                                    messages: [
                                        Message(role: .user, content: [.text("Summarise my trip notes")]),
                                        Message(role: .assistant, content: [.text("Here is your summary."), doc("Trip summary")]),
                                        Message(role: .user, content: [.text("Now make it a checklist")]),
                                    ])),
        Fixture(name: "Onboarding brief that opens with an assistant turn",
                request: AppRequest(schema: .v1, build: 470, installationID: "ios-470-a", model: sonnet,
                                    messages: [
                                        Message(role: .assistant, content: [.text("Welcome! Here is your plan."), doc("Starter plan")]),
                                        Message(role: .user, content: [.text("Adjust it for a beginner")]),
                                    ])),
        Fixture(name: "Cited refund policy quoted back by the user",
                request: AppRequest(schema: .v2, build: 488, installationID: "ios-488-a", model: sonnet,
                                    messages: [Message(role: .user, content: [
                                        .text("Your policy says refunds take 30 days. Is that right?",
                                              citations: [Citation(sourceTitle: "Refund policy", citedText: "within 30 days")]),
                                    ])])),
        Fixture(name: "Current build, clean request",
                request: AppRequest(schema: .v2, build: 502, installationID: "ios-502-a", model: opus,
                                    messages: [Message(role: .user, content: [.text("Draft a packing list")])])),
    ]

    /// Rewrites the team has reviewed and signed off for specific builds.
    /// Build 412's lost temperature is deliberately NOT signed off, so the CI gate
    /// shows exactly what a reviewer would be asked to decide.
    static let acknowledged: Set<Acknowledgement> = [
        Acknowledgement(build: 455, rule: .assistantDocumentRelocated),
        Acknowledgement(build: 488, rule: .userCitationsStripped),
    ]
}

@main
struct ContractGatewayDemoApp: App {
    var body: some Scene {
        WindowGroup {
            GatewayDashboardView(model: DashboardModel(fixtures: ShippedFleet.fixtures,
                                                       acknowledged: ShippedFleet.acknowledged,
                                                       catalog: .migrationGuideExamples))
        }
    }
}
