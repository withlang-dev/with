# D23 — Known-issue test disposition: expected-red is committed, loud, and bidirectional

**Date:** 2026-07-26
**Status:** Accepted — BDFL ruling.
**Deciders:** Eric (BDFL)

**Decision.** A test fixture documenting an open bug carries
`//! known-issue: #NNN <one-line why>` as its first directive. The runner
tolerates that fixture's red (printing `[known-issue #NNN] <file> red as
expected` while the underlying failure output stays visible) and FAILS the
fixture if it passes, so a fixed issue forces the directive's removal in the
same change. A red without the directive fails the lane as before. Test-green
therefore means "no unexplained red," not "no red."

**Context.** The reseed evidence gate (`:test-green` → `:update-seed`)
requires fresh lane-pass markers. After #714, the spec lane carried six reds
that Eric's own rulings keep red (4× #723 pre-existing spec debt, red on the
seed too; 2× ss14_11 held as #724 evidence), hard-blocking reseed while the
seed aged past 600 commits. Alternatives weighed: fixing all six first
(#724 needs its own design ruling; #723's four are separate root-cause
campaigns), silently bypassing the marker (forbidden — weakening the check),
runtime skips à la Go `T.Skip` (hides the red and carries no issue binding).
The adopted model is Rust compiletest's `known-bug: #NNNNN`
(`src/tools/compiletest/src/directives.rs`), which binds every tolerated red
to an issue and re-fails when the bug is fixed.

**Reopen if:** the directive count grows past a handful — expected-red is a
disposition for ruled, filed debt, not a parking lot; every entry must cite
an open issue that someone intends to close.