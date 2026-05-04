import AppKit
import Observation
import SpeechFlowConnectors
import SpeechFlowCore
import SpeechFlowDictation
import SpeechFlowInference
import SpeechFlowVault
import SwiftUI

@Observable @MainActor
public final class HarnessState {
    private let connectorDemo = StubCanvasConnector(emitsSamples: true)
    private let retrieval = RetrievalEngine()
    private let dictation = DictationOrchestrator()
    private let inference = NoOpInferenceBackend()

    public private(set) var vaultDirectory: URL?
    public private(set) var bootstrapMessage: String = "Initializing harness…"
    public private(set) var markdownNotes: Int = 0
    public private(set) var lastInferencePreview: String = ""
    public private(set) var connectorLog: String = "stub-canvas awaiting first sync."

    private var coordinator: VaultCoordinator?

    public init() {
        Task { await bootstrap() }
    }

    public func bootstrap() async {
        do {
            let root = try ApplicationPaths.defaultVaultDirectory()
            coordinator = try VaultCoordinator(root: root)
            vaultDirectory = root
            markdownNotes = try await coordinator?.markdownFileCount() ?? 0
            bootstrapMessage = "Vault staged at \(root.path)"
            connectorLog = "stub-canvas ready (sample emitters on)."
        } catch {
            coordinator = nil
            vaultDirectory = nil
            bootstrapMessage = "Vault bootstrap failed: \(error.localizedDescription)"
            connectorLog = "Resolve Application Support permission then relaunch."
        }
    }

    public func stubSync() async {
        guard let coordinator else {
            connectorLog = "Vault offline — bootstrap failed."
            return
        }

        connectorLog = "Pulling deterministic Canvas scaffold…"

        do {
            try await connectorDemo.authenticate(interactive: false)
            let delta = try await connectorDemo.sync(since: nil)
            try await coordinator.apply(events: delta)
            markdownNotes = try await coordinator.markdownFileCount()
            connectorLog = "Stub sync wrote \(delta.count) canonical LMS events • vault notes \(markdownNotes)."
        } catch {
            connectorLog = "Stub sync failure: \(error.localizedDescription)"
        }
    }

    public func scratchDictationPreview() async {
        guard let coordinator else {
            bootstrapMessage = "Cannot preview dictation bridge without a vault coordinator."
            return
        }

        do {
            let utterance = await dictation.provisionalTranscript()
            let bundle = try await retrieval.retrievalPacket(for: utterance, vault: coordinator)
            lastInferencePreview =
                try await inference.generate(prompt: bundle, options: GenerationOptions(maxTokens: 768))
            bootstrapMessage =
                "`Dictation façade + retrieval + InferenceBackend.generate` exercised with sample transcript."
        } catch {
            lastInferencePreview = "Preview aborted: \(error.localizedDescription)"
        }
    }

    public func revealVaultFolder() {
        guard let vaultDirectory else {
            NSSound.beep()
            return
        }
        NSWorkspace.shared.open(vaultDirectory)
    }
}
