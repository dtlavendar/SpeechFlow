# SpeechFlow — agent context / implementation plan

This file mirrors `README.md` for **AI assistants** and contributors: vision, boundaries, and how to extend the codebase without drifting scope.

---

## One-line pitch

Open-source **desktop system-wide dictation** + **education harness** that **ingests LMS/course signals** into an **Obsidian-like note graph**, with a **swap-in local model** handling short horizons only.

---

## Core product decisions (frozen for planning)

| Decision | Choice |
|----------|--------|
| Client shape | **Desktop**, **system-wide** dictation (inject text like a keyboard/dictation service). |
| Intelligence | **Local**, user-**interchangeable** model/runtime adapters. |
| Course data | User-provided **connectors**: Canvas first-class, generic **course site** crawler/API second. |
| Context strategy | Do **not** rely on raw context length. Use **small structured notes + links** (Obsidian paradigm: wikilinks, graph, backlinks). |

---

## Data flow (authoritative)

```
Connectors (Canvas / course URLs / …)
    → normalized events (assignment_due, post_new, asset_new, …)
    → harness writes/updates atomic notes in vault (+ optional FTS index)
Dictation pipeline
    → ASR/transcript chunks
    → model + RAG-ish retrieval from linked-note neighborhood OR explicit “scratch” note
    → user accepts → paste/system-wide insertion + vault update
```

- **Assignments / posts / uploads** surface as **note types** or **front-matter**, not freestyle prose only.
- Linking expresses **relations**: reading ↔ assignment ↔ week ↔ course.

---

## Model role vs harness role

- **Harness**: scheduling fetches, diffing LMS state, deterministic dedupe, vault I/O, link suggestions, injecting “retrieval packets” into the model call.
- **Model** (small, local): classification, extraction, rewriting, answering **when** retrieval context is capped to a handful of linked notes + user utterance.

If an assistant adds features, bias toward **moving state into notes** rather than lengthening prompts.

---

## Small-model constraint (engineering implication)

Assume **rapid context loss**. Every feature proposal should answer:

1. Where does durable state live? (**Vault**, not RAM-only chat.)
2. What is shown to the model? (**Subset** of vault via links + retrieval, not whole history.)
3. How does dictation reconcile? (**Append or merge** into targeted notes.)

---

## Connectors module (expected contract)

Define a minimal interface roughly:

- `list_sources()`, `authenticate()`, `sync_since(cursor) → events[]`
- Map provider payloads → **canonical event schema** (`Assignment`, `Announcement`, `FileRef`, …)
- Respect rate limits and ToS; prefer official APIs (**Canvas REST**).

Do not hardcode Gemini/Gemma naming in core logic — only in **runtime adapter docs** and manifests.

---

## Vault format (planned)

Align with interoperability:

- **Markdown** bodies + YAML frontmatter (machine tags: `type`, `due`, `source_uri`, `sha256`)
- **`[[wikilinks]]`** and/or explicit edge store if needed later for graph queries.

---

## What not to ship in v0

- Silent cloud ingestion of LMS content beyond user-configured sources.
- “Do my homework end-to-end” defaults without visible sourcing and educator controls (integrity is a future policy layer — design hooks, not loopholes).

---

## File map expectation (when code exists)

- `README.md` — public narrative and onboarding.
- `claude.md` — this operational plan for agents.
- Implementations split: connectors / vault / dictation shim / inference adapters — keep adapters behind interfaces.
