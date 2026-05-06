import SwiftUI

public struct SpeechFlowRootView: View {
    public let harness: HarnessState

    public init(controller: HarnessState) {
        harness = controller
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
            .navigationTitle("SpeechFlow")
        } detail: {
            detail
            .navigationTitle("Details")
        }
    }

    private var sidebar: some View {
        List {
            Section("Harness") {
                Label("Local vault", systemImage: "archivebox.fill")
                    .help(harness.bootstrapMessage)

                LabeledContent("Notes") {
                    Text("\(harness.markdownNotes)")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                }

                LabeledContent("Connector") {
                    Text("stub-canvas")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Actions") {
                Button {
                    Task { await harness.stubSync() }
                } label: {
                    Label("Run LMS stub sync", systemImage: "arrow.triangle.2.circlepath")
                }

                Button {
                    Task { await harness.scratchDictationPreview() }
                } label: {
                    Label("Preview dictation flow", systemImage: "waveform.circle")
                }

                Button {
                    harness.revealVaultFolder()
                } label: {
                    Label("Reveal vault", systemImage: "folder")
                }
            }

            Section("Vault Path") {
                Text(harness.vaultDirectory?.path(percentEncoded: false) ?? "(not initialized)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .listStyle(.sidebar)
    }

    private var detail: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    HStack(alignment: .top, spacing: 16) {
                        MetricCard(
                            title: "Vault atoms",
                            value: "\(harness.markdownNotes)",
                            caption: "Markdown notes on disk",
                            systemImage: "square.stack.3d.up"
                        )

                        StatusCard(
                            title: "Connector",
                            message: harness.connectorLog,
                            systemImage: "link.badge.plus"
                        )

                        StatusCard(
                            title: "Bootstrap",
                            message: harness.bootstrapMessage,
                            systemImage: "checkmark.seal"
                        )
                    }

                    previewPanel

                    HStack(alignment: .top, spacing: 16) {
                        PillarCard(
                            title: "Dictate anywhere",
                            caption: "Speech and insertion stay behind a preview commit before text leaves SpeechFlow.",
                            systemImage: "mic.fill"
                        )

                        PillarCard(
                            title: "Ground locally",
                            caption: "The model sees a retrieved vault subset, never an unbounded semester transcript.",
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )

                        PillarCard(
                            title: "Swap the backend",
                            caption: "Inference remains a protocol so MLX, llama.cpp, or a user daemon can replace the stub.",
                            systemImage: "cpu"
                        )
                    }
                }
                .padding(32)
                .frame(maxWidth: 1120, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            StatusPill(text: "Local-first education harness")

            Text("Small notes. Clear context. No cloud memory trick.")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("""
SpeechFlow turns LMS events and future dictation into a durable Markdown vault. \
This skeleton keeps the privacy-sensitive runtime in Swift while the current demo path proves connector, vault, retrieval, and inference boundaries.
""")
            .font(.title3)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    Task { await harness.stubSync() }
                } label: {
                    Label("Hydrate sample vault", systemImage: "sparkle.magnifyingglass")
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button {
                    Task { await harness.scratchDictationPreview() }
                } label: {
                    Label("Exercise preview pipeline", systemImage: "waveform")
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(28)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(.tertiary)
                .padding(24)
        }
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Inference preview buffer", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Spacer()
                StatusPill(text: "No backend configured")
            }

            Text(harness.lastInferencePreview.isEmpty ? "Run the preview pipeline to see the dictation facade, recent vault notes, and no-op inference output." : harness.lastInferencePreview)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(harness.lastInferencePreview.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(22)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct CanvasBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.90, blue: 0.84),
                    Color(red: 0.80, green: 0.86, blue: 0.82),
                    Color(red: 0.60, green: 0.70, blue: 0.74),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.98, green: 0.75, blue: 0.48).opacity(0.35))
                .blur(radius: 56)
                .frame(width: 280, height: 280)
                .offset(x: 320, y: -180)

            Circle()
                .fill(Color(red: 0.18, green: 0.34, blue: 0.38).opacity(0.22))
                .blur(radius: 70)
                .frame(width: 360, height: 360)
                .offset(x: -360, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct StatusPill: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Color(red: 0.13, green: 0.24, blue: 0.25))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.54), in: Capsule())
    }
}

private struct MetricCard: View {
    var title: String
    var value: String
    var caption: String
    var systemImage: String

    var body: some View {
        DashboardCard {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))

            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusCard: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        DashboardCard {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .textSelection(.enabled)
        }
    }
}

private struct PillarCard: View {
    var title: String
    var caption: String
    var systemImage: String

    var body: some View {
        DashboardCard {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.13, green: 0.24, blue: 0.25))

            Text(title)
                .font(.title3.weight(.bold))

            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DashboardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .padding(20)
        .background(Color.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.48), lineWidth: 1)
        }
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.96, green: 0.94, blue: 0.87))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Color(red: 0.13, green: 0.24, blue: 0.25).opacity(configuration.isPressed ? 0.82 : 1),
                in: Capsule()
            )
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.13, green: 0.24, blue: 0.25))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color.white.opacity(configuration.isPressed ? 0.36 : 0.62), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
    }
}
