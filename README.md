# SpeechFlow — Education Harness (planned)

SpeechFlow aims to be an **open-source, education-centered alternative** to products like Wispr Flow: **desktop system-wide dictation** plus an **education harness** that connects what you say with what your courses publish.

---

## Documentation policy (architecture)

Whenever you make an **overall architectural change** to the project (splitting systems, layering, branching strategy, major component boundaries), **update `README.md` and `claude.md` together** in the **same logical change**. They are paired: README is human-facing narrative; `claude.md` is operational detail for contributors and tooling. Drift between them wastes review time.

---

## Two-part architecture

The product ships as **two cooperating pieces**:

| Deliverable | Role | Repo home |
|-------------|------|-----------|
| **Swift harness** | macOS/desktop app: connectors, vault, dictation insertion, interchangeable local inference, menu-bar / HUD UX | **`main`** (default): Swift Package (`Package.swift`) + optional Xcode wrapper |
| **Public website** | Open-source positioning: downloads, screenshots, ethos, contrib guide, roadmap, pointers to binaries and docs—not the runtime | Branch **`website`**: landing site sources under `website/` |

The website does **not** host model weights or LMS credentials; it is **marketing plus documentation**. The Swift app owns **privacy-sensitive** workflows.

Cross-links in releases: shipped app version ↔ site downloads page ↔ changelog in GitHub.

---

## Goals

| Idea | Detail |
|------|--------|
| **Where it runs** | **Desktop**, **system-wide** dictation — speak anywhere you can type, like a polished dictation layer. |
| **Who owns the intelligence** | **Local-first**: inference runs **on-device**. The user can **swap the underlying model/runtime** (e.g. GGUF bundles, compatible local servers). |
| **What it organizes** | The app is **not “one long chat.”** Small models lose global context quickly. The harness **writes small, durable notes** and **links them** so context is reconstructed from **structured memory**, not infinite context windows. |

---

## User-visible flow

1. **Sources** — The user connects **education surfaces they trust** (e.g. **Canvas**, a **course website**, other LMS/feeds where it is feasible and permitted). Credentials and fetch rules stay explicit and inspectable where possible.

2. **Ingest & digest** — A scheduled or on-demand pass pulls structured signals:

   - **Upcoming assignments** (due dates, rubrics snippets)
   - **Recent announcements / discussion posts**
   - **Newly uploaded readings or files** (titles, hashes, outlines when available — not replacing the LMS, mirroring pointers and summaries)

3. **Notebook layer (Obsidian-style)** — Instead of cramming everything into one prompt:

   - The harness (and/or the model under policy) emits **atomic notes**: one concept, one assignment, one reading, etc.
   - Notes **reference each other** (`[[Course]]`, assignment ↔ reading, prerequisite links) similar in spirit to **Obsidian**: graph over notes, backlinks, manageable chunk size.
   - **Dictation** can append or refine notes: “tie this rant to Assignment 3 and the Smith reading.”

4. **Model as agent** — The **same local model** participates in drafting, rewriting, Q&A — but **grounding** comes from retrieved notes + connectors, **not** from expecting the model to remember the whole semester in weights.

---

## Why the graph of small notes?

Small instruction-tuned models (e.g. compact open-weight stacks) excel at short tasks but **drop long-range coherence**. SpeechFlow treats that as a **design constraint**:

- Persist **explicit extractions** (assignments due, new PDF on week 7) into the note vault.
- Use **links and light structure** so any model pass only needs relevant **neighborhoods** (a few linked notes), not entire course history in one blob.

---

## Engineering design (summary)

The **Swift harness** is the system of record for everything except promotional content. Layers (implemented as SPM modules under `Sources/`):

1. **Connectors** — Target Canvas REST + OAuth PKCE with Keychain-held tokens. **Today**: `StubCanvasConnector` emits deterministic demo events shaped as `[CanonicalEvent]`.
2. **Harness reducer** — `VaultCoordinator` merges connector output plus future dictation append paths into Markdown atoms (single-writer discipline).
3. **Vault** — Markdown + YAML front matter + lightly linked bodies under `~/Library/Application Support/<bundle>/Vault/` (`assignments/`, `announcements/`, `files/` today). FTS / SQLite graph index is slated once pure-file traversal is insufficient.
4. **Retrieval** — `RetrievalEngine` gathers the freshest Markdown bodies + user transcript into `RetrievalPacket` (proper wikilink neighborhood expansion still TODO).
5. **Dictation** — Mic capture → `Speech` adapters → Accessibility / paste bridging with enforced preview (**today**: deterministic `DictationOrchestrator` stub).
6. **Inference** — `InferenceBackend.generate` abstracts local runtimes (**today**: `NoOpInferenceBackend` echoes packets for wiring tests).

**Website** (branch `website`, folder `website/`): static site / SSG for marketing docs + release links—not runtime state.

**Non-functional posture**: offline-friendly sync; audited connector logs surfacing backoff + errors; LMS secrets confined to Keychain (not Markdown).

For threat-model sketches, phased milestones, and contributor checklists see **`claude.md`**.

### Build & run (`main`)

- **Requires** macOS 14+ plus a Swift **6.x** toolchain (validated with Swift 6.1).

```bash
swift build           # emits .build/debug/SpeechFlow
swift run SpeechFlow  # launches the SwiftUI harness window
```

`swift run` produces an unsigned developer executable—not a notarized `.app` yet—so treat it as a harness for local QA.

#### Module cheat sheet

| Target | Highlights |
|--------|------------|
| `SpeechFlowCore` | `CanonicalEvent`, `SyncCursor`, `RetrievalPacket`, `LMSConnector`, `InferenceBackend` |
| `SpeechFlowVault` | `VaultCoordinator`, Application Support resolver, `RetrievalEngine` |
| `SpeechFlowConnectors` | `StubCanvasConnector`, `ConnectorSamples` |
| `SpeechFlowInference` | `NoOpInferenceBackend` |
| `SpeechFlowDictation` | `DictationOrchestrator` stub |
| `SpeechFlowUI` | `HarnessState` (`@Observable`) + `SpeechFlowRootView` |
| `SpeechFlow` (executable) | `@main` SwiftUI `App` |

---

## Open-source & trust stance

- **Open code** for the harness, connectors, and dictation UX so schools and contributors can audit behavior.
- **Interchangeable models**: document supported backends and how to verify weights (checksums, pinned revisions, reproducible manifests).
- **Connectors**: respect LMS terms of use; prefer official APIs where available.

---

## Non-goals (for early versions)

- Replacing Canvas or the LMS of record — this is an **ambient layer**, not grade submission.
- Storing copyrighted course materials blindly — prioritize **references**, **metadata**, and **user-generated** distillations consistent with license and institution policy.

---

## Status

Swift harness scaffolding now lives on `main`:

- SPM modules compile end-to-end; `swift run SpeechFlow` opens the UI shell.
- Canonical LMS ingestion path is runnable via **`StubCanvasConnector` → `[CanonicalEvent]` → `VaultCoordinator`** (writes Markdown stubs you can inspect in Finder).
- Dictation, Canvas OAuth, real inference backends, and signed app packaging remain **explicit next milestones**.

What we expect contributors to tackle soon: Speech / Accessibility MVP, SQLite-backed retrieval neighborhoods, Canvas token storage + sync scheduling, packaged reference `InferenceBackend`, release CI/notarization.
