# D238 — Law 13: meaning belongs to the compiler; presentation belongs to the formatter (ruled)

**Laws:** 13 (`docs/mission.md`).

**Date:** 2026-11-26. **Status:** BDFL ruling (Eric, 2026-11-26: *"Add a law to mission.md... land law 13"*).

**Context.** Earlier drafts (`docs/proposals/with-fmt.md`) conflated layout and semantic rewrites in `with fmt`, and #2519's line-width discussion blurred whether line width was a language/compiler concern or strictly a formatter concern.

**Decision.** Added **Law 13** to `docs/mission.md`: meaning belongs to the compiler; presentation belongs to the formatter. The compiler judges only semantics (types, ownership, safety, execution) and never enforces taste or line width; `with fmt` owns style — configurable, idempotent, and strictly semantics-preserving. Also ruled #2519 under Law 13: `with fmt` defaults to 100 columns, configurable via `--max-width N` and `[fmt] max_width` in `with.toml` (CLI overrides `with.toml`), with symmetric single-expression body folding/unfolding.
