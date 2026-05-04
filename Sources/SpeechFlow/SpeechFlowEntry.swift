import SpeechFlowUI
import SwiftUI

@main
struct SpeechFlowEntry: App {
    @State private var harness = HarnessState()

    var body: some Scene {
        WindowGroup("SpeechFlow") {
            SpeechFlowRootView(controller: harness)
                .frame(minWidth: 900, minHeight: 520)
        }
        .commands {
            CommandMenu("Harness") {
                Button("Hydrate LMS stub sync") {
                    Task { await harness.stubSync() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Preview dictation + inference") {
                    Task { await harness.scratchDictationPreview() }
                }

                Divider()

                Button("Reveal Markdown vault…") {
                    harness.revealVaultFolder()
                }
            }
        }
    }
}
