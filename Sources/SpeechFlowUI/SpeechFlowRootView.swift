import AppKit
import SwiftUI

public struct SpeechFlowRootView: View {
    public let harness: HarnessState

    public init(controller: HarnessState) {
        harness = controller
    }

    public var body: some View {
        NavigationSplitView {
            List {
                Section("Education harness") {
                    Label("Markdown vault", systemImage: "archivebox.fill")
                        .help(harness.bootstrapMessage)

                    LabeledContent("Notes on disk") {
                        Text("\(harness.markdownNotes)")
                            .monospaced()
                    }

                    LabeledContent("Connector") {
                        Text("stub-canvas")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await harness.stubSync() }
                    } label: {
                        Label("Run stub LMS sync", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        Task { await harness.scratchDictationPreview() }
                    } label: {
                        Label("Preview dictation + inference", systemImage: "waveform.circle")
                    }

                    Button {
                        harness.revealVaultFolder()
                    } label: {
                        Label("Reveal vault in Finder", systemImage: "folder")
                    }
                }

                Section("Status") {
                    Text(harness.bootstrapMessage)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)

                    Text(harness.connectorLog)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Inference preview buffer") {
                    Text(harness.lastInferencePreview.isEmpty ? "Inference preview appears here." : harness.lastInferencePreview)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }

                Section("Vault path") {
                    Text(harness.vaultDirectory?.path(percentEncoded: false) ?? "(not initialized)")
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }

                Section("Next engineering drops") {
                    Text("Speech framework dictation, Accessibility insertion gates, Canvas OAuth PKCE + Keychain-backed tokens.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("SpeechFlow")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Education harness blueprint")
                        .font(.largeTitle.bold())

                    Text("""
SpeechFlow treats LMS ingestion as deterministic canonical events emitted by adapters. \
VaultCoordinator persists Markdown atoms (`assignments/`, `announcements/`, `files/`) linked by lightweight wikilink fragments so small-context local assistants only ever see capped neighborhoods emitted by RetrievalEngine stubs.
""")
                    .foregroundStyle(.secondary)

                    Divider()

                    groupedColumn(title: "System-wide dictation", icon: "mic.fill") {
                        Text("Speech / CoreAudio scaffolding ships next. Accessibility writers and paste bridging stay behind opaque preview confirmations.")
                    }

                    groupedColumn(title: "Interchangeable inference", icon: "cpu") {
                        Text("Wire `InferenceBackend` to MLX, llama.cpp, or user binaries without touching LMS vault codepaths.")
                    }

                    groupedColumn(title: "Connector discipline", icon: "link") {
                        Text("Prefer Canvas REST OAuth over scraping. Telemetry around rate-limit headers informs UI copy + offline queues.")
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Details")
        }
    }

    private func groupedColumn<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
            content()
        }
    }
}