import Foundation
import SpeechFlowCore

/// Placeholder LMS connector returning canned events until Canvas OAuth PKCE lands.
public struct StubCanvasConnector: LMSConnector {
    private let emitsSamples: Bool

    public init(emitsSamples: Bool = false) {
        self.emitsSamples = emitsSamples
    }

    public let id = "stub-canvas"

    public func authenticate(interactive _: Bool) async throws {}

    public func sync(since _: SyncCursor?) async throws -> [CanonicalEvent] {
        guard emitsSamples else { return [] }
        return ConnectorSamples.promoWeekDemo
    }
}

public enum ConnectorSamples {
    public static var promoWeekDemo: [CanonicalEvent] {
        let dueSoft = Calendar.current.date(byAdding: .day, value: 9, to: Date())
        return [
            .assignmentUpdated(
                AssignmentPayload(
                    sourceID: "canvas-assign-1001",
                    title: "Seminar reading reflection",
                    dueAt: dueSoft,
                    htmlURL: URL(string: "https://canvas.instructure.com/courses/demo/assignments/1001"),
                    courseName: "Seminar Methods"
                )
            ),
            .announcementNew(
                AnnouncementPayload(
                    sourceID: "canvas-announ-442",
                    title: "New slides uploaded for Week 4",
                    bodySnippet: "### Quick links\nSlides + optional reading appended to Modules.",
                    postedAt: Date(),
                    htmlURL: URL(string: "https://canvas.instructure.com/courses/demo/discussion_topics/442")
                )
            ),
            .fileMetadataNew(
                FileMetadataPayload(
                    sourceID: "canvas-file-9005",
                    displayName: "Week4_context.pdf",
                    byteSize: 1_831_929,
                    contentType: "application/pdf",
                    htmlURL: URL(string: "https://canvas.instructure.com/courses/demo/files/9005/download")
                )
            ),
        ]
    }
}
