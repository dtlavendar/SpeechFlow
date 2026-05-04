import SpeechFlowCore

/// Lightweight neighborhood builder until SQLite/graph indexing lands.
public struct RetrievalEngine: Sendable {
    public init() {}

    public func retrievalPacket(for utterance: String, vault: VaultCoordinator, contextLimit: Int = 12) async throws
        -> RetrievalPacket {
        let notes = try await vault.loadRecentNoteBodies(limit: contextLimit)
        return RetrievalPacket(userUtterance: utterance, contextNotesMarkdown: notes, mode: "harness_demo")
    }
}
