import Foundation
import SpeechFlowCore

/// Mic capture → ASR pipeline façade. Ships as a deterministic stub until `Speech`/CoreAudio wiring ships.
public struct DictationOrchestrator: Sendable {
    public init() {}

    public func provisionalTranscript() async -> String {
        """
        Stub dictation façade — microphone capture + Speech framework adapters land next.
        Treat this transcript as deterministic sample text until devices access is granted.
        """
    }
}
