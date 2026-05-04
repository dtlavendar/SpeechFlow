import Foundation
import SpeechFlowCore

/// Single serialized writer for vault mutations (connector output, merges, dictation append).
public actor VaultCoordinator {
    public let root: URL

    public init(root: URL) throws {
        self.root = root
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    nonisolated private static func iso8601String(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
    /// Apply canonical LMS events deterministically → Markdown atoms + folders.
    public func apply(events: [CanonicalEvent]) throws {
        for event in events {
            switch event {
            case .assignmentUpdated(let payload):
                try writeAssignment(payload)
            case .announcementNew(let payload):
                try writeAnnouncement(payload)
            case .fileMetadataNew(let payload):
                try writeFileStub(payload)
            }
        }
    }

    /// List note bodies for lightweight retrieval bundles (SQLite/FTS replaces this later).
    public func loadRecentNoteBodies(limit: Int) throws -> [String] {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        else { return [] }

        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            guard url.pathExtension.lowercased() == "md" else { continue }
            urls.append(url)
        }

        urls.sort { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return da > db
        }

        return try urls.prefix(limit).map {
            try String(contentsOf: $0, encoding: .utf8)
        }
    }

    public func markdownFileCount() throws -> Int {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        else { return 0 }

        var count = 0
        while let url = enumerator.nextObject() as? URL {
            if url.pathExtension.lowercased() == "md" { count += 1 }
        }
        return count
    }

    private func writeAssignment(_ p: AssignmentPayload) throws {
        let slug = "\(sanitize(p.title))-\(sanitize(p.sourceID.prefix(48)))"
        let dir = root.appendingPathComponent("assignments", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(slug).md")
        let due = p.dueAt.map { Self.iso8601String(for: $0) } ?? ""
        let course = p.courseName ?? ""
        let link = p.htmlURL?.absoluteString ?? ""
        var fm: [String: String] = [
            "type": "assignment",
            "source_id": p.sourceID,
            "title": p.title,
            "due_at": due,
            "course": course,
        ]
        if !link.isEmpty { fm["lms_url"] = link }

        let wikilinkCourse = sanitizeWikilinkFragment(course.isEmpty ? "Course" : course)
        var bodyParts: [String] = [
            "# \(p.title)",
            "",
            "**Due:** \(due.isEmpty ? "TBD" : due)",
            "**Course:** \(course.isEmpty ? "—" : "[[\(wikilinkCourse)]]")",
            "",
        ]
        if !link.isEmpty { bodyParts.append("[Open in LMS](\(link))") }
        let body = bodyParts.joined(separator: "\n")

        try renderMarkdown(notePath: file, frontMatter: fm, body: body)
    }

    private func writeAnnouncement(_ p: AnnouncementPayload) throws {
        let slug = "announce-\(sanitize(p.sourceID))"
        let dir = root.appendingPathComponent("announcements", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(slug).md")
        let posted = p.postedAt.map { Self.iso8601String(for: $0) } ?? ""
        let link = p.htmlURL?.absoluteString ?? ""
        var fm: [String: String] = [
            "type": "announcement",
            "source_id": p.sourceID,
            "title": p.title,
            "posted_at": posted,
        ]
        if !link.isEmpty { fm["lms_url"] = link }

        var bodyParts = [
            "# \(p.title)",
            "",
            p.bodySnippet,
            "",
        ]
        if !link.isEmpty { bodyParts.append("[Open in LMS](\(link))") }
        let body = bodyParts.joined(separator: "\n")
        try renderMarkdown(notePath: file, frontMatter: fm, body: body)
    }

    private func writeFileStub(_ p: FileMetadataPayload) throws {
        let slug = "file-\(sanitize(p.sourceID))"
        let dir = root.appendingPathComponent("files", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(slug).md")

        let size = p.byteSize.map { "\($0) bytes" } ?? "unknown size"
        let ctype = p.contentType ?? "unknown type"
        let link = p.htmlURL?.absoluteString ?? ""

        var fm: [String: String] = [
            "type": "course_file",
            "source_id": p.sourceID,
            "display_name": p.displayName,
            "byte_size": p.byteSize.map(String.init) ?? "",
            "content_type": ctype,
        ]
        if !link.isEmpty { fm["lms_url"] = link }

        var lines = [
            "# \(p.displayName)",
            "",
            "- Kind: \(ctype)",
            "- Size: \(size)",
            "",
        ]
        if !link.isEmpty { lines.append("[Open / download](\(link))") }
        let body = lines.joined(separator: "\n")

        try renderMarkdown(notePath: file, frontMatter: fm, body: body)
    }

    private func renderMarkdown(notePath: URL, frontMatter: [String: String], body: String) throws {
        var yaml: [String] = ["---"]
        for key in frontMatter.keys.sorted() {
            let raw = frontMatter[key] ?? ""
            yaml.append(Self.yamlScalar(key: key, value: raw))
        }
        yaml.append("---")
        yaml.append("")
        yaml.append(contentsOf: body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))

        try yaml.joined(separator: "\n").write(to: notePath, atomically: true, encoding: .utf8)
    }

    private nonisolated static func yamlScalar(key: String, value: String) -> String {
        if value.isEmpty { return "\(key): \"\"" }
        let normalized = value.replacingOccurrences(of: "\n", with: " ")
        let mustQuote =
            normalized.contains(":") || normalized.contains("\"") || normalized.contains("#")
                || normalized.hasPrefix(" ") || normalized.contains("\t")
        if mustQuote {
            let escaped = normalized.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(
                of: "\"", with: "\\\""
            )
            return "\(key): \"\(escaped)\""
        }
        return "\(key): \(normalized)"
    }
}

private func sanitize(_ string: Substring) -> String {
    let bad = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
    return string
        .replacingOccurrences(of: "/", with: "-")
        .components(separatedBy: bad).filter { !$0.isEmpty }.joined(separator: "-")
        .lowercased()
}

private func sanitize(_ string: String) -> String {
    sanitize(string[...])
}

private func sanitizeWikilinkFragment(_ name: String) -> String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
}
