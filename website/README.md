# SpeechFlow website

This directory holds the **marketing and documentation-facing site** for SpeechFlow.

- **Development branch**: `website` — open PRs and iterate here so Swift harness work on `main` stays focused.
- **Scope**: positioning, screenshots, downloads (links to GitHub Releases), contrib guide excerpts, changelog highlights. **No** LMS auth, vault, or inference — those live in the Swift app only.

Suggested stack when you bootstrap the project (see [`../claude.md`](../claude.md) § “Senior engineer design — website”): static site / SSG (e.g. Astro or VitePress) + CI deploy to GitHub Pages or Netlify.

Merge policy is up to the maintainers (`website` → `main` when you want a single-tree repo, or keep site-only merges separate).
