import Foundation
import SpeechFlowConnectors
import SpeechFlowCore
import SpeechFlowInference
import SpeechFlowVault
import XCTest

final class SpeechFlowHarnessTests: XCTestCase {
    func testVaultReducerWritesDeterministicMarkdownAtoms() async throws {
        let root = try makeTemporaryVault()
        let vault = try VaultCoordinator(root: root)
        let dueAt = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-05-04T19:00:00Z"))

        let events: [CanonicalEvent] = [
            .assignmentUpdated(
                AssignmentPayload(
                    sourceID: "canvas:assign/42",
                    title: "Unit Assignment",
                    dueAt: dueAt,
                    htmlURL: URL(string: "https://canvas.example.edu/assignments/42"),
                    courseName: "Foundations Seminar"
                )
            ),
            .announcementNew(
                AnnouncementPayload(
                    sourceID: "canvas-announcement-9",
                    title: "Reading window moved",
                    bodySnippet: "Finish the Week 4 packet before studio.",
                    postedAt: dueAt,
                    htmlURL: nil
                )
            ),
            .fileMetadataNew(
                FileMetadataPayload(
                    sourceID: "canvas-file-7",
                    displayName: "Week4_packet.pdf",
                    byteSize: 2048,
                    contentType: "application/pdf",
                    htmlURL: URL(string: "https://canvas.example.edu/files/7/download")
                )
            ),
        ]

        try await vault.apply(events: events)

        let fileCount = try await vault.markdownFileCount()
        XCTAssertEqual(fileCount, 3)

        let assignmentURL = root
            .appendingPathComponent("assignments", isDirectory: true)
            .appendingPathComponent("unit-assignment-canvas-assign-42.md")
        let assignment = try String(contentsOf: assignmentURL, encoding: .utf8)

        XCTAssertTrue(assignment.contains("type: assignment"))
        XCTAssertTrue(assignment.contains("source_id: \"canvas:assign/42\""))
        XCTAssertTrue(assignment.contains("due_at: \"2026-05-04T19:00:00Z\""))
        XCTAssertTrue(assignment.contains("**Course:** [[Foundations Seminar]]"))
    }

    func testRetrievalPacketUsesRecentNotesWithinLimit() async throws {
        let root = try makeTemporaryVault()
        let vault = try VaultCoordinator(root: root)

        try writeNote(named: "older.md", body: "# Older\n\nFirst note.", modifiedAt: Date(timeIntervalSince1970: 100), root: root)
        try writeNote(named: "newest.md", body: "# Newest\n\nSecond note.", modifiedAt: Date(timeIntervalSince1970: 300), root: root)
        try writeNote(named: "middle.md", body: "# Middle\n\nThird note.", modifiedAt: Date(timeIntervalSince1970: 200), root: root)

        let packet = try await RetrievalEngine().retrievalPacket(
            for: "summarize current work",
            vault: vault,
            contextLimit: 2
        )

        XCTAssertEqual(packet.userUtterance, "summarize current work")
        XCTAssertEqual(packet.mode, "harness_demo")
        XCTAssertEqual(packet.contextNotesMarkdown.count, 2)
        XCTAssertTrue(packet.contextNotesMarkdown[0].contains("# Newest"))
        XCTAssertTrue(packet.contextNotesMarkdown[1].contains("# Middle"))
    }

    func testNoOpInferenceBackendEchoesUtteranceAndReportsUnavailable() async throws {
        let backend = NoOpInferenceBackend()
        let packet = RetrievalPacket(
            userUtterance: "Draft a short note from this transcript.",
            contextNotesMarkdown: ["# Assignment\n\nDue tomorrow."],
            mode: "dictation_scratch"
        )

        let preview = try await backend.generate(prompt: packet, options: GenerationOptions(maxTokens: 128))

        XCTAssertTrue(preview.contains("Draft a short note from this transcript."))
        XCTAssertTrue(preview.contains("Recent vault notes injected (1)"))
        let health = await backend.health
        XCTAssertEqual(health, .unavailable("No local inference backend selected."))
    }

    private func makeTemporaryVault() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeechFlowTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeNote(named name: String, body: String, modifiedAt: Date, root: URL) throws {
        let url = root.appendingPathComponent(name)
        try body.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: modifiedAt], ofItemAtPath: url.path)
    }
}
