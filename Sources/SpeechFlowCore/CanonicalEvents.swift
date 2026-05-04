import Foundation

public enum CanonicalEvent: Sendable, Equatable {
    case assignmentUpdated(AssignmentPayload)
    case announcementNew(AnnouncementPayload)
    case fileMetadataNew(FileMetadataPayload)
}

public struct AssignmentPayload: Sendable, Equatable {
    public var sourceID: String
    public var title: String
    public var dueAt: Date?
    public var htmlURL: URL?
    public var courseName: String?

    public init(sourceID: String, title: String, dueAt: Date?, htmlURL: URL?, courseName: String?) {
        self.sourceID = sourceID
        self.title = title
        self.dueAt = dueAt
        self.htmlURL = htmlURL
        self.courseName = courseName
    }
}

public struct AnnouncementPayload: Sendable, Equatable {
    public var sourceID: String
    public var title: String
    public var bodySnippet: String
    public var postedAt: Date?
    public var htmlURL: URL?

    public init(sourceID: String, title: String, bodySnippet: String, postedAt: Date?, htmlURL: URL?) {
        self.sourceID = sourceID
        self.title = title
        self.bodySnippet = bodySnippet
        self.postedAt = postedAt
        self.htmlURL = htmlURL
    }
}

public struct FileMetadataPayload: Sendable, Equatable {
    public var sourceID: String
    public var displayName: String
    public var byteSize: Int64?
    public var contentType: String?
    public var htmlURL: URL?

    public init(sourceID: String, displayName: String, byteSize: Int64?, contentType: String?, htmlURL: URL?) {
        self.sourceID = sourceID
        self.displayName = displayName
        self.byteSize = byteSize
        self.contentType = contentType
        self.htmlURL = htmlURL
    }
}
