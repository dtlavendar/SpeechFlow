# SpeechFlow — agent context / implementation plan

This file mirrors `README.md` for **AI assistants** and contributors: vision, boundaries, and how to extend the codebase without drifting scope.

---

## Documentation policy (must follow)

**Overall architectural changes** (new major subsystem, split between app vs site, security boundary moves, default branch/branching strategy) require **updating `README.md` and `claude.md` in the same change**. If you touch one, touch both. Keep tone different (README: narrative; this file: contracts and checklists) but **facts must match**.

---

## One-line pitch

Open-source **desktop system-wide dictation** + **education harness** that **ingests LMS/course signals** into an **Obsidian-like note graph**, with a **swap-in local model** handling short horizons only.

---

## Two-part system architecture

| Part | Responsibility | Canonical location |
|------|----------------|-------------------|
| **Swift harness** | Connectors, vault, retrieval, dictation, inference adapters — all privacy-sensitive runtime | Implemented on **`main`** (default trunk) |
| **Website** | Landing, docs excerpts, contrib onboarding, screenshots, GitHub Releases links — **no** LMS secrets | Sources under **`website/`**, integrated on **`website`** git branch |

**Why branch `website`**: keeps marketing site churn and asset pipelines out of Swift PRs until you choose to merge; release process can publish site independently of app patch releases.

Cross-reference in both places: pinned app semver, installer checksums Page (site) ↔ **releases** artifacts (built from `main`/CI).

---

## Core product decisions (frozen until explicitly revised)

| Decision | Choice |
|----------|--------|
| Client shape | **Desktop**, **system-wide** dictation (inject text into focused app). |
| Primary implementation | **Swift** (macOS first; future platforms only after native UX parity is decided). |
| Intelligence | **Local**, user-**interchangeable** inference via **adapter protocols**. |
| Course data | User-provided **connectors**: Canvas first-class via API; generic course URL second-tier. |
| Context strategy | **Vault + linked notes**, not mega-context reliance. |

Revise **both** markdown files together when changing any row above.

---

## Senior engineer design — Swift harness

### Architectural principles

1. **Event-sourced ingestion** — Connectors emit **canonical events** (`assignment_updated`, `announcement_new`, `file_metadata_new`). The harness reduces events to vault operations; connectors never write Markdown directly unless that is intentionally the adapter contract.
2. **Single writer for vault mutations** — One serial queue (`VaultCoordinator`) merges connector output, manual edits detection, and dictation append to avoid forked note state.
3. **Adapter boundaries** — `InferenceBackend`, `SpeechPipeline`, `LMSConnector` are protocols in a **core** module; concrete types live in feature modules to keep linking lean.
4. **Secrets hygiene** — OAuth tokens **Keychain-only**; no logging payloads that contain bearer tokens.

### Planned module map (Swift Package / Xcode targets)

```
SpeechFlowCore        — models, CanonicalEvent*, NoteDraft, RetrievalPacket
SpeechFlowVault       — file IO, indexing, graph helpers, migration
SpeechFlowConnectors  — Canvas, generic URL watcher (narrow scope)
SpeechFlowInference   — InferenceBackend implementations (process, FFI stub)
SpeechFlowDictation   — capture, ASR, insertion strategy façade
SpeechFlowApp         — SwiftUI shell, lifecycle, onboarding
```

Collapse or rename for v0 **only if** redundancy is proved; bias toward compilation isolation over “one mega target.”

### Data flow (authoritative)

```
Connectors → [CanonicalEvent] → VaultCoordinator → vault markdown + index
Focused app + user shortcut → DictationOrchestrator → transcript
RetrievalEngine → subgraph (wikilink neighborhood + FTS hits) → RetrievalPacket → InferenceBackend → user-reviewed text → paste + optional note append
```

### Canonical event sketch (evolve in code, not only prose)

- Stable `source_id` (LMS primary key + account id namespace)
- `occurred_at`, `ingested_at`
- `payload` per type (assignment: due, title, html_url; file: size, content-type, hash if local copy exists)

### Connector contract (protocol)

```swift
// Conceptual — exact names in repo when implemented
protocol LMSConnector {
    var id: String { get }
    func authenticate(interactive: Bool) async throws
    func sync(since: SyncCursor?) async throws -> [CanonicalEvent]
}
```

Canvas: **OAuth 2.0 PKCE**, least scopes; store refresh token in Keychain; respect `X-Request-Rate-Limit` headers with exponential backoff + user-visible “sync delayed.”

### Vault

- **v0**: Markdown + YAML front matter; wikilinks `[[Note]]`
- **Index**: add GRDB/SQLite when performance demands — store `path`, `title`, `type`, `outgoing_links`, `modified_at` for O(1) neighborhood expansion
- **Conflict**: LMS is source of truth for **due dates**; user body text merges via last-writer + optional “LMS changed” banner in UI

### Dictation & system-wide insertion

- **ASR**: start with `Speech` framework for iteration; optional pluggable local model path later
- **Insertion**: prefer **Accessibility API** to write into focused element when permitted; fall back to pasteboard + synthetic Cmd+V only with explicit user consent (security + sandbox implications)
- **Always** show a **preview commit** step before sending text to another app if model rewrote content

### Inference adapters

```swift
protocol InferenceBackend: Sendable {
    func generate(prompt: RetrievalPacket, options: GenerationOptions) async throws -> String
    var health: BackendHealth { get async }
}
```

Ship **one** reference backend (e.g. subprocess to an open binary the user installs) before chasing multiple. Weight verification is **UI + manifest** in Core, not inside the model binary.

### Concurrency & offline

- `actor` for `VaultCoordinator`; `async` connectors; **cancel** sync on sleep if appropriate
- Queue outbound model calls when backend offline; never block UI thread

### Testing strategy

- **Golden tests** for event → markdown reduction (fixtures from anonymized Canvas JSON)
- **Snapshot tests** for vault diff (small)
- **Contract tests** for connector HTTP with recorded responses (not live network in CI)

### macOS distribution

- Notarization + Hardened Runtime for distributed builds; document **entitlements** (network client, accessibility if used, microphone)
- Sandboxing: may conflict with some injection strategies — decision is **explicit milestone**; document chosen posture in both markdown files when decided

---

## Senior engineer design — website (branch `website`)

### Purpose

Trust and discovery: **what** SpeechFlow is, **how** to install, **how** to contribute, **where** releases live. No authenticated LMS flows.

### Suggested stack (pick one in first PR on branch)

- **Astro** or **VitePress** — static output, fast CI, simple MDX/MD content
- Host: **GitHub Pages** (simplest for OSS) or Netlify

### Content sections (IA)

- Hero + 3 pillars (local, open, education harness)
- Download (links to GitHub Releases + checksum instructions)
- Architecture one-pager (link back to this repo’s README)
- Contributing + code of conduct reference
- Privacy summary (local-first; no telemetry by default — adjust if product changes)

### CI (when added)

- `website` branch: `npm ci && npm run build` → deploy artifact
- No secrets in repo; use `GITHUB_TOKEN` for Pages

---

## Phased delivery (engineering)

| Phase | Outcome |
|-------|---------|
| **P0** | Swift app shell + Keychain + empty vault + manual note create |
| **P1** | Canvas connector read-only + event → notes for assignments/announcements |
| **P2** | Dictation loop + preview + paste path / accessibility writer (one strategy) |
| **P3** | First `InferenceBackend` + retrieval packet from linked notes |
| **P4** | Website live on branch `website` + release linkage |

Update this table in **both** docs when scope shifts.

---

## Small-model constraint (engineering implication)

Assume **rapid context loss**. Every feature proposal should answer:

1. Where does durable state live? (**Vault**, not RAM-only chat.)
2. What is shown to the model? (**Subset** of vault via links + retrieval, not whole history.)
3. How does dictation reconcile? (**Append or merge** into targeted notes.)

---

## What not to ship in v0

- Silent cloud ingestion of LMS content beyond user-configured sources.
- “Do my homework end-to-end” defaults without visible sourcing and educator controls (integrity is a future policy layer — design hooks, not loopholes).

---

## File map expectation (when code exists)

- `README.md` — public narrative, architecture summary, doc parity rule.
- `claude.md` — this operational plan for agents.
- `main` — Swift harness sources (`SpeechFlow*/`, `SpeechFlow.xcodeproj` or SPM at root).
- `website/` (on **`website`** branch) — landing site only.

---

## gstack

Use the `/browse` skill from gstack for all web browsing. **Never** use `mcp__claude-in-chrome__*` tools.

Available gstack skills: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/setup-gbrain`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`.
