import Foundation

/// Opaque paging token per connector; serialized by the vault or app defaults.
public struct SyncCursor: Codable, Sendable, Equatable, Hashable {
    public var connectorID: String
    public var opaquePayload: String

    public init(connectorID: String, opaquePayload: String) {
        self.connectorID = connectorID
        self.opaquePayload = opaquePayload
    }
}

/// Intermediate shape before vault writes finalized Markdown.
public struct NoteDraft: Sendable, Equatable {
    public var relativePath: String
    public var title: String
    public var frontMatter: [String: String]
    public var bodyMarkdown: String

    public init(relativePath: String, title: String, frontMatter: [String: String], bodyMarkdown: String) {
        self.relativePath = relativePath
        self.title = title
        self.frontMatter = frontMatter
        self.bodyMarkdown = bodyMarkdown
    }
}
