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
| **Swift harness** | macOS/desktop app: connectors, vault, dictation insertion, interchangeable local inference, menu-bar / HUD UX | **`main`** (default): Swift Package + Xcode workspace as implementation lands |
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

The **Swift harness** is the system of record for everything except promotional content. Architectural layers (implement as modules when code exists):

1. **Connectors** — Pull from Canvas (REST + OAuth PKCE preferred) and pluggable scrapers/feeds for course pages. Output: **immutable sync events** with stable IDs.
2. **Harness core** — Map events → **vault mutations** (create/update notes, backlinks), maintain **sync cursors**, enforce rate limits and user-visible sync logs.
3. **Vault** — Files on disk (Markdown + front matter + wikilinks); optional SQLite/GRDB index for search and graph edges if pure-file parsing is too slow.
4. **Retrieval** — Given the active course or user selection, build a **small context bundle** (linked neighborhood + recent changes) for the model and UI.
5. **Dictation path** — Capture audio → local ASR (Speech framework and/or bundled model) → transcript → model-assisted formatting if enabled → **trusted insertion** into the focused app (Accessibility / event simulation strategy TBD per App Store and sandbox posture).
6. **Inference adapters** — Protocol-based backends (e.g. subprocess to `llama.cpp`, user-provided server, future Core ML). **No** hard dependency on a single vendor model in core types.

**Website** (on branch `website`): static or SSG (Astro, VitePress, or similar) for speed and cheap hosting; CI builds to GitHub Pages or Netlify; content mirrors high-level docs and release artifacts.

**Non-functional targets**: offline-first after setup; auditable sync history; clear separation of **secret storage** (Keychain) vs **note vault** (user-exportable).

For module boundaries, threat model for tokens, and phased delivery, see **`claude.md`**.

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

Planning / design phase — this repository defines **intent and architecture** until implementation lands.

Contribution areas we expect next: connector contracts, vault format spec, Swift module layout, dictation/injection prototype, local inference adapter interface.
