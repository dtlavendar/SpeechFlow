import AppKit
import SpeechFlowUI
import SwiftUI

/// Ensures SPM / CLI launches foreground like a Dock app (`swift run` skips normal activation).
private final class SpeechFlowAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct SpeechFlowEntry: App {
    @NSApplicationDelegateAdaptor(SpeechFlowAppDelegate.self) private var appDelegate

    @State private var harness = HarnessState()

    var body: some Scene {
        WindowGroup("SpeechFlow") {
            SpeechFlowRootView(controller: harness)
                .frame(minWidth: 900, minHeight: 520)
        }
        .defaultSize(width: 960, height: 600)
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
