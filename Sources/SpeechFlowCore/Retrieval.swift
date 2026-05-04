import Foundation

/// Context bundle handed to interchangeable inference backends — keep small by design.
public struct RetrievalPacket: Sendable {
    public var userUtterance: String
    public var contextNotesMarkdown: [String]
    /// UI / policy label ("cornell_notes", "draft_email", …).
    public var mode: String

    public init(userUtterance: String, contextNotesMarkdown: [String] = [], mode: String = "default") {
        self.userUtterance = userUtterance
        self.contextNotesMarkdown = contextNotesMarkdown
        self.mode = mode
    }
}

public struct GenerationOptions: Sendable {
    public var maxTokens: Int

    public init(maxTokens: Int = 1024) {
        self.maxTokens = maxTokens
    }
}

public enum BackendHealth: Sendable, Equatable {
    case unknown
    case ready
    case unavailable(String)
}
