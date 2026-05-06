# SpeechFlow — handoff todos for downstream LLM

**Purpose.** This file is the actionable backlog distilled from root `README.md`, `CLAUDE.md` (workspace may show it as `claude.md` or `CLAUDE.md` depending on tooling), plus a quick repo audit. Execute tasks in dependency order unless parallelized explicitly.

**Environment.** macOS 14+ host; Swift **6.x** (README validates 6.1). Executable product name casing: `swift run SpeechFlow` only (capital `F`).

**Architecture invariant (both docs).** Whenever you change *overall* boundaries (major subsystem splits, website vs harness, security posture, branching), update **`README.md` and `CLAUDE.md` in the same change**; narrative vs checklist tone, but facts must match.

**Small-model constraint.** Every feature answers: (1) durable state in **vault**, (2) model sees **retrieved subset** not full history, (3) dictation **appends or merges** into targeted notes.

---

## 0. Baseline already implemented (verify before duplicating work)

| Area | Location / behavior |
|------|---------------------|
| SPM graph | `Package.swift` — targets `SpeechFlowCore`, `SpeechFlowVault`, `SpeechFlowConnectors`, `SpeechFlowInference`, `SpeechFlowDictation`, `SpeechFlowUI`, executable `SpeechFlow`. |
| Connector stub | `Sources/SpeechFlowConnectors/StubCanvasConnector.swift` — deterministic `[CanonicalEvent]`. |
| Vault single-writer | `Sources/SpeechFlowVault/VaultCoordinator.swift` — `apply(events:)` writes `assignments/`, `announcements/`, `files/` Markdown + YAML. |
| Retrieval (temporary) | `Sources/SpeechFlowVault/RetrievalEngine.swift` — **recent mtime** scan via `VaultCoordinator.loadRecentNoteBodies(limit:)`; **not** wikilink neighborhood expansion yet (README calls this TODO). |
| Inference stub | `Sources/SpeechFlowInference/NoOpInferenceBackend.swift` — echoes `RetrievalPacket` for UI wiring. |
| Dictation stub | `Sources/SpeechFlowDictation/DictationOrchestrator.swift` — fixed string transcript. |
| UI shell | `Sources/SpeechFlowUI/HarnessState.swift`, `SpeechFlowRootView.swift`; entry `Sources/SpeechFlow/`. |

**Gap vs `CLAUDE.md` P0 wording:** `Package.swift` has **no `testTarget`**. P0 promised “Retrieval / inference protocol smoke tests” — still missing as formal tests.

---

## 1. Testing & quality (unblocks safe refactors)

1. **Add SwiftPM test target(s)** in `Package.swift` (e.g. `SpeechFlowVaultTests`, `SpeechFlowCoreTests`) depending on what you test first.
2. **Golden / reducer tests:** Given fixture `[CanonicalEvent]` (use shapes from `Sources/SpeechFlowCore/CanonicalEvents.swift` + `StubCanvasConnector` / `ConnectorSamples` if present), assert deterministic Markdown output paths and key front-matter keys after `VaultCoordinator.apply`. Prefer file-based fixtures under `Tests/.../Fixtures/`.
3. **Retrieval smoke test:** Temp directory + `VaultCoordinator` + write a few notes with known mtimes; call `RetrievalEngine.retrievalPacket` and assert ordering/count caps respect `contextLimit`.
4. **Inference contract test:** `NoOpInferenceBackend.generate` returns non-empty string and includes utterance; `health` reports `.unavailable` as today.
5. **CI hook (optional but valuable):** GitHub Action `swift test` on `main` for macOS runner; document in a follow-up if not in scope.

**Acceptance:** `swift test` passes locally; no network in unit tests.

---

## 2. Phase P1 — Canvas connector (production path)

**Goal:** Real Canvas OAuth 2.0 **PKCE**, Keychain-only token storage, REST sync → `[CanonicalEvent]`, rate-limit aware.

1. **New type** in `SpeechFlowConnectors` (e.g. `CanvasConnector`) conforming to `LMSConnector` in `Sources/SpeechFlowCore/ConnectorProtocol.swift`.
2. **Authentication:** Implement `authenticate(interactive:)` — system browser or `ASWebAuthenticationSession`-style flow; store **refresh token** (and access token if used) via **Security framework / Keychain**; never log bearer tokens or full OAuth responses.
3. **Sync:** Implement `sync(since: SyncCursor?)` — map Canvas REST JSON to existing `CanonicalEvent` cases (`assignmentUpdated`, `announcementNew`, `fileMetadataNew`); preserve stable `source_id` namespace semantics from `CanonicalEvents.swift`.
4. **HTTP client behavior:** Inspect `X-Request-Rate-Limit` (and related Canvas headers); exponential backoff; surface **user-visible** “sync delayed” string via mechanism already used by `HarnessState.connectorLog` (extend as needed).
5. **Configuration:** Minimal UI or plist/UserDefaults **non-secret** config (Canvas base URL, client id — **not** secrets). Secrets only in Keychain.
6. **Wire UI:** Replace or complement “stub only” UX in `HarnessState` / `SpeechFlowRootView` / `SpeechFlowEntry` so user can choose stub vs Canvas and run sync.
7. **Tests:** Connector **contract tests** with recorded HTTP (URLProtocol stub or OHHTTPStubs-equivalent); **no live Canvas** in CI.

**Acceptance:** On a dev machine with valid Canvas OAuth app, sync produces Markdown in vault indistinguishable in *shape* from stub output; CI tests use fixtures only.

---

## 3. Vault index & retrieval (README “proper wikilink neighborhood” + `CLAUDE.md` SQLite plan)

**Goal:** Move from `mtime` glob to **indexed** notes for O(1) neighborhood expansion.

1. **Design:** Schema for `path`, `title`, `type`, `outgoing_links` (parse `[[...]]`), `modified_at`; choose **GRDB** or bare SQLite per team preference (`CLAUDE.md` suggests GRDB).
2. **Integration point:** Maintain index inside **`VaultCoordinator`** (single writer): update index on every `apply` / future dictation append; avoid second writer racing.
3. **Retrieval:** Extend `RetrievalEngine` API to accept optional “seed” note or utterance-derived entity; expand **graph neighborhood** (BFS/K-hop) capped by byte/token budget; fallback to recent notes when links missing.
4. **Conflict policy (later UI):** Document in code comments: LMS source of truth for **due dates**; user body last-writer — full UI banner can be follow-up.

**Acceptance:** Unit tests prove link parsing and neighborhood selection deterministic; performance acceptable on ~1k notes (smoke benchmark optional).

---

## 4. Phase P2 — Dictation & insertion MVP

**Goal:** Replace `DictationOrchestrator` provisional stub with **Speech framework** pipeline; define **Accessibility vs clipboard** insertion with **preview commit** when model rewrites (`CLAUDE.md`).

1. **Microphone entitlement / Info.plist:** Add required keys for distributed app (even dev); document entitlement set.
2. **ASR:** Wire `Speech` recognizer (or CoreAudio capture + future pluggable path); stream partial + final transcripts into `HarnessState`.
3. **Preview UI:** If `InferenceBackend` output differs from raw transcript beyond trivial whitespace, require explicit user confirm before **insertion** or vault append.
4. **Insertion strategy:** Prefer **Accessibility** to insert into focused element; document sandbox implications; clipboard + synthetic Cmd+V only behind **explicit consent** toggle.
5. **Tests:** Prefer abstractions injecting mock AX / pasteboard for unit tests where possible.

**Acceptance:** User can dictate, see transcript, optionally run inference, commit text into focused app **or** copy path; macOS permission prompts behave correctly.

---

## 5. Phase P3 — First real `InferenceBackend`

**Goal:** One **reference** backend (subprocess or bundled bridge — MLX / llama.cpp style) implementing `InferenceBackend` in `Sources/SpeechFlowCore/InferenceProtocol.swift`.

1. **Process model:** Spawn/manage child process or connect local socket; cancellation on app quit.
2. **Manifests:** Weight verification **UI + manifest** in Core (`CLAUDE.md`); backend does not embed trust policy.
3. **Health:** Implement `health` reflecting process reachability / GPU OOM strings user-actionable.
4. **Queue:** When offline/unhealthy, queue or fail softly — **never block main thread** (`HarnessState` async patterns).

**Acceptance:** User selects backend in UI; `generate` returns model text for sample `RetrievalPacket`; abusive prompt does not crash broker.

---

## 6. Phase P4 — Website, releases, distribution

**Repo contract:** Sources under `website/`; primary integration branch **`website`** per docs (marketing churn separate from `main`). If `website/` exists but incomplete, finish **Astro or VitePress** scaffold (**pick one**, align both docs if frozen choice changes).

### 6a. Website content (`CLAUDE.md` IA checklist)

For each deliver on `website` branch PR:

1. Hero + three pillars (**local**, **open**, **education harness**).
2. **Download:** Links to GitHub Releases + checksum how-to mirroring **`main`/CI artifacts**.
3. Architecture one-pager linking back to repo `README.md`.
4. Contributing + Code of Conduct pointer.
5. Privacy summary: local-first, **no telemetry by default** (adjust if product changes — then update both root docs).

### 6b. CI & hosting

1. Workflow: `npm ci && npm run build` (or pnpm equivalent) on `website` branch; deploy to **GitHub Pages** or Netlify using `GITHUB_TOKEN` only (no repo secrets for LMS).
2. Cross-link **pinned app semver** and installer checksums between site and Releases.

### 6c. macOS app distribution

1. **Notarization + Hardened Runtime** pipeline for releasable `.app`/installer.
2. Document **entitlements:** network client, microphone, accessibility (if used).
3. **Sandbox decision:** `CLAUDE.md` marks this explicit milestone — choose posture; update **both** `README.md` and `CLAUDE.md` when decided (conflicts with some injection strategies).

**Acceptance:** Static site builds in CI; release workflow produces signed/notarized artifact referenced from site.

---

## 7. Documentation hygiene (ongoing)

- When completing any **Phase P1–P4** milestone, update the **phased delivery table** in **both** `README.md` and `CLAUDE.md` if scope or ordering changed.
- When adding telemetry, cloud sync, or integrity features, reconcile with **“What not to ship in v0”** in `CLAUDE.md` and **Non-goals** in `README.md`.

---

## 8. Suggested execution order for a single agent

1. **§1 Testing** (enables safe changes).
2. **§3 Retrieval index** *or* **§2 Canvas** — choose based on product priority (course data vs smarter context). Engineering-wise, tests first, then either parallelize with two agents (connector vs index) or sequence: connector first if vault content must be real before link graph matters.
3. **§4 Dictation** (depends on preview/inference UX — can stub preview until §5).
4. **§5 Inference backend** (can overlap with §4 after protocol stable).
5. **§6 Website + release** on branch `website` and CI.

---

## 9. Files the next LLM should read first

| File | Why |
|------|-----|
| `CLAUDE.md` | Contracts, phases, security rules |
| `README.md` | User-facing status and module cheat sheet |
| `Package.swift` | Target graph |
| `Sources/SpeechFlowCore/ConnectorProtocol.swift` | `LMSConnector` |
| `Sources/SpeechFlowCore/CanonicalEvents.swift` | Event payloads |
| `Sources/SpeechFlowVault/VaultCoordinator.swift` | Single-writer vault |
| `Sources/SpeechFlowVault/RetrievalEngine.swift` | Current retrieval limitations |
| `Sources/SpeechFlowUI/HarnessState.swift` | UI ↔ domain wiring |

End of handoff list.
