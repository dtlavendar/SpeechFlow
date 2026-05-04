/// Pluggable local inference (`llama.cpp` bridge, MLX, user daemon, …).
public protocol InferenceBackend: Sendable {
    func generate(prompt: RetrievalPacket, options: GenerationOptions) async throws -> String
    var health: BackendHealth { get async }
}
