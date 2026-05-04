import SpeechFlowCore

public struct NoOpInferenceBackend: InferenceBackend {
    public init() {}

    public func generate(prompt: RetrievalPacket, options _: GenerationOptions) async throws -> String {
        var sections: [String] = []

        sections.append("## Harness preview — no inference binary configured.")
        sections.append(
            "> Transcript \(prompt.mode == "dictation_scratch" ? "from dictation façade" : "from harness"):")
        sections.append(prompt.userUtterance)

        if prompt.contextNotesMarkdown.isEmpty == false {
            sections.append("")
            sections.append("## Recent vault notes injected (\(prompt.contextNotesMarkdown.count))")
            sections.append(prompt.contextNotesMarkdown.joined(separator: "\n\n---\n\n"))
        }

        sections.append("")
        sections.append(
            "`InferenceBackend.generate` awaits a bundled bridge (Metal / llama.cpp / MLX…) or user-provided daemon."
        )

        return sections.joined(separator: "\n")
    }

    public var health: BackendHealth {
        get async { .unavailable("No local inference backend selected.") }
    }
}
