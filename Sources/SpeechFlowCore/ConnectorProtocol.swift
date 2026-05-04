/// Integrations with LMS / course feeds. Implementations ship in `SpeechFlowConnectors`.
public protocol LMSConnector: Sendable {
    var id: String { get }

    func authenticate(interactive: Bool) async throws
    func sync(since: SyncCursor?) async throws -> [CanonicalEvent]
}
